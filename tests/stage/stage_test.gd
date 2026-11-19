extends SceneTree
## 実ステージの投入順、出荷得点と終了結果を検証する。

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
	_test_clear_at_target_score()
	_test_capacity_game_over()
	_test_blocked_entrance_game_over()
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
	for _index in 2:
		_supply_and_sort(stage, GameSession.BoxSide.LEFT)
	for _index in 2:
		_supply_and_sort(stage, GameSession.BoxSide.RIGHT)
	_helper.assert_equal(stage.ship(), 260, "左右とも目標重量なら基礎点200に均等ボーナス60を加える")
	_helper.assert_equal(stage.score, 260, "出荷得点を累計へ加算する")
	_helper.assert_array(
			[stage._left_box_state.current_weight, stage._right_box_state.current_weight],
			[0, 0], "出荷後は左右の投入先を空箱に交換する",
	)
	_supply_and_sort(stage, GameSession.BoxSide.LEFT)
	_supply_and_sort(stage, GameSession.BoxSide.LEFT)
	_helper.assert_equal(stage.ship(), 100, "片箱だけ目標重量なら基礎点100を得る")
	_helper.assert_equal(stage.ship(), 0, "両箱が空なら出荷得点は0")
	_helper.assert_equal(stage.score, 360, "連続出荷を累計し、空箱では加点しない")
	_dispose_stage(stage)


## 累計得点が目標と一致する場合と超える場合の終了結果を確認する。
func _test_clear_at_target_score() -> void:
	_helper.change_test_name("clear_at_target_score")
	for target_score in [200, 199]:
		var stage := _make_stage(target_score)
		var results := _record_finish(stage)
		_supply_and_sort(stage, GameSession.BoxSide.LEFT)
		_supply_and_sort(stage, GameSession.BoxSide.LEFT)
		stage.ship()
		_helper.assert_true(
				stage.state == GameSession.State.PLAYING and results.is_empty(),
				"累計得点が目標%d点未満なら続行する" % target_score,
		)
		_supply_and_sort(stage, GameSession.BoxSide.RIGHT)
		_supply_and_sort(stage, GameSession.BoxSide.RIGHT)
		stage.advance(0.5)
		stage.ship()
		stage.advance(10.0)
		stage.supply()
		stage.ship()
		_helper.assert_array(
				results, [[GameSession.State.CLEARED, 200, 0.5, GameSession.State.CLEARED, 200, 0.5]],
				"目標%d点に達したときの確定結果を一度だけ通知する" % target_score,
		)
		_helper.assert_array(
				[stage.score, stage.elapsed_seconds, stage._main_conveyor.get_cargo_item_count()],
				[200, 0.5, 0], "クリア後は得点・時間・待機数を変えない",
		)
		_dispose_stage(stage)


## 容量いっぱいでの続行、次の供給での終了と終了後の数値の維持を確認する。
func _test_capacity_game_over() -> void:
	_helper.change_test_name("capacity_game_over")
	var stage := _make_stage()
	var results := _record_finish(stage)
	_supply_and_sort(stage, GameSession.BoxSide.LEFT)
	_supply_and_sort(stage, GameSession.BoxSide.LEFT)
	stage.ship()
	var score_before_game_over := stage.score
	_supply_and_sort(stage, GameSession.BoxSide.RIGHT)
	stage.advance(10.0)
	_helper.assert_equal(stage._main_conveyor.get_cargo_item_count(), 10, "十間隔で十個供給する")
	_helper.assert_true(
			stage.state == GameSession.State.PLAYING and results.is_empty(),
			"容量ちょうどでは継続する",
	)
	stage.advance(5.0)
	stage.advance(1.0)
	stage.supply()
	stage.sort_cargo_item(GameSession.BoxSide.LEFT)
	stage.ship()
	_helper.assert_array(
			results,
			[[
				GameSession.State.GAME_OVER, score_before_game_over, 11.0,
				GameSession.State.GAME_OVER, score_before_game_over, 11.0,
			]],
			"次の供給に失敗した時点の確定結果を一度だけ通知する",
	)
	_helper.assert_array(
			[
				stage.score, stage.elapsed_seconds, stage._left_box_state.current_weight,
				stage._right_box_state.current_weight, stage._main_conveyor.get_cargo_item_count(),
			],
			[score_before_game_over, 11.0, 0, 10, 10],
			"終了後は得点・時間・左右の重量・待機数を変えない",
	)
	_dispose_stage(stage)


## 空き容量があっても入口が塞がっていれば次の供給で終了することを確認する。
func _test_blocked_entrance_game_over() -> void:
	_helper.change_test_name("blocked_entrance_game_over")
	var stage := _make_stage()
	stage.supply()
	stage.supply()
	_helper.assert_array(
			[stage.state, stage._main_conveyor.get_cargo_item_count()],
			[GameSession.State.GAME_OVER, 1], "入口が詰まったまま供給すると終了する",
	)
	_dispose_stage(stage)


## 終了通知の引数と、通知時点のステージの状態・得点・時刻を記録する。[br]
## [param stage]: 終了通知を記録するステージ。
func _record_finish(stage: GameSession) -> Array[Array]:
	var results: Array[Array] = []
	stage.game_finished.connect(
			func(result: GameSession.State, score: int, elapsed_seconds: float) -> void:
				results.append([
					result, score, elapsed_seconds,
					stage.state, stage.score, stage.elapsed_seconds,
				]),
	)
	return results


## 設定を複製し、重量10を手動進行で供給する実ステージを用意する。[br]
## [param target_score]: ステージクリアに必要な累計得点。
func _make_stage(target_score: int = 600) -> GameSession:
	var stage := STAGE_SCENE.instantiate() as GameSession
	stage.settings = stage.settings.duplicate() as DemoSettings
	stage.settings.fruit_weights = [10]
	stage.settings.fruit_probabilities = PackedFloat32Array([1.0])
	stage.settings.supply_interval = 1.0
	stage.settings.conveyor_speed = 360.0
	stage.settings.queue_capacity = 10
	stage.settings.target_weight = 20
	stage.settings.target_score = target_score
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
