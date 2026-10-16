class_name GameSession
extends RefCounted
## FIFO、箱、出荷、ゲーム状態を管理する表示非依存のゲーム本体。

signal changed
signal shipped(points: int)

enum State { READY, PLAYING, GAME_OVER }
enum BoxSide { LEFT, RIGHT }

var state: State = State.READY
var score: int = 0
var left_box := BoxState.new()
var right_box := BoxState.new()
var settings: DemoSettings

var _queue: Array[FruitData] = []
var _generator: FruitGenerator
var _supply_elapsed: float = 0.0


## 使用する設定でゲームを準備する。[br]
## [param demo_settings]: 一回のプレイで使用する設定。
func _init(demo_settings: DemoSettings) -> void:
	assert(demo_settings.is_valid(), "デモ設定が不正です")
	settings = demo_settings
	_generator = FruitGenerator.new(settings)


## 重量、待機列、時間、スコアを初期化して開始する。リトライにも使用する。
func start() -> void:
	if state == State.PLAYING:
		return
	_queue.clear()
	left_box.clear()
	right_box.clear()
	score = 0
	_supply_elapsed = 0.0
	state = State.PLAYING
	changed.emit()


## 経過時間に応じて果実を供給する。[br]
## [param delta]: 前回の更新からの経過秒数。
func advance(delta: float) -> void:
	if state != State.PLAYING or delta <= 0.0:
		return
	_supply_elapsed += delta
	while _supply_elapsed >= settings.supply_interval and state == State.PLAYING:
		_supply_elapsed -= settings.supply_interval
		supply()


## 果実を一個供給する。満杯の状態への追加供給でゲームオーバーにする。
func supply() -> void:
	if state != State.PLAYING:
		return
	if _queue.size() >= settings.queue_capacity:
		state = State.GAME_OVER
	else:
		_queue.append(_generator.generate())
	changed.emit()


## 待機列の参照用コピーを返す。並び順は生成順。
func get_queue() -> Array[FruitData]:
	return _queue.duplicate()


## 先頭果実を箱に投入する。処理できなければfalseを返す。[br]
## [param side]: 投入先の箱。
func sort_fruit(side: BoxSide) -> bool:
	if state != State.PLAYING or _queue.is_empty():
		return false
	if side != BoxSide.LEFT and side != BoxSide.RIGHT:
		return false
	var fruit: FruitData = _queue.pop_front()
	var box := left_box if side == BoxSide.LEFT else right_box
	box.add(fruit)
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
