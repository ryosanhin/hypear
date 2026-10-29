extends SceneTree
## 実コンベアの経路移動、待機、取り出しと初期化を検証する。

const TestHelper := preload("res://tests/supports/test_helper.gd")
const CONVEYOR_SCENE := preload("res://backgrounds/conveyor.tscn")

var _helper := TestHelper.new(true)


## ツリーの準備後にテストを開始する。
func _initialize() -> void:
	_run.call_deferred()


## 搬送と容量のテストを集計する。
func _run() -> void:
	_test_transport()
	_test_limits()
	await _helper.finish(self, "conveyor")


## 経路上での前進、間隔、到着条件とFIFOを検証する。
func _test_transport() -> void:
	_helper.change_test_name("transport")
	var conveyor := CONVEYOR_SCENE.instantiate() as MainConveyor
	root.add_child(conveyor)
	conveyor.configure(DemoSettings.new())
	var first := CargoItemData.new(2)
	var second := CargoItemData.new(10)
	_helper.assert_true(conveyor.add_fruit(first), "入口で受け入れる")
	_helper.assert_null(conveyor.take_ready_fruit(), "搬送中は取り出せない")
	var path := conveyor.get_node("FruitPath") as Path2D
	var follower := path.get_child(0) as PathFollow2D
	conveyor.advance(0.5)
	_helper.assert_true(is_equal_approx(follower.progress, 180.0), "速度に応じた距離を進む")
	_helper.assert_true(follower.position.is_equal_approx(path.curve.sample_baked(180.0, true)), "経路の座標に一致する")
	_helper.assert_true(conveyor.add_fruit(second), "入口が空いたら後続を受け入れる")
	conveyor.advance(20.0)
	var following := path.get_child(1) as PathFollow2D
	_helper.assert_true(is_equal_approx(follower.progress, path.curve.get_baked_length()), "先頭は終端で停止")
	_helper.assert_true(is_equal_approx(follower.progress - following.progress, conveyor.fruit_spacing), "後続は間隔を空けて停止")
	_helper.assert_false(follower.loop or follower.rotates, "終端で折り返さず、表示を回転させない")
	conveyor.set_show_weights(false)
	_helper.assert_false(following.get_child(0).get_node("Weight").visible, "全果実の重量表示を切り替える")
	_helper.assert_same(conveyor.peek_ready_fruit(), first, "到着した先頭を参照できる")
	_helper.assert_same(conveyor.take_ready_fruit(), first, "生成順で取り出す")
	_helper.assert_null(conveyor.take_ready_fruit(), "後続の到着前は取り出せない")
	var before := following.progress
	conveyor.advance(-1.0)
	_helper.assert_equal(following.progress, before, "負の時間では移動しない")
	conveyor.advance(1.0)
	_helper.assert_same(conveyor.take_ready_fruit(), second, "後続も前進後に取り出せる")
	_helper.assert_equal(path.get_child_count(), 0, "取り出した表示は経路から除去する")
	conveyor.free()


## 入口の重複生成、容量超過、参照コピーと初期化を検証する。
func _test_limits() -> void:
	_helper.change_test_name("limits")
	var conveyor := CONVEYOR_SCENE.instantiate() as MainConveyor
	root.add_child(conveyor)
	var settings := DemoSettings.new()
	settings.queue_capacity = 2
	conveyor.configure(settings)
	_helper.assert_true(conveyor.add_fruit(CargoItemData.new(2)), "一個目を追加")
	_helper.assert_false(conveyor.add_fruit(CargoItemData.new(3)), "入口に重ねて追加しない")
	conveyor.advance(1.0)
	_helper.assert_true(conveyor.add_fruit(CargoItemData.new(3)), "二個目を追加")
	conveyor.advance(1.0)
	_helper.assert_false(conveyor.add_fruit(CargoItemData.new(5)), "容量を超えて追加しない")
	var copy := conveyor.get_queue()
	copy.clear()
	_helper.assert_equal(conveyor.get_queue().size(), 2, "参照用コピーから内部列を変更できない")
	conveyor.clear()
	_helper.assert_true(conveyor.get_queue().is_empty(), "果実を初期化する")
	_helper.assert_equal(conveyor.get_node("FruitPath").get_child_count(), 0, "表示も初期化する")
	_helper.assert_true(conveyor.add_fruit(CargoItemData.new(7)), "初期化後は入口で再度受け入れる")
	conveyor.free()
