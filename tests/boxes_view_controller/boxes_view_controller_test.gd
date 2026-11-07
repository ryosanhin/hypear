extends SceneTree
## 実ステージで箱の表示先、連続出荷と状態との対応付けを検証する。

const TestHelper := preload("res://tests/supports/test_helper.gd")
const STAGE_SCENE := preload("res://scenes/stages/stage.tscn")
const BOX_SCENE := preload("res://prefabs/boxes/box_view.tscn")

var _helper := TestHelper.new(true)


## ツリーの準備後にテストを開始する。
func _initialize() -> void:
	_run.call_deferred()


## 箱表示の生成から出荷・解放までを検証し、結果を集計する。
func _run() -> void:
	await _test_overlapping_shipments()
	await _test_waiting_box_replacement()
	await _test_conveyor_transform()
	await _helper.finish(self, "boxes_view_controller")


## 出荷前後の描画順、変換の保持と複数世代の通知を検証する。
func _test_overlapping_shipments() -> void:
	_helper.change_test_name("overlapping_shipments")
	var stage := _make_stage()
	var controller := stage.get_node("BoxesViewController") as BoxesViewController
	var waiting_root := stage.get_node("BoxesViewRoot") as Node2D
	var shipping := stage.get_node("ShippingConveyor") as ShippingConveyor
	var entry_root := shipping.get_node("BoxesEntryViewRoot") as Node2D
	var path := shipping.get_node("Path2D") as Path2D
	_helper.assert_true(
			shipping.get_node("TileMapLayer").get_index() < entry_root.get_index()
			and entry_root.get_index() < path.get_index(),
			"ベルト、移動中、搬送中の箱の順に手前へ描画する",
	)
	var first_left := controller._left_box_view
	var first_right := controller._right_box_view
	_helper.assert_same(first_left.get_parent(), waiting_root, "投入待ちの箱は待機用ルートに置く")
	_helper.assert_true(first_left.get_index() > first_right.get_index(), "先に追加した箱を手前に置く")
	_helper.assert_equal(stage.ship(), 0, "両箱が空なら表示を交換しない")
	_helper.assert_same(controller._left_box_view, first_left, "空箱の出荷判断はGameSessionが担う")
	stage._left_box_state.add(CargoItemData.new(7))
	stage._right_box_state.add(CargoItemData.new(3))
	_helper.assert_equal(first_left.get_node("Sprite2D").frame, 2, "目標に対する重量で表示を更新する")
	_helper.assert_equal(first_right.get_node("DebugLabel").text, "3", "右箱の状態も対応する表示へ届く")
	_helper.assert_equal(
			stage._left_box_state.shipped.get_connections().size(), 1,
			"出荷通知はControllerだけが受ける",
	)

	# 待機先と移動先の変換が異なっても、出荷開始時に表示が飛ばない。
	waiting_root.position = Vector2(11.0, -7.0)
	waiting_root.rotation = 0.1
	waiting_root.scale = Vector2(0.8, 0.9)
	entry_root.position = Vector2(-13.0, 5.0)
	entry_root.rotation = -0.2
	entry_root.scale = Vector2(1.1, 0.7)
	var initial_transform := first_left.global_transform
	var first_state := stage._left_box_state
	_helper.assert_equal(stage.ship(), 50, "採点は左右の状態からGameSessionが行う")
	_helper.assert_same(first_left.get_parent(), entry_root, "演出開始前に移動用ルートへ移す")
	_helper.assert_true(
			first_left.global_transform.is_equal_approx(initial_transform),
			"親変更でグローバル変換を保持する",
	)
	_helper.assert_true(first_left.get_index() > first_right.get_index(), "移動中も先に追加した箱が手前になる")
	_helper.assert_true(first_left.get_node("AnimatedSprite2D").is_playing(), "親変更後に蓋を閉じ始める")
	_helper.assert_true(first_state.weight_changed.get_connections().is_empty(), "出荷開始時に重量との接続を解除する")
	_helper.assert_true(first_state.shipped.get_connections().is_empty(), "出荷通知は一度で切断する")
	first_state.add(CargoItemData.new(10))
	first_state.ship()
	_helper.assert_equal(first_left.get_node("DebugLabel").text, "7", "出荷後に元の状態が変わっても表示を固定する")

	# 最初の箱が到着する前に次の左右も出荷し、その次の投入先を用意する。
	var second_left := controller._left_box_view
	var second_right := controller._right_box_view
	stage._left_box_state.add(CargoItemData.new(20))
	_helper.assert_equal(stage.ship(), 100, "直後の出荷も独立して採点する")
	_helper.assert_equal(stage.score, 150, "連続した出荷の得点を累積する")
	var current_left := controller._left_box_view
	var current_right := controller._right_box_view
	_helper.assert_equal(entry_root.get_child_count(), 4, "二組の出荷箱が同時に存在する")
	_helper.assert_equal(waiting_root.get_child_count(), 2, "投入待ちは次の左右だけになる")
	_helper.assert_true(first_right.get_index() > second_left.get_index(), "後から出荷した箱を奥へ追加する")
	var arrivals: Array[BoxView] = []
	for box in [first_left, first_right, second_left, second_right]:
		box.reached_ship_entry_position.connect(
				func(arrived: BoxView) -> void: arrivals.append(arrived),
		)
	stage._right_box_state.add(CargoItemData.new(5))
	_helper.assert_equal(current_right.get_node("DebugLabel").text, "5", "次の投入先も状態更新を受ける")
	await create_timer(2.0).timeout
	_helper.assert_equal(arrivals.size(), 4, "各箱の到着通知が一度ずつ届く")
	_helper.assert_equal(path.get_child_count(), 4, "全ての出荷箱をコンベアへ渡す")
	for box in [first_left, first_right, second_left, second_right]:
		_helper.assert_true(arrivals.has(box), "到着通知には出荷した箱自身が含まれる")
		_helper.assert_true(box.get_parent() is PathFollow2D, "到着した箱は追従ノードの子になる")
		_helper.assert_same(box.get_parent().get_parent(), path, "出荷経路へ引き渡す")
	_helper.assert_false(first_left.get_node("Sprite2D").visible, "蓋が閉じたら開いた箱を隠す")
	var expected_transform := initial_transform
	expected_transform.origin = controller._left_box_ship_marker.global_position
	_helper.assert_true(
			first_left.global_transform.is_equal_approx(expected_transform),
			"到着後の親変更でも変換を保持する",
	)
	_helper.assert_equal(entry_root.get_child_count(), 0, "到着済みの箱を移動用ルートに残さない")
	_helper.assert_same(current_left.get_parent(), waiting_root, "古い到着通知で新しい左箱を移さない")
	_helper.assert_same(current_right.get_parent(), waiting_root, "古い到着通知で新しい右箱を移さない")
	_helper.assert_true(
			shipping._followers[0].get_index() > shipping._followers[3].get_index(),
			"搬送中も先に受け入れた箱を手前にする",
	)
	var position_before := first_left.global_position
	shipping.advance(0.1)
	_helper.assert_true(first_left.global_position.x < position_before.x, "受け入れた箱を経路に沿って左へ運ぶ")
	shipping.advance(30.0)
	await process_frame
	_helper.assert_false(is_instance_valid(first_left), "終端で最初の箱を解放する")
	_helper.assert_false(is_instance_valid(second_right), "終端で後続の箱も解放する")
	stage.queue_free()
	await process_frame


