extends Node2D
## 入力、ゲーム本体、表示を接続するデモ画面。

const FRUIT_SCENE := preload("res://views/fruit_view.tscn")

@export var settings: DemoSettings = preload("res://game/demo_settings.tres")

var session: GameSession
var _fruit_views: Dictionary = {}
var _show_weights: bool

@onready var _fruit_layer: Node2D = $FruitLayer
@onready var _left_box: Node2D = $LeftBox
@onready var _right_box: Node2D = $RightBox
@onready var _score: Label = $UI/Score
@onready var _queue_count: Label = $UI/QueueCount
@onready var _target: Label = $UI/Target
@onready var _shipment: Label = $UI/Shipment
@onready var _overlay: ColorRect = $UI/Overlay
@onready var _title: Label = $UI/Overlay/Title
@onready var _summary: Label = $UI/Overlay/Summary
@onready var _start_button: Button = $UI/Overlay/Start
@onready var _debug_toggle: CheckButton = $UI/DebugToggle


## ゲームとUIを接続して開始待ち画面を表示する。
func _ready() -> void:
	session = GameSession.new(settings)
	_show_weights = settings.show_weights
	_debug_toggle.button_pressed = _show_weights
	_debug_toggle.toggled.connect(_on_debug_toggled)
	_start_button.pressed.connect(_on_start_pressed)
	session.changed.connect(_refresh)
	session.shipped.connect(_on_shipped)
	_refresh()


## 果実供給と見た目の移動を更新する。[br]
## [param delta]: 前フレームからの経過秒数。
func _process(delta: float) -> void:
	session.advance(delta)
	if session.state != GameSession.State.PLAYING:
		return
	var fruits := session.get_queue()
	var spacing := minf(45.0, 410.0 / maxf(1.0, settings.queue_capacity - 1))
	for index in fruits.size():
		var view: Node2D = _fruit_views[fruits[index]]
		var destination := Vector2(480 + index * spacing, 280)
		view.position = view.position.move_toward(destination, settings.conveyor_speed * delta)


## InputMapの操作をゲームへ渡す。[br]
## [param event]: キー入力などのイベント。
func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("start_game") and session.state != GameSession.State.PLAYING:
		_on_start_pressed()
	elif event.is_action_pressed("sort_left"):
		session.sort_fruit(GameSession.BoxSide.LEFT)
	elif event.is_action_pressed("sort_right"):
		session.sort_fruit(GameSession.BoxSide.RIGHT)
	elif event.is_action_pressed("ship_boxes"):
		session.ship()
	elif event.is_action_pressed("toggle_weights"):
		_debug_toggle.button_pressed = not _debug_toggle.button_pressed


## 新規プレイまたはリトライを開始する。
func _on_start_pressed() -> void:
	_shipment.text = "Ship both boxes with DOWN"
	_start_button.release_focus()
	session.start()


## デバッグ用重量表示を切り替える。[br]
## [param enabled]: 数値を表示するか。
func _on_debug_toggled(enabled: bool) -> void:
	_show_weights = enabled
	_refresh()


## 出荷した得点を通知する。[br]
## [param points]: 今回の出荷得点。
func _on_shipped(points: int) -> void:
	_shipment.text = "Shipment: +%d" % points


## ゲームの変更を各表示へ反映する。
func _refresh() -> void:
	var fruits := session.get_queue()
	for fruit in _fruit_views.keys():
		if not fruits.has(fruit):
			_fruit_views[fruit].queue_free()
			_fruit_views.erase(fruit)
	for fruit in fruits:
		if not _fruit_views.has(fruit):
			var view := FRUIT_SCENE.instantiate() as Node2D
			_fruit_layer.add_child(view)
			var spacing := minf(45.0, 410.0 / maxf(1.0, settings.queue_capacity - 1))
			var spawn_x := 940.0
			var index := fruits.find(fruit)
			if index > 0:
				var previous: Node2D = _fruit_views[fruits[index - 1]]
				spawn_x = maxf(spawn_x, previous.position.x + spacing)
			view.position = Vector2(spawn_x, 280)
			view.scale = Vector2.ONE * minf(1.0, spacing / 46.0)
			_fruit_views[fruit] = view
		_fruit_views[fruit].configure(fruit.weight, _show_weights)
	_score.text = "SCORE  %d" % session.score
	_queue_count.text = "QUEUE  %d / %d" % [fruits.size(), settings.queue_capacity]
	_queue_count.modulate = (
			Color("ffb09b") if fruits.size() == settings.queue_capacity else Color.WHITE
	)
	_target.text = "Current fruit: --"
	if not fruits.is_empty():
		_target.text = (
				"Current fruit: %d" % fruits[0].weight
				if _show_weights else "Current fruit: see circle"
		)
	_left_box.update_weight(session.left_box.weight, settings.target_weight)
	_right_box.update_weight(session.right_box.weight, settings.target_weight)
	_overlay.visible = session.state != GameSession.State.PLAYING
	if session.state == GameSession.State.READY:
		_title.text = "HYPEAR / SORTING DEMO"
		_summary.text = (
				"LEFT / RIGHT: sort fruit\nDOWN: ship both boxes\n"
				+ "Aim for %d in each box.\nOverflow ends the game." % settings.target_weight
		)
		_start_button.text = "START (Enter / Space)"
	elif session.state == GameSession.State.GAME_OVER:
		_title.text = "GAME OVER"
		_summary.text = "Queue overflow!\nFinal score: %d" % session.score
		_start_button.text = "RETRY (Enter / Space)"
