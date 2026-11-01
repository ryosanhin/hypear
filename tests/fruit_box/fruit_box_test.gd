extends SceneTree
## 箱の重量の接続、出荷後の切断と移動時間の引き継ぎを検証する。

const TestHelper := preload("res://tests/supports/test_helper.gd")
const BOX_SCENE := preload("res://prefabs/boxes/box_view.tscn")
var _helper := TestHelper.new(true)


## テストを遅延開始する。
func _initialize() -> void:
	_run.call_deferred()


## 出荷状態と残り時間を確認する。
func _run() -> void:
	_helper.change_test_name("shipping_entry")
	var box := BOX_SCENE.instantiate() as BoxView
	var marker := Marker2D.new()
	root.add_child(box)
	root.add_child(marker)
	marker.position = Vector2(0.0, BoxView.SHIP_ENTRY_SPEED * 0.04)
	var state := BoxState.new()
	box.construct(state, marker)
	state.add(CargoItemData.new(7))
	state.add(CargoItemData.new(10))
	_helper.assert_equal(state.weight, 17, "重量を累積する")
	state.ship()
	_helper.assert_equal(box.position, Vector2.ZERO, "出荷通知だけでは移動しない")
	_helper.assert_false(state.weight_changed.has_connections(), "出荷した表示を状態から切断する")
	var remaining := box.advance_ship_entry(0.1)
	_helper.assert_true(is_equal_approx(remaining, 0.06), "到達に使わなかった0.06秒を返す")
	_helper.assert_true(box.is_at_ship_entry(), "乗せ位置に到達する")
	_helper.assert_true(box.position.is_equal_approx(marker.position), "乗せ位置で停止する")
	box.free()
	marker.free()
	await _helper.finish(self, "fruit_box")
