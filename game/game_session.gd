class_name GameSession
extends Node
## コンベアと箱を取りまとめ、供給、仕分け、出荷とゲーム進行を管理する。

signal shipped(points: int)
signal sorted(side: BoxSide)

enum State { READY, PLAYING, GAME_OVER }
enum BoxSide { LEFT, RIGHT }

@export var is_start_automatically: bool = true

@export var settings: DemoSettings = preload("res://game/demo_settings.tres")
@export var _main_conveyor: MainConveyor
@export var _shipping_conveyor: ShippingConveyor
@export var _character: SortingCharacter

@export var _box_view_prefab: PackedScene
@export var _left_box_spawn_marker: Marker2D
@export var _right_box_spawn_marker: Marker2D
@export var _left_box_ship_marker: Marker2D
@export var _right_box_ship_marker: Marker2D

var _left_box: BoxView
var _right_box: BoxView

var _left_box_state: BoxState
var _right_box_state: BoxState
var state: State = State.READY
var score: int = 0
var _fruit_flow: FruitFlow


## 接続されたコンポーネントを設定して開始待ちにする。
func _ready() -> void:
	_fruit_flow = FruitFlow.new(settings, _main_conveyor)
	_fruit_flow.supply_failed.connect(_end_game)
	_main_conveyor.configure(settings)
	_main_conveyor.reached_terminal.connect(_on_cargo_item_reached_terminal)
	if is_start_automatically:
		start_game()


## ゲームの時間を進める。[br]
## [param delta]: 前フレームからの経過秒数。
func _process(delta: float) -> void:
	advance(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	elif event.is_action_pressed("sort_left"):
		sort_cargo_item(GameSession.BoxSide.LEFT)
	elif event.is_action_pressed("sort_right"):
		sort_cargo_item(GameSession.BoxSide.RIGHT)
	elif event.is_action_pressed("ship_boxes"):
		ship()


## 全コンポーネント、供給時間とスコアを初期化して開始する。
func start_game() -> void:
	if state == State.PLAYING:
		return
	_main_conveyor.clear()
	_shipping_conveyor.clear()
	_clear_box(_left_box)
	_clear_box(_right_box)
	_character.set_fruit(null, settings.show_weights)
	_character.reset_pose()
	_create_boxes()
	score = 0
	_fruit_flow.start()
	state = State.PLAYING


## 各流れへ同じゲーム内経過時間を渡す。周期の蓄積は各担当に委ねる。[br]
## [param delta]: Engine.time_scaleが適用済みの前フレームからの経過秒数。
func advance(delta: float) -> void:
	if state != State.PLAYING or delta <= 0.0 or not is_finite(delta):
		return
	_fruit_flow.advance(delta)
	if state == State.PLAYING:
		_shipping_conveyor.advance(delta)


## 果実を供給する。容量超過または入口の詰まりでゲームを終了する。
func supply() -> void:
	_fruit_flow.supply()


## 供給失敗時に全ての流れを停止する。
func _end_game() -> void:
	state = State.GAME_OVER
	_fruit_flow.stop()
	_shipping_conveyor.stop()


## 到着した先頭果実を選択した箱へ渡す。処理できなければfalseを返す。[br]
## [param side]: 投入先の箱。
func sort_cargo_item(side: BoxSide) -> bool:
	if state != State.PLAYING:
		return false
	if side != BoxSide.LEFT and side != BoxSide.RIGHT:
		return false
	var cargo_item := _main_conveyor.take_ready_cargo_item()
	if cargo_item == null:
		return false
	var box_state := _left_box_state if side == BoxSide.LEFT else _right_box_state
	box_state.add(cargo_item)
	_character.set_fruit(null, settings.show_weights)
	_character.show_sort_pose(side == BoxSide.LEFT)
	sorted.emit(side)
	return true


## 到着した輸送物を手元へ表示し、コンベア上の二重表示を防ぐ。[br]
## [param cargo_item]: 終端に到着した輸送物。
func _on_cargo_item_reached_terminal(cargo_item: CargoItemData) -> void:
	_character.set_fruit(cargo_item, settings.show_weights)
	_main_conveyor.set_ready_fruit_visible(false)


## 左右の箱を同時出荷して合計得点を返す。両方空の場合は出荷しない。
func ship() -> int:
	if state != State.PLAYING or (_left_box_state.weight == 0 and _right_box_state.weight == 0):
		return 0
	var points := calculate(
			_left_box_state.weight,
			settings.target_weight,
	)
	points += calculate(
			_right_box_state.weight,
			settings.target_weight,
	)
	score += points
	shipped.emit(points)
	_left_box_state.ship()
	_right_box_state.ship()
	_shipping_conveyor.start_shipment([_left_box, _right_box], settings.flow_tick_interval)
	_create_boxes()
	return points


## 左右の投入先となる空箱を生成して状態と乗せ位置を接続する。
func _create_boxes() -> void:
	_left_box = _box_view_prefab.instantiate() as BoxView
	add_child(_left_box)
	_left_box.global_position = _left_box_spawn_marker.global_position
	_left_box_state = BoxState.new()
	_left_box.construct(_left_box_state, _left_box_ship_marker)

	_right_box = _box_view_prefab.instantiate() as BoxView
	add_child(_right_box)
	_right_box.global_position = _right_box_spawn_marker.global_position
	_right_box_state = BoxState.new()
	_right_box.construct(_right_box_state, _right_box_ship_marker)


## 再開始時に古い投入先の表示と状態接続を除去する。[br]
## [param box]: 前のゲームで使用した未出荷の箱。
func _clear_box(box: BoxView) -> void:
	if box == null:
		return
	box.unbind_state()
	box.get_parent().remove_child(box)
	box.queue_free()


## 一箱の得点を返す。空箱は0点、超過と不足は同じ差として評価する。[br]
## [param shipped_weight]: 箱の現在重量。[br]
## [param target_weight]: 目標重量。
func calculate(shipped_weight: int, target_weight: int) -> int:
	if shipped_weight == 0:
		return 0
	return maxi(0, 100 - absi(shipped_weight - target_weight) * 5)
