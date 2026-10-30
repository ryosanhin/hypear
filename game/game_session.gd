class_name GameSession
extends Node
## コンベアと箱を取りまとめ、供給、仕分け、出荷とゲーム進行を管理する。

signal changed
signal shipped(points: int)
signal fruit_sorted(side: BoxSide)

enum State { READY, PLAYING, GAME_OVER }
enum BoxSide { LEFT, RIGHT }

@export var settings: DemoSettings = preload("res://game/demo_settings.tres")
@export var _main_conveyor: MainConveyor
@export var _shipping_conveyor :ShippingConveyor

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
var _generator: FruitGenerator
var _supply_elapsed: float = 0.0


## 接続されたコンポーネントを設定して開始待ちにする。
func _ready() -> void:
	assert(settings.is_valid(), "デモ設定が不正です")
	assert(_main_conveyor != null and _left_box != null and _right_box != null, "コンポーネントが未設定です")
	_generator = FruitGenerator.new(settings)
	_main_conveyor.configure(settings)

	_create_boxes()


## ゲームの時間を進める。[br]
## [param delta]: 前フレームからの経過秒数。
func _process(delta: float) -> void:
	advance(delta)


## 全コンポーネント、供給時間とスコアを初期化して開始する。
func start() -> void:
	if state == State.PLAYING:
		return
	_main_conveyor.clear()
	_create_boxes()
	score = 0
	_supply_elapsed = 0.0
	state = State.PLAYING
	changed.emit()


## 供給時刻ごとに搬送を進め、長いフレームでも生成位置を重ねない。[br]
## [param delta]: 前回の更新からの経過秒数。
func advance(delta: float) -> void:
	if state != State.PLAYING or delta <= 0.0 or not is_finite(delta):
		return
	while delta > 0.0 and state == State.PLAYING:
		var until_supply := maxf(0.0, settings.supply_interval - _supply_elapsed)
		var step := minf(delta, until_supply)
		_main_conveyor.advance(step)
		_supply_elapsed += step
		delta -= step
		if _supply_elapsed >= settings.supply_interval:
			_supply_elapsed = 0.0
			supply()
	changed.emit()


## 果実を供給する。容量超過または入口の詰まりでゲームを終了する。
func supply() -> void:
	if state != State.PLAYING:
		return
	if not _main_conveyor.add_fruit(_generator.generate()):
		state = State.GAME_OVER
	changed.emit()


## 到着した先頭果実を選択した箱へ渡す。処理できなければfalseを返す。[br]
## [param side]: 投入先の箱。
func sort_fruit(side: BoxSide) -> bool:
	if state != State.PLAYING:
		return false
	if side != BoxSide.LEFT and side != BoxSide.RIGHT:
		return false
	var fruit := _main_conveyor.take_ready_fruit()
	if fruit == null:
		return false
	var box_state := _left_box_state if side == BoxSide.LEFT else _right_box_state
	box_state.add(fruit)
	fruit_sorted.emit(side)
	changed.emit()
	return true


## 左右の箱を同時出荷して合計得点を返す。両方空の場合は出荷しない。
func ship() -> int:
	if state != State.PLAYING or (_left_box_state.weight == 0 and _right_box_state.weight == 0):
		return 0
	var points := ScoreCalculator.calculate(
			_left_box_state.weight,
			settings.target_weight,
	)
	points += ScoreCalculator.calculate(
			_right_box_state.weight,
			settings.target_weight,
	)
	score += points
	shipped.emit(points)
	_create_boxes()
	changed.emit()
	return points


func _create_boxes() -> void:
	_left_box = _box_view_prefab.instantiate() as BoxView
	_left_box.global_position = _left_box_spawn_marker.global_position
	_left_box_state = BoxState.new()
	_left_box.construct(_left_box_state, _left_box_ship_marker)
	_left_box.reached_ship_entry_position.connect(_shipping_conveyor.accept_box)

	_right_box = _box_view_prefab.instantiate() as BoxView
	_right_box.global_position = _right_box_spawn_marker.global_position
	_right_box_state = BoxState.new()
	_right_box.construct(_right_box_state, _right_box_ship_marker)
	_right_box.reached_ship_entry_position.connect(_shipping_conveyor.accept_box)
