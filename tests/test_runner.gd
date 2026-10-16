extends SceneTree
## 外部アドオンを使用せず、ゲームロジックとシーン接続を検証する。

var _failures: int = 0
var _checks: int = 0


## ツリー準備後にテストを開始する。
func _initialize() -> void:
	_run.call_deferred()


## 各テストを実行して失敗数を終了コードへ反映する。
func _run() -> void:
	_test_generation()
	_test_fifo_and_sorting()
	_test_shipping()
	_test_timing_and_states()
	_test_overflow_and_retry()
	await _test_scene_flow()
	print("Checks: %d, failures: %d" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


## 条件を集計し、失敗時に説明を出力する。[br]
## [param condition]: 成功条件。[br]
## [param message]: 検証内容。
func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)


## 一種類だけ出現する検証用設定を作成する。[br]
## [param weight]: 生成する果実の重量。
func _settings(weight: int = 5) -> DemoSettings:
	var settings := DemoSettings.new()
	settings.fruit_weights = [weight]
	settings.fruit_probabilities = [1.0]
	return settings


## 設定された重量と出現確率を検証する。
func _test_generation() -> void:
	for weight in [2, 3, 5, 7, 10]:
		var generator := FruitGenerator.new(_settings(weight))
		_check(generator.generate().weight == weight, "生成重量: %d" % weight)
	var settings := DemoSettings.new()
	settings.fruit_probabilities = [0.0, 0.0, 1.0, 0.0, 0.0]
	var generator := FruitGenerator.new(settings)
	for index in 30:
		_check(generator.generate().weight == 5, "確率0の重量は生成しない")
	settings.fruit_probabilities = [0.0, 0.0, 0.0, 0.0, 0.0]
	_check(not settings.is_valid(), "全確率0を拒否")
	settings.fruit_probabilities = [1.0]
	_check(not settings.is_valid(), "重量と確率の個数不一致を拒否")
	settings.fruit_probabilities = [1.0, -1.0, 1.0, 1.0, 1.0]
	_check(not settings.is_valid(), "負の出現確率を拒否")


## 生成順、左右への投入、処理後の待機列を検証する。
func _test_fifo_and_sorting() -> void:
	var session := GameSession.new(DemoSettings.new())
	session.start()
	for index in 4:
		session.supply()
	var original := session.get_queue()
	_check(session.sort_fruit(GameSession.BoxSide.RIGHT), "右に仕分け可能")
	_check(session.right_box.weight == original[0].weight, "先頭だけが右箱に入る")
	_check(session.left_box.weight == 0, "左箱は変化しない")
	_check(session.get_queue()[0] == original[1], "二個目が先頭に進む")
	_check(session.get_queue().size() == 3, "待機列から一個だけ除去")
	var left_weight := 0
	for index in range(1, original.size()):
		_check(session.get_queue()[0] == original[index], "FIFOを維持")
		left_weight += original[index].weight
		session.sort_fruit(GameSession.BoxSide.LEFT)
	_check(session.left_box.weight == left_weight, "左箱の加算重量")
	_check(not session.sort_fruit(GameSession.BoxSide.LEFT), "空の待機列は操作不可")
	_check(session.get_queue().is_empty(), "全処理後は待機列が空")


## 得点、目標超過、片箱出荷、空箱出荷と出荷後のリセットを検証する。
func _test_shipping() -> void:
	_check(ScoreCalculator.calculate(20, 20) == 100, "目標一致は100点")
	_check(ScoreCalculator.calculate(17, 20) == 85, "不足は差に応じて減点")
	_check(ScoreCalculator.calculate(23, 20) == 85, "超過も同じ差として評価")
	_check(ScoreCalculator.calculate(0, 20) == 0, "空箱は0点")
	_check(ScoreCalculator.calculate(50, 20) == 0, "得点は負にならない")
	var session := GameSession.new(_settings(10))
	var shipments: Array[int] = []
	session.shipped.connect(func(points: int) -> void: shipments.append(points))
	session.start()
	_check(session.ship() == 0 and shipments.is_empty(), "両箱空では出荷しない")
	for index in 2:
		session.supply()
		session.sort_fruit(GameSession.BoxSide.LEFT)
	for index in 3:
		session.supply()
		session.sort_fruit(GameSession.BoxSide.RIGHT)
	_check(session.right_box.weight == 30, "目標超過しても投入できる")
	_check(session.ship() == 150, "左右の得点を合計")
	_check(session.score == 150, "累計得点へ加算")
	_check(session.left_box.weight == 0 and session.right_box.weight == 0, "左右を同時に空にする")
	_check(shipments == [150], "出荷結果を通知")
	session.supply()
	session.sort_fruit(GameSession.BoxSide.LEFT)
	_check(session.ship() == 50, "片方の箱だけでも出荷できる")
	_check(session.score == 200, "複数回の出荷を累計")


