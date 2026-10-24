extends Node2D
## 入力、進行管理とHUDを接続するゲーム画面。

var _show_weights: bool

@onready var session: GameSession = $GameSession
@onready var _player: SortingCharacter = $Player
@onready var _conveyor: Conveyor = $Conveyor
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
	_show_weights = session.settings.show_weights
	_debug_toggle.button_pressed = _show_weights
	_debug_toggle.toggled.connect(_on_debug_toggled)
	_start_button.pressed.connect(_on_start_pressed)
	session.changed.connect(_refresh)
	session.shipped.connect(_on_shipped)
	session.fruit_sorted.connect(_on_fruit_sorted)
	_refresh()


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
	_conveyor.set_show_weights(enabled)
	_refresh()


## 出荷した得点を通知する。[br]
## [param points]: 今回の出荷得点。
func _on_shipped(points: int) -> void:
	_shipment.text = "Shipment: +%d" % points


## 成功した投入の方向をキャラクター表示へ渡す。[br]
## [param side]: 投入先の箱。
func _on_fruit_sorted(side: GameSession.BoxSide) -> void:
	_player.show_sort_pose(side == GameSession.BoxSide.LEFT)


## ゲームの変更を各表示へ反映する。
func _refresh() -> void:
	var fruits := _conveyor.get_queue()
	var settings := session.settings
	_score.text = "SCORE  %d" % session.score
	_queue_count.text = "QUEUE  %d / %d" % [fruits.size(), settings.queue_capacity]
	_queue_count.modulate = (
			Color("ffb09b") if fruits.size() == settings.queue_capacity else Color.WHITE
	)
	_target.text = "Current fruit: --"
	var ready_fruit := _conveyor.peek_ready_fruit()
	_player.set_fruit(ready_fruit, _show_weights)
	_conveyor.set_ready_fruit_visible(false)
	if session.state != GameSession.State.PLAYING:
		_player.reset_pose()
	if ready_fruit != null:
		_target.text = (
				"Current fruit: %d" % ready_fruit.weight
				if _show_weights else "Current fruit: ready"
		)
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
		_summary.text = "Conveyor full or entrance blocked!\nFinal score: %d" % session.score
		_start_button.text = "RETRY (Enter / Space)"