## 出荷せず箱を交換した場合も古い接続と表示を残さない。
func _test_waiting_box_replacement() -> void:
	_helper.change_test_name("waiting_box_replacement")
	var stage := _make_stage()
	var controller := stage.get_node("BoxesViewController") as BoxesViewController
	var old_state := stage._left_box_state
	var old_box := controller._left_box_view
	old_state.add(CargoItemData.new(10))
	stage.state = GameSession.State.GAME_OVER
	stage.start_game()
	_helper.assert_equal(stage.get_node("BoxesViewRoot").get_child_count(), 2, "再開始時も投入待ちの箱は二つだけ")
	_helper.assert_true(old_state.weight_changed.get_connections().is_empty(), "古い重量更新の接続を外す")
	_helper.assert_true(old_state.shipped.get_connections().is_empty(), "古い出荷通知の接続を外す")
	old_state.ship()
	_helper.assert_equal(
			stage.get_node("ShippingConveyor/BoxesEntryViewRoot").get_child_count(), 0,
			"交換前の状態では新しい箱を出荷しない",
	)
	await process_frame
	_helper.assert_false(is_instance_valid(old_box), "交換した投入待ちの箱を解放する")
	var current_state := stage._left_box_state
	stage.queue_free()
	await process_frame
	_helper.assert_true(
			current_state.weight_changed.get_connections().is_empty(),
			"ステージ終了時に重量の接続を解除する",
	)
	_helper.assert_true(current_state.shipped.get_connections().is_empty(), "ステージ終了時に出荷の接続を解除する")


## 経路外の受け入れ位置でも、親変更で座標や向きが飛ばない。
func _test_conveyor_transform() -> void:
	_helper.change_test_name("conveyor_transform")
	var stage := _make_stage()
	var shipping := stage.get_node("ShippingConveyor") as ShippingConveyor
	shipping.rotation = 0.2
	shipping.scale = Vector2(1.2, 0.8)
	var box := BOX_SCENE.instantiate() as BoxView
	stage.get_node("BoxesViewRoot").add_child(box)
	box.position = Vector2(301.0, 651.0)
	box.rotation = -0.1
	box.scale = Vector2(0.9, 1.1)
	var before := box.global_transform
	shipping.accept_box(box)
	_helper.assert_true(box.global_transform.is_equal_approx(before), "受け入れ位置を経路へ強制的にスナップしない")
	shipping.advance(0.5)
	_helper.assert_not_equal(box.global_position, before.origin, "受け入れ後は経路の進行量で移動する")
	stage.queue_free()
	await process_frame


## 手動で進行できる実ステージを用意する。
func _make_stage() -> GameSession:
	var stage := STAGE_SCENE.instantiate() as GameSession
	root.add_child(stage)
	stage.set_process(false)
	return stage