## 開始前の操作停止と供給間隔の蓄積を検証する。
func _test_timing_and_states() -> void:
	var settings := _settings()
	settings.supply_interval = 1.0
	var session := GameSession.new(settings)
	session.advance(10.0)
	session.supply()
	_check(session.state == GameSession.State.READY, "初期状態はREADY")
	_check(session.get_queue().is_empty(), "開始前は供給しない")
	_check(not session.sort_fruit(GameSession.BoxSide.LEFT), "開始前は仕分け不可")
	session.start()
	session.advance(0.75)
	_check(session.get_queue().is_empty(), "間隔未到達では生成しない")
	session.advance(0.25)
	_check(session.get_queue().size() == 1, "間隔到達で一個生成")
	session.advance(2.5)
	_check(session.get_queue().size() == 3, "長いフレームでも供給回数を維持")
	session.start()
	_check(session.get_queue().size() == 3, "プレイ中の開始は無視する")


## 上限丁度と上限超過、終了後の停止、リトライ時の完全初期化を検証する。
func _test_overflow_and_retry() -> void:
	var settings := _settings(10)
	settings.queue_capacity = 2
	settings.supply_interval = 1.0
	var session := GameSession.new(settings)
	session.start()
	session.supply()
	session.sort_fruit(GameSession.BoxSide.LEFT)
	session.ship()
	session.supply()
	session.sort_fruit(GameSession.BoxSide.RIGHT)
	session.advance(2.5)
	_check(session.state == GameSession.State.PLAYING, "上限丁度では継続")
	session.advance(0.5)
	_check(session.state == GameSession.State.GAME_OVER, "追加供給でGAME_OVER")
	_check(session.get_queue().size() == 2, "上限を超える果実は列に追加しない")
	session.advance(20.0)
	session.supply()
	_check(not session.sort_fruit(GameSession.BoxSide.LEFT), "終了後は仕分け停止")
	_check(session.ship() == 0, "終了後は出荷停止")
	_check(session.score == 50 and session.right_box.weight == 10, "終了後は得点と箱を維持")
	_check(session.get_queue().size() == 2, "終了後は生成停止")
	session.start()
	_check(session.state == GameSession.State.PLAYING, "リトライでPLAYING")
	_check(session.score == 0 and session.get_queue().is_empty(), "得点と待機列を初期化")
	_check(session.left_box.weight == 0 and session.right_box.weight == 0, "両方の箱を初期化")
	session.advance(0.5)
	_check(session.get_queue().is_empty(), "供給タイマーも初期化")
	session.advance(0.5)
	_check(session.get_queue().size() == 1, "リトライ後も供給できる")


## 実シーンとInputMapを通して開始から終了・リトライまで接続を検証する。
func _test_scene_flow() -> void:
	var scene := load("res://scenes/game/game.tscn").instantiate() as Node2D
	root.add_child(scene)
	scene.set_process(false)
	_check(scene.session.state == GameSession.State.READY, "シーンは開始待ち")
	_check(_mapped_key("sort_left", KEY_LEFT), "左キーのInputMap")
	_check(_mapped_key("sort_right", KEY_RIGHT), "右キーのInputMap")
	_check(_mapped_key("ship_boxes", KEY_DOWN), "下キーのInputMap")
	_press(scene, "start_game")
	_check(scene.session.state == GameSession.State.PLAYING, "入力で開始")
	for index in 2:
		scene.session.supply()
	var first: FruitData = scene.session.get_queue()[0]
	var second: FruitData = scene.session.get_queue()[1]
	_press(scene, "sort_left")
	_press(scene, "sort_right")
	_check(scene.session.left_box.weight == first.weight, "入力で左箱に仕分け")
	_check(scene.session.right_box.weight == second.weight, "入力で右箱に仕分け")
	var expected := ScoreCalculator.calculate(first.weight, scene.settings.target_weight)
	expected += ScoreCalculator.calculate(second.weight, scene.settings.target_weight)
	_press(scene, "ship_boxes")
	_check(scene.session.score == expected, "入力で出荷")
	scene.session.supply()
	scene._process(0.25)
	var fruit: Node2D = scene._fruit_views[scene.session.get_queue()[0]]
	var initial_x := fruit.position.x
	scene._process(0.25)
	_check(fruit.position.x < initial_x, "果実の見た目が前進する")
	var shown: bool = scene._show_weights
	_press(scene, "toggle_weights")
	_check(scene._show_weights != shown, "デバッグ表示を入力で切り替え")
	_check(fruit.get_node("Weight").visible == scene._show_weights, "果実の数値表示も切り替え")
	for index in scene.settings.queue_capacity:
		scene.session.supply()
	_check(scene.session.state == GameSession.State.GAME_OVER, "シーンで上限超過")
	_check(scene.get_node("UI/Overlay").visible, "終了画面を表示")
	_press(scene, "start_game")
	_check(scene.session.score == 0 and scene.session.get_queue().is_empty(), "入力でリトライ")
	_check(not scene.get_node("UI/Overlay").visible, "リトライで終了画面を閉じる")
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
