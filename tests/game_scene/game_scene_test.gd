extends SceneTree
## 実エンジンの通常倍率と2倍速で、ステージの各流れの速度を検証する。

const TestHelper := preload("res://tests/supports/test_helper.gd")
const STAGE_SCENE := preload("res://scenes/stages/stage.tscn")
const FrameProbe := preload("fixtures/frame_probe.gd")
var _helper := TestHelper.new(true)


## テストを遅延開始する。
func _initialize() -> void:
	_run.call_deferred()


## 倍率を変更したエンジンのdeltaを受け、二重適用がないことを確認する。
func _run() -> void:
	var original_scale := Engine.time_scale
	for scale in [1.0, 2.0]:
		await _test_engine_time_scale(scale)
	Engine.time_scale = original_scale
	await _helper.finish(self, "game_scene")


## エンジンから受けた秒数と果実・箱の実際の搬送距離を比較する。[br]
## [param scale]: エンジンに設定する時間倍率。
func _test_engine_time_scale(scale: float) -> void:
	_helper.change_test_name("engine_time_scale_%s" % scale)
	Engine.time_scale = scale
	# 倍率変更前に計算済みのフレームを測定対象から外す。
	await process_frame
	var stage := STAGE_SCENE.instantiate() as GameSession
	stage.is_start_automatically = false
	stage.settings = DemoSettings.new()
	stage.settings.supply_interval = 0.2
	root.add_child(stage)
	stage.start_game()
	stage.supply()
	var fruit := stage._main_conveyor.get_node("FruitPath").get_child(0) as PathFollow2D
	stage._left_box_state.add(CargoItemData.new(5))
	var box := stage._left_box
	stage.ship()
	var probe := FrameProbe.new()
	probe.session = stage
	root.add_child(probe)
	await probe.finished
	var game_time: float = floor((probe.elapsed + 1.0e-10) / 0.1) * 0.1
	_helper.assert_true(game_time > 0.0, "実エンジンのフレームでゲーム内時間を進める")
	_helper.assert_true(is_equal_approx(fruit.progress, stage.settings.conveyor_speed * game_time), "果実のdeltaへ倍率を二重適用しない")
	var expected_count := 1 + int(floor((game_time + 1.0e-10) / 0.2))
	_helper.assert_equal(stage._main_conveyor.get_queue().size(), expected_count, "供給もゲーム内時間に追従する")
	var entry_time := minf(game_time, 0.5)
	var expected_y := 600.0 + BoxView.SHIP_ENTRY_SPEED * entry_time
	_helper.assert_true(is_equal_approx(box.global_position.y, expected_y), "下向き移動も同じゲーム内時間で進む")
	var belt_time := maxf(0.0, game_time - 0.5)
	var expected_x := 288.0 - stage._shipping_conveyor.speed * belt_time
	_helper.assert_true(is_equal_approx(box.global_position.x, expected_x), "パス移動にも倍率を二重適用しない")
	print("Engine.time_scale=%s: 30フレームのゲーム内経過時間=%s秒" % [scale, probe.elapsed])
	probe.queue_free()
	stage.queue_free()
	await process_frame
