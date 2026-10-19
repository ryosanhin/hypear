class_name GameSession
extends Node
## コンベアと箱を取りまとめ、供給、仕分け、出荷とゲーム進行を管理する。

signal changed
signal shipped(points: int)

enum State { READY, PLAYING, GAME_OVER }
enum BoxSide { LEFT, RIGHT }

@export var settings: DemoSettings = preload("res://game/demo_settings.tres")
@export var conveyor: Conveyor
@export var left_box: FruitBox
@export var right_box: FruitBox

var state: State = State.READY
var score: int = 0
var _generator: FruitGenerator
var _supply_elapsed: float = 0.0


## 接続されたコンポーネントを設定して開始待ちにする。
func _ready() -> void:
	assert(settings.is_valid(), "デモ設定が不正です")
	assert(conveyor != null and left_box != null and right_box != null, "コンポーネントが未設定です")
	_generator = FruitGenerator.new(settings)
	conveyor.configure(settings)
	left_box.configure(settings.target_weight)
	right_box.configure(settings.target_weight)


## ゲームの時間を進める。[br]
## [param delta]: 前フレームからの経過秒数。
func _process(delta: float) -> void:
	advance(delta)


## 全コンポーネント、供給時間とスコアを初期化して開始する。
func start() -> void:
	if state == State.PLAYING:
		return
	conveyor.clear()
	left_box.clear()
	right_box.clear()
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
		conveyor.advance(step)
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
	if not conveyor.add_fruit(_generator.generate()):
		state = State.GAME_OVER
	changed.emit()


## 到着した先頭果実を選択した箱へ渡す。処理できなければfalseを返す。[br]
## [param side]: 投入先の箱。
func sort_fruit(side: BoxSide) -> bool:
	if state != State.PLAYING:
		return false
	if side != BoxSide.LEFT and side != BoxSide.RIGHT:
		return false
	var fruit := conveyor.take_ready_fruit()
	if fruit == null:
		return false
	var box := left_box if side == BoxSide.LEFT else right_box
	box.add_fruit(fruit)
	changed.emit()
	return true


## 左右の箱を同時出荷して合計得点を返す。両方空の場合は出荷しない。
func ship() -> int:
	if state != State.PLAYING or (left_box.weight == 0 and right_box.weight == 0):
		return 0
	var points := ScoreCalculator.calculate(left_box.weight, settings.target_weight)
	points += ScoreCalculator.calculate(right_box.weight, settings.target_weight)
	score += points
	left_box.clear()
	right_box.clear()
	shipped.emit(points)
	changed.emit()
	return points
