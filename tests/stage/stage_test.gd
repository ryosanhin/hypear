extends SceneTree
## 実ステージの手元表示、左右の投入ポーズと出荷箱の搬送を検証する。

const TestHelper := preload("res://tests/supports/test_helper.gd")
const STAGE_SCENE := preload("res://scenes/stages/stage.tscn")

var _helper := TestHelper.new(true)


## ツリーの準備後にテストを開始する。
func _initialize() -> void:
	_run.call_deferred()


## ステージの連携を検証し、結果を集計する。
func _run() -> void:
	await _test_stage_flow()
	await _helper.finish(self, "stage")


## 到着から左右の仕分け、出荷と経路終端での解放までを確認する。
func _test_stage_flow() -> void:
	_helper.change_test_name("stage_flow")
	var stage := STAGE_SCENE.instantiate() as GameSession
	root.add_child(stage)
	stage.set_process(false)
	var conveyor := stage.get_node("MainConveyor") as MainConveyor
	var character := stage.get_node("Character") as SortingCharacter
	var body := character.get_node("Body") as Sprite2D
	var held := character.get_node("Body/HoldPoint/Pear") as CargoItem
	var front := body.texture
	_press(stage, "sort_left")
	_helper.assert_same(body.texture, front, "果実がない入力ではポーズを変えない")

	var arrivals: Array[CargoItemData] = []
	conveyor.reached_terminal.connect(
			func(item: CargoItemData) -> void: arrivals.append(item),
	)
	var first := CargoItemData.new(5)
	var second := CargoItemData.new(3)
	conveyor.add_cargo_item(first)
	conveyor.advance(0.2)
	conveyor.add_cargo_item(second)
	conveyor.advance(20.0)
	var path := conveyor.get_node("FruitPath") as Path2D
	var first_follower := path.get_child(0) as PathFollow2D
	var second_follower := path.get_child(1) as PathFollow2D
	_helper.assert_true(held.visible, "到着した果実を手元に表示する")
	_helper.assert_equal(held.get_node("DebugLabel").text, "5", "到着した重量を表示する")
	_helper.assert_false(first_follower.visible, "到着した果実をコンベア上で二重表示しない")
	_helper.assert_true(second_follower.visible, "搬送中の後続果実は表示する")
	conveyor.advance(0.1)
	_helper.assert_equal(arrivals.size(), 1, "終端で待機中は到着通知を繰り返さない")

	_press(stage, "sort_left")
	_helper.assert_equal(stage._left_box_state.weight, first.weight, "左入力で左箱へ投入する")
	_helper.assert_same(body.texture, character._left_pose_texture, "左入力で左の投入画像を使う")
	_helper.assert_false(body.flip_h, "左投入では画像を反転しない")
	_helper.assert_false(held.visible, "投入した果実を手元から消す")
	conveyor.advance(0.25)
	await character.get_node("Timer").timeout
	_helper.assert_same(body.texture, front, "タイマーで正面画像へ戻る")
	_helper.assert_true(held.visible, "投入ポーズ中に到着した後続果実を復帰後に表示する")
	_helper.assert_equal(held.get_node("DebugLabel").text, "3", "後続果実の重量へ更新する")
	_helper.assert_false(second_follower.visible, "後続果実も到着後はコンベア上から隠す")
	_helper.assert_equal(arrivals.size(), 2, "後続果実の到着も通知する")
	_press(stage, "sort_right")
	_helper.assert_equal(stage._right_box_state.weight, second.weight, "右入力で右箱へ投入する")
	_helper.assert_same(body.texture, character._left_pose_texture, "右画像未設定時は左画像を使う")
	_helper.assert_true(body.flip_h, "右入力では左画像を反転する")
	_helper.assert_false(held.visible, "右投入後も手元に果実を残さない")

	var left_box := stage._left_box
	var right_box := stage._right_box
	_press(stage, "ship_boxes")
	await create_timer(1.2).timeout
	var shipping := stage.get_node("ShippingConveyor") as ShippingConveyor
	var shipping_path := shipping.get_node("Path2D") as Path2D
	_helper.assert_equal(shipping_path.get_child_count(), 2, "出荷した左右の箱を経路に載せる")
	_helper.assert_true(left_box.get_parent() is PathFollow2D, "左箱を経路の追従ノードへ渡す")
	_helper.assert_true(right_box.get_parent() is PathFollow2D, "右箱を経路の追従ノードへ渡す")
	var left_position := left_box.global_position
	var right_position := right_box.global_position
	stage.advance(0.25)
	_helper.assert_true(left_box.global_position.x < left_position.x, "中枢の更新で左箱が左へ進む")
	_helper.assert_true(right_box.global_position.x < right_position.x, "中枢の更新で右箱が左へ進む")
	_helper.assert_true(
			is_equal_approx(left_box.global_position.y, left_position.y),
			"箱は出荷ベルトの高さを保つ",
	)
	_helper.assert_not_equal(stage._left_box, left_box, "出荷後の投入先には新しい箱を用意する")
	shipping.advance(30.0)
	_helper.assert_equal(shipping_path.get_child_count(), 0, "終端に到着した追従ノードを除去する")
	await process_frame
	_helper.assert_false(is_instance_valid(left_box), "終端に到着した左箱を解放する")
	_helper.assert_false(is_instance_valid(right_box), "終端に到着した右箱を解放する")
	stage.queue_free()
	await process_frame


## 指定アクションの入力をステージへ渡す。[br]
## [param stage]: 検証対象のステージ。[br]
## [param action]: 入力するアクション名。
func _press(stage: GameSession, action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	stage._unhandled_input(event)
