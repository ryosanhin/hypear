extends SceneTree
## 箱コンポーネントの重量保持と表示更新を検証する。

const TestHelper := preload("res://tests/supports/test_helper.gd")
const BOX_SCENE := preload("res://views/box_view.tscn")

var _helper := TestHelper.new(true)


## ツリーの準備後にテストを開始する。
func _initialize() -> void:
	_run.call_deferred()


## 実シーンの重量加算、超過と初期化を検証する。
func _run() -> void:
	_helper.change_test_name("weight_and_display")
	var box := BOX_SCENE.instantiate() as BoxView
	root.add_child(box)
	box.configure(20)
	box.add_fruit(FruitData.new(7))
	box.add_fruit(FruitData.new(10))
	_helper.assert_equal(box.weight, 17, "重量を累積する")
	_helper.assert_equal(box.get_node("Weight").text, "17 / 20", "表示にも反映する")
	box.add_fruit(FruitData.new(10))
	_helper.assert_equal(box.weight, 27, "目標超過も受け入れる")
	_helper.assert_equal(box.get_node("Weight").modulate, Color("ffb09b"), "超過を色で示す")
	box.clear()
	_helper.assert_equal(box.weight, 0, "箱を空にする")
	_helper.assert_equal(box.get_node("Weight").text, "0 / 20", "表示もリセットする")
	_helper.assert_equal(box.get_node("Weight").modulate, Color.WHITE, "表示色もリセットする")
	box.free()
	await _helper.finish(self, "fruit_box")
