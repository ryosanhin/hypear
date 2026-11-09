extends SceneTree
## 実ステージの投入順、出荷得点と容量超過による終了を検証する。

const TestHelper := preload("res://tests/supports/test_helper.gd")
const STAGE_SCENE := preload("res://scenes/stages/stage.tscn")

var _helper := TestHelper.new(true)


## ツリーの準備後にテストを開始する。
func _initialize() -> void:
	_run.call_deferred()


## 数値と状態の連携だけを検証し、結果を集計する。
func _run() -> void:
	_test_sorting_order()
	_test_shipping_scores()
	_test_capacity_game_over()
	await _helper.finish(self, "stage")


## 異なる重量の果実が供給順に一個ずつ箱へ入ることを確認する。
func _test_sorting_order() -> void:
	_helper.change_test_name("sorting_order")
	var stage := _make_stage()
	var conveyor := stage._main_conveyor
	conveyor.add_cargo_item(CargoItemData.new(7))
	conveyor.advance(1.0)
	conveyor.add_cargo_item(CargoItemData.new(3))
	conveyor.advance(20.0)
	stage.sort_cargo_item(GameSession.BoxSide.LEFT)
	conveyor.advance(1.0)
	stage.sort_cargo_item(GameSession.BoxSide.RIGHT)
	_helper.assert_array(
			[stage._left_box_state.current_weight, stage._right_box_state.current_weight],
			[7, 3], "供給順の重量を左右の箱へ加算する",
	)
	_helper.assert_true(conveyor.get_queue().is_empty(), "投入した果実を待機列に残さない")
	_dispose_stage(stage)


## 左右の合計点、空箱への交換と連続出荷時の累計点を確認する。
func _test_shipping_scores() -> void:
	_helper.change_test_name("shipping_scores")
	var stage := _make_stage()
	for index in 2:
		_supply_and_sort(stage, GameSession.BoxSide.LEFT)
	for index in 3:
		_supply_and_sort(stage, GameSession.BoxSide.RIGHT)
	_helper.assert_equal(stage.ship(), 150, "左20と右30の出荷得点を合計する")
	_helper.assert_equal(stage.score, 150, "出荷得点を累計へ加算する")
	_helper.assert_array(
			[stage._left_box_state.current_weight, stage._right_box_state.current_weight],
			[0, 0], "出荷後は左右の投入先を空箱に交換する",
	)
	_supply_and_sort(stage, GameSession.BoxSide.LEFT)
	_helper.assert_equal(stage.ship(), 50, "次の箱にも投入し、片箱だけで出荷できる")
	_helper.assert_equal(stage.ship(), 0, "両箱が空なら出荷得点は0")
	_helper.assert_equal(stage.score, 200, "連続出荷を累計し、空箱では加点しない")
	_dispose_stage(stage)


## 時間経過による供給と容量上限、終了後の数値の維持を確認する。
func _test_capacity_game_over() -> void:
	_helper.change_test_name("capacity_game_over")
	var stage := _make_stage(2)
	_supply_and_sort(stage, GameSession.BoxSide.LEFT)
	stage.ship()
	_supply_and_sort(stage, GameSession.BoxSide.RIGHT)
	stage.advance(2.0)
	_helper.assert_equal(stage._main_conveyor.get_queue().size(), 2, "二間隔で二個供給する")
	_helper.assert_equal(stage.state, GameSession.State.PLAYING, "容量丁度では継続する")
	stage._main_conveyor.advance(20.0)
	stage.advance(1.0)
	_helper.assert_equal(stage.state, GameSession.State.GAME_OVER, "次の供給で容量超過となり終了する")
	stage.advance(1.0)
	stage.supply()
	stage.sort_cargo_item(GameSession.BoxSide.LEFT)
	stage.ship()
	_helper.assert_array(
			[
				stage.score, stage._left_box_state.current_weight,
				stage._right_box_state.current_weight, stage._main_conveyor.get_queue().size(),
			],
			[50, 0, 10, 2], "終了後は得点・左右の重量・待機数を変えない",
	)
	_dispose_stage(stage)


## 設定を複製し、重量10を手動進行で供給する実ステージを用意する。[br]
## [param capacity]: 果実の待機容量。
func _make_stage(capacity: int = 10) -> GameSession:
	var stage := STAGE_SCENE.instantiate() as GameSession
	stage.settings = stage.settings.duplicate() as DemoSettings
	stage.settings.fruit_weights = [10]
	stage.settings.fruit_probabilities = PackedFloat32Array([1.0])
	stage.settings.supply_interval = 1.0
	stage.settings.conveyor_speed = 360.0
	stage.settings.queue_capacity = capacity
	stage.settings.target_weight = 20
	stage.is_start_automatically = false
	root.add_child(stage)
	stage.set_process(false)
	stage.start_game()
	return stage


## 一個供給し、到着させてから指定した箱へ投入する。[br]
## [param stage]: 検証対象のステージ。[br]
## [param side]: 投入先の箱。
func _supply_and_sort(stage: GameSession, side: GameSession.BoxSide) -> void:
	stage.supply()
	stage._main_conveyor.advance(20.0)
	stage.sort_cargo_item(side)


## 出荷時のTweenを手動で完了させ、待機中の処理を残さず破棄する。[br]
## [param stage]: 検証を終えたステージ。
func _dispose_stage(stage: GameSession) -> void:
	for tween in get_processed_tweens():
		tween.custom_step(60.0)
	stage.free()
