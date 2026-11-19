class_name GameSession
extends Node
## コンベアと箱を取りまとめ、供給、仕分け、出荷とゲーム進行を管理する。

signal shipped(points: int)
signal score_changed(total_score: int)
signal sorted(side: BoxSide)

## ステージの進行を停止し、結果を確定したときに一度だけ通知する。[br]
## [param result]: クリアまたはゲームオーバーの状態。[br]
## [param final_score]: 終了時の累計得点。[br]
## [param elapsed_seconds]: 開始から終了までのプレイ秒数。
signal game_finished(result: State, final_score: int, elapsed_seconds: float)

enum State { READY, PLAYING, GAME_OVER, CLEARED }
enum BoxSide { LEFT, RIGHT }

const ResultShutter := preload("res://prefabs/shutters/result_shutter.gd")

@export var is_start_automatically: bool = true

@export var settings: DemoSettings = preload("res://game/demo_settings.tres")
@export var _main_conveyor: MainConveyor
@export var _shipping_conveyor :ShippingConveyor
@export var _character: SortingCharacter
@export var _boxes_view_controller: BoxesViewController
@export var _left_weighing_scale: WeighingScale
@export var _right_weighing_scale: WeighingScale
@export var _total_score: TotalScore
@export var _cargo_item_counter: CargoItemCounter
@export var game_clear_shutter: ResultShutter
@export var game_over_shutter: ResultShutter

var _left_box_state: BoxState
var _right_box_state: BoxState
var state: State = State.READY
var score: int = 0
var elapsed_seconds: float = 0.0
var _generator: FruitGenerator
var _supply_elapsed: float = 0.0


## 接続されたコンポーネントを設定して開始待ちにする。
func _ready() -> void:
	_generator = FruitGenerator.new(settings)
	_main_conveyor.configure(settings)
	_main_conveyor.reached_terminal.connect(_on_cargo_item_reached_terminal)
	score_changed.connect(_total_score.set_score)
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


## 全コンポーネント、経過時間、供給時間とスコアを初期化して開始する。
func start_game() -> void:
	if state == State.PLAYING:
		return
	if not settings.is_valid():
		push_error("ゲーム設定が不正です。")
		return
	_main_conveyor.clear()
	_character.set_fruit(null, settings.show_weights)
	_character.reset_pose()
	_create_boxes()
	score = 0
	elapsed_seconds = 0.0
	_supply_elapsed = 0.0
	state = State.PLAYING
	_update_cargo_item_counter()
	score_changed.emit(score)


## 供給時刻ごとに搬送を進め、長いフレームでも生成位置を重ねない。[br]
## [param delta]: 前回の更新からの経過秒数。
func advance(delta: float) -> void:
	if state != State.PLAYING or delta <= 0.0 or not is_finite(delta):
		return
	while delta > 0.0 and state == State.PLAYING:
		var until_supply := maxf(0.0, settings.supply_interval - _supply_elapsed)
		var step := minf(delta, until_supply)
		_main_conveyor.advance(step)
		_shipping_conveyor.advance(step)
		elapsed_seconds += step
		_supply_elapsed += step
		delta -= step
		if _supply_elapsed >= settings.supply_interval:
			_supply_elapsed = 0.0
			supply()


## 果実を供給する。容量超過または入口の詰まりでゲームを終了する。
func supply() -> void:
	if state != State.PLAYING:
		return
	var cargo_item := _generator.generate()
	if cargo_item == null or not _main_conveyor.add_cargo_item(cargo_item):
		_finish_game(State.GAME_OVER)
		return
	_update_cargo_item_counter()


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
	_update_cargo_item_counter()
	sorted.emit(side)
	return true


## コンベアが保持している未処理の果実数と容量を表示に反映する。
func _update_cargo_item_counter() -> void:
	_cargo_item_counter.set_count(_main_conveyor.get_cargo_item_count(), _main_conveyor.capacity)


## 到着した輸送物を手元へ表示し、コンベア上の二重表示を防ぐ。[br]
## [param cargo_item]: 終端に到着した輸送物。
func _on_cargo_item_reached_terminal(cargo_item: CargoItemData) -> void:
	_character.set_fruit(cargo_item, settings.show_weights)
	_main_conveyor.set_ready_fruit_visible(false)


## 左右の箱を同時出荷して合計得点を返す。両方空の場合は出荷しない。
func ship() -> int:
	if state != State.PLAYING or (_left_box_state.current_weight == 0 and _right_box_state.current_weight == 0):
		return 0
	var left_points := ScoreCalculator.calculate(
			_left_box_state.current_weight,
			settings.target_weight,
	)
	var right_points := ScoreCalculator.calculate(
			_right_box_state.current_weight,
			settings.target_weight,
	)
	var bonus := ScoreCalculator.calculate_balance_bonus(
			left_points,
			right_points,
			_left_box_state.current_weight,
			_right_box_state.current_weight,
			settings.target_weight,
	)
	var points := left_points + right_points + bonus
	score += points
	shipped.emit(points)
	if _left_box_state.current_weight > 0:
		_boxes_view_controller.show_shipping_score(_left_box_state, left_points)
	_left_box_state.ship()
	if _right_box_state.current_weight > 0:
		_boxes_view_controller.show_shipping_score(_right_box_state, right_points)
	_right_box_state.ship()
	_create_boxes()
	if points > 0:
		score_changed.emit(score)
	if score >= settings.target_score:
		_finish_game(State.CLEARED)
	return points


## ゲームを停止して、確定した終了結果を通知する。[br]
## [param result]: クリアまたはゲームオーバーの状態。
func _finish_game(result: State) -> void:
	if state != State.PLAYING:
		return
	state = result
	game_finished.emit(state, score, elapsed_seconds)


## 左右の新しい箱の状態を生成し、表示の用意をControllerへ依頼する。
func _create_boxes() -> void:
	_left_box_state = BoxState.new(settings.target_weight)
	_right_box_state = BoxState.new(settings.target_weight)
	_boxes_view_controller.create_boxes(_left_box_state, _right_box_state)
	_left_weighing_scale.configure_observe_box(_left_box_state)
	_right_weighing_scale.configure_observe_box(_right_box_state)
