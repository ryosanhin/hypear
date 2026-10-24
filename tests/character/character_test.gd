extends SceneTree
## 手元表示、左右画像の優先順位、反転補完とポーズ復帰を検証する。

const TestHelper := preload("res://tests/supports/test_helper.gd")
const CHARACTER_SCENE := preload("res://character/character.tscn")

var _helper := TestHelper.new(true)


## ツリーの準備後にテストを開始する。
func _initialize() -> void:
	_run.call_deferred()


## キャラクター表示のテストを集計する。
func _run() -> void:
	_test_holding()
	_test_poses()
	await _helper.finish(self, "character")


## 果実の位置、大きさ、重量表示と非表示化を検証する。
func _test_holding() -> void:
	_helper.change_test_name("holding")
	var character := CHARACTER_SCENE.instantiate() as SortingCharacter
	character.scale = Vector2(0.4, 0.4)
	root.add_child(character)
	var point := character.get_node("Body/HoldPoint") as Node2D
	var view := point.get_child(0) as Node2D
	_helper.assert_false(view.visible, "果実がなければ非表示")
	character.set_fruit(FruitData.new(10), true)
	_helper.assert_true(view.visible, "到着した果実を手元に表示")
	_helper.assert_equal(view.global_position, point.global_position, "HoldPointに果実を置く")
	_helper.assert_true(view.global_scale.is_equal_approx(Vector2.ONE), "キャラクターの倍率で果実を縮めない")
	var pear := view.get_node("Pear") as Sprite2D
	_helper.assert_true(is_equal_approx(pear.scale.x, pow(2.0, 1.0 / 3.0)), "重量比の立方根で拡縮")
	_helper.assert_equal(view.get_node("Weight").text, "10", "果実の重量を表示")
	character.set_fruit(FruitData.new(5), false)
	_helper.assert_false(view.get_node("Weight").visible, "手元の重量も非表示にできる")
	character.set_fruit(null, false)
	_helper.assert_false(view.visible, "取り出した果実を非表示")
	character.free()


## 片側だけ、両側、両側未設定とポーズ終了時の復帰を検証する。
func _test_poses() -> void:
	_helper.change_test_name("poses")
	var character := CHARACTER_SCENE.instantiate() as SortingCharacter
	root.add_child(character)
	var body := character.get_node("Body") as Sprite2D
	var hands := character.get_node("Body/Hands") as Sprite2D
	var view := character.get_node("Body/HoldPoint").get_child(0) as Node2D
	var front := body.texture
	var left := character.left_pose_texture
	var right := GradientTexture2D.new()
	character.set_fruit(FruitData.new(5), true)
	character.show_sort_pose(true)
	_helper.assert_same(body.texture, left, "左画像を使う")
	_helper.assert_false(body.flip_h, "左画像を左用には反転しない")
	_helper.assert_false(hands.visible or view.visible, "横向きでは正面の手と果実を隠す")
	character.show_sort_pose(false)
	_helper.assert_same(body.texture, left, "右未設定なら左画像を使う")
	_helper.assert_true(body.flip_h, "左画像を右用に反転する")
	character.right_pose_texture = right
	character.show_sort_pose(false)
	_helper.assert_same(body.texture, right, "右画像があれば優先する")
	_helper.assert_false(body.flip_h, "専用画像は反転しない")
	character.left_pose_texture = null
	character.show_sort_pose(true)
	_helper.assert_same(body.texture, right, "左未設定なら右画像を使う")
	_helper.assert_true(body.flip_h, "右画像を左用に反転する")
	character._process(character.pose_duration / 2.0)
	_helper.assert_same(body.texture, right, "表示時間の途中ではポーズを維持")
	character._process(character.pose_duration)
	_helper.assert_same(body.texture, front, "表示時間後に正面へ戻る")
	_helper.assert_false(body.flip_h, "正面に反転を残さない")
	_helper.assert_true(hands.visible and view.visible, "正面の手と待機果実を復元")
	character.right_pose_texture = null
	character.show_sort_pose(false)
	_helper.assert_same(body.texture, front, "両側未設定なら正面を維持")
	character.free()
