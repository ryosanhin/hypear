extends SceneTree
## 実シーンの入力、果実移動、表示切替とリトライの接続を検証する。

const TestHelper := preload("res://tests/supports/test_helper.gd")
const GAME_SCENE := preload("res://scenes/game/game.tscn")

var _helper := TestHelper.new(true)


## ツリーの準備後にこのスクリプトのテストを開始する。
func _initialize() -> void:
	_run.call_deferred()


## この対象のテストを実行し、共通ヘルパーで結果を集計する。
func _run() -> void:
	await _test_scene_flow()
	await _helper.finish(self, "game_scene")


## 実シーンとInputMapを通して開始から終了・リトライまで接続を検証する。
func _test_scene_flow() -> void:
	_helper.change_test_name("scene_flow")
	var scene := GAME_SCENE.instantiate() as Node2D
	root.add_child(scene)
	# 供給と移動を手動更新し、実行環境のフレーム速度に依存させない。
	scene.session.set_process(false)
	_helper.assert_equal(scene.session.state, GameSession.State.READY, "シーンは開始待ち")
	_helper.assert_true(_mapped_key("sort_left", KEY_LEFT), "左キーのInputMap")
	_helper.assert_true(_mapped_key("sort_right", KEY_RIGHT), "右キーのInputMap")
	_helper.assert_true(_mapped_key("ship_boxes", KEY_DOWN), "下キーのInputMap")
	_press(scene, "start_game")
	_helper.assert_equal(scene.session.state, GameSession.State.PLAYING, "入力で開始")
	for index in 2:
		scene.session.supply()
		scene.session.conveyor.advance(0.2)
	var first: FruitData = scene.session.conveyor.get_queue()[0]
	var second: FruitData = scene.session.conveyor.get_queue()[1]
	var player := scene.get_node("Player") as SortingCharacter
	var body := player.get_node("Body") as Sprite2D
	var front := body.texture
	var held := player.get_node("Body/HoldPoint").get_child(0) as Node2D
	_press(scene, "sort_left")
	_helper.assert_equal(scene.session.left_box.weight, 0, "到着前の入力は箱へ渡さない")
	_helper.assert_same(body.texture, front, "失敗した入力でポーズを変えない")
	scene.session.advance(0.001)
	scene.session.conveyor.advance(20.0)
	scene.session.advance(0.001)
	_helper.assert_true(held.visible, "到着した果実を手元に表示")
	var arrived := scene.get_node("Conveyor/FruitPath").get_child(0) as PathFollow2D
	_helper.assert_false(arrived.visible, "到着した果実を二重表示しない")
	_press(scene, "sort_left")
	_helper.assert_same(body.texture, player.left_pose_texture, "左投入で横向きへ切り替え")
	_helper.assert_false(body.flip_h or held.visible, "左投入は反転せず果実を消す")
	scene.session.conveyor.advance(20.0)
	_press(scene, "sort_right")
	_helper.assert_true(body.flip_h, "右投入は左画像の反転を使う")
	_helper.assert_equal(scene.session.left_box.weight, first.weight, "入力で左箱に仕分け")
	_helper.assert_equal(scene.session.right_box.weight, second.weight, "入力で右箱に仕分け")
	var expected := ScoreCalculator.calculate(first.weight, scene.session.settings.target_weight)
	expected += ScoreCalculator.calculate(second.weight, scene.session.settings.target_weight)
	_press(scene, "ship_boxes")
	_helper.assert_equal(scene.session.score, expected, "入力で出荷")
	scene.session.supply()
	var follower := scene.get_node("Conveyor/FruitPath").get_child(0) as PathFollow2D
	var initial_position := follower.position
	scene.session.advance(0.25)
	_helper.assert_not_equal(follower.position, initial_position, "果実が経路に沿って前進する")
	var fruit := follower.get_child(0) as Node2D
	var shown: bool = scene._show_weights
	_press(scene, "toggle_weights")
	_helper.assert_not_equal(scene._show_weights, shown, "デバッグ表示を入力で切り替え")
	_helper.assert_equal(fruit.get_node("Weight").visible, scene._show_weights, "果実の数値表示も切り替え")
	for index in scene.session.settings.queue_capacity:
		scene.session.conveyor.advance(0.2)
		scene.session.supply()
	_helper.assert_equal(scene.session.state, GameSession.State.GAME_OVER, "シーンで上限超過")
	_helper.assert_true(scene.get_node("UI/Overlay").visible, "終了画面を表示")
	_press(scene, "start_game")
	_helper.assert_true(scene.session.score == 0 and scene.session.conveyor.get_queue().is_empty(), "入力でリトライ")
	_helper.assert_false(scene.get_node("UI/Overlay").visible, "リトライで終了画面を閉じる")
	_helper.assert_equal(scene.get_node("Conveyor/FruitPath").get_child_count(), 0, "リトライで果実表示も除去")
	_helper.assert_same(body.texture, front, "リトライで正面へ戻す")
	_helper.assert_false(body.flip_h or held.visible, "リトライで手元と反転を初期化")
	scene.queue_free()
	await process_frame


## 指定アクションの入力を画面へ渡す。[br]
## [param scene]: 検証対象の画面。[br]
## [param action]: InputMapのアクション名。
func _press(scene: Node, action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	scene._unhandled_input(event)


## 指定キーがアクションに登録されているかを返す。[br]
## [param action]: アクション名。[br]
## [param key]: 期待する物理キー。
func _mapped_key(action: StringName, key: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == key:
			return true
	return false
