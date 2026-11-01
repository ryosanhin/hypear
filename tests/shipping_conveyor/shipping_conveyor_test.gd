extends SceneTree
## 出荷単位の周期、乗せ位置への到達前後の時間配分と終了を検証する。

const TestHelper := preload("res://tests/supports/test_helper.gd")
const SHIPPING_SCENE := preload("res://prefabs/conveyors/shipping_conveyor.tscn")
const BOX_SCENE := preload("res://prefabs/boxes/box_view.tscn")
var _helper := TestHelper.new(true)
var _fixtures: Array[Node] = []


## テストを遅延開始する。
func _initialize() -> void:
	_run.call_deferred()


## 箱の流れのテストを実行する。
func _run() -> void:
	_test_independent_shipments()
	_test_entry_transition()
	_test_speed_and_cleanup()
	for fixture in _fixtures:
		if fixture is ShippingConveyor:
			fixture.clear()
		fixture.free()
	await _helper.finish(self, "shipping_conveyor")


## 同時出荷の同期と、新しい出荷から独立した周期を検証する。
func _test_independent_shipments() -> void:
	_helper.change_test_name("independent_shipments")
	var shipping := _make_shipping()
	var first := _make_box(Vector2(700, -72), Vector2(700, 0))
	var paired := _make_box(Vector2(300, -72), Vector2(300, 0))
	shipping.start_shipment([first, paired], 0.1)
	shipping.advance(0.09)
	_helper.assert_equal(first.position.y, -72.0, "最初の更新まで移動しない")
	var later := _make_box(Vector2(500, -72), Vector2(500, 0))
	shipping.start_shipment([later], 0.1)
	shipping.advance(0.01)
	_helper.assert_true(is_equal_approx(first.position.y, -57.6), "新規出荷が既存の端数を消さない")
	_helper.assert_equal(first.position.y, paired.position.y, "同時出荷の二箱は同期する")
	_helper.assert_equal(later.position.y, -72.0, "後の出荷は自身の境界を待つ")
	shipping.advance(0.09)
	_helper.assert_true(is_equal_approx(later.position.y, -57.6), "後の出荷が自身の境界で進む")
	_helper.assert_true(is_equal_approx(first.position.y, -57.6), "先の出荷は次の境界を待つ")
	shipping.advance(0.01)
	_helper.assert_true(is_equal_approx(first.position.y, -43.2), "先の出荷も周期を維持")


## 0.04秒で到達した更新の残り時間と、到達前の端数を検証する。
func _test_entry_transition() -> void:
	_helper.change_test_name("entry_transition")
	var shipping := _make_shipping()
	var box := _make_box(Vector2(700, -BoxView.SHIP_ENTRY_SPEED * 0.14), Vector2(700, 0))
	shipping.start_shipment([box], 0.1)
	shipping.advance(0.15)
	_helper.assert_true(is_equal_approx(box.global_position.y, -5.76), "一回分だけ下向きに進む")
	_helper.assert_false(box.get_parent() is PathFollow2D, "到達前は経路へ載せない")
	shipping.advance(0.05)
	_helper.assert_true(box.get_parent() is PathFollow2D, "持ち越した端数で到達更新を実行")
	_helper.assert_true(is_equal_approx(box.global_position.x, 700.0 - shipping.speed * 0.06), "残り0.06秒だけ経路上を進む")
	var position := box.global_position
	shipping.advance(0.09)
	_helper.assert_equal(box.global_position, position, "到達後も元の次の境界を待つ")
	shipping.advance(0.01)
	_helper.assert_true(is_equal_approx(box.global_position.x, position.x - shipping.speed * 0.1), "到達後も同じ周期で進む")


## 更新間隔に依存しない速度、停止と全経路の後始末を検証する。
func _test_speed_and_cleanup() -> void:
	_helper.change_test_name("speed_and_cleanup")
	for interval in [0.05, 0.1, 0.2]:
		var shipping := _make_shipping()
		var box := _make_box(Vector2(700, -72), Vector2(700, 0))
		shipping.start_shipment([box], interval)
		shipping.advance(1.0)
		_helper.assert_true(is_equal_approx(box.global_position.x, 628.0), "間隔を変えても1秒の搬送距離を保つ")
		shipping.stop()
		var position := box.global_position
		shipping.advance(3.0)
		_helper.assert_equal(box.global_position, position, "終了後は経路移動を停止する")
		shipping.clear()
		_helper.assert_null(box.get_parent().get_parent(), "古い経路をツリーから外す")
		var next := _make_box(Vector2(700, -72), Vector2(700, 0))
		shipping.start_shipment([next], interval)
		shipping.advance(interval * 0.9)
		_helper.assert_equal(next.position.y, -72.0, "再開始に古い端数を引き継がない")
		shipping.advance(30.0)
		_helper.assert_equal(shipping.get_node("Path2D").get_child_count(), 0, "長いフレームでも終端で解放予約する")


## 実際の出荷コンベアを準備する。
func _make_shipping() -> ShippingConveyor:
	var shipping := SHIPPING_SCENE.instantiate() as ShippingConveyor
	root.add_child(shipping)
	_fixtures.append(shipping)
	return shipping


## 出荷通知済みの箱を準備する。[br]
## [param position]: 初期位置。[br]
## [param destination]: コンベアへ載せる位置。
func _make_box(position: Vector2, destination: Vector2) -> BoxView:
	var box := BOX_SCENE.instantiate() as BoxView
	var marker := Marker2D.new()
	root.add_child(box)
	root.add_child(marker)
	box.position = position
	marker.position = destination
	var state := BoxState.new()
	box.construct(state, marker)
	state.ship()
	_fixtures.append(marker)
	# 箱は出荷コンベアが解放する。未到達の箱も同様にclearで取り除く。
	return box
