extends SceneTree
## 実コンポーネントを接続した進行管理、仕分けとリトライを検証する。

const TestHelper := preload("res://tests/supports/test_helper.gd")
const FIXED_SETTINGS := preload("fixtures/fixed_weight_settings.tres")

const STAGE_SCENE := preload("res://scenes/stages/stage.tscn")

var _helper := TestHelper.new(true)
var _fixtures: Array[Node] = []


## ツリーの準備後にこのスクリプトのテストを開始する。
func _initialize() -> void:
	_run.call_deferred()


## この対象のテストを実行し、共通ヘルパーで結果を集計する。
func _run() -> void:
	_test_fifo_and_sorting()
	_test_shipping()
	_test_timing_and_states()
	_test_overflow_and_retry()
	_test_discrete_fruit_flow()
	_test_supply_order()
	_test_flow_origins_and_input()
	_test_shipping_restart()
	for fixture in _fixtures:
		fixture.free()
	await _helper.finish(self, "game_session")


## 生成順、左右への投入、処理後の待機列を検証する。
func _test_fifo_and_sorting() -> void:
	_helper.change_test_name("fifo_and_sorting")
	var session := _make_session(DemoSettings.new())
	session.start_game()
	for index in 4:
		session.supply()
		session._main_conveyor.advance(0.2)
	# 重量が偶然一致しても順序違反を検出できるよう、果実の参照を保存する。
	var original := session._main_conveyor.get_queue()
	_helper.assert_false(session.sort_cargo_item(GameSession.BoxSide.LEFT), "到着前は仕分け不可")
	session._main_conveyor.advance(20.0)
	_helper.assert_false(session.sort_cargo_item(-1), "不正な仕分け先は無視する")
	_helper.assert_true(session.sort_cargo_item(GameSession.BoxSide.RIGHT), "右に仕分け可能")
	_helper.assert_equal(session._right_box_state.weight, original[0].weight, "先頭だけが右箱に入る")
	_helper.assert_equal(session._left_box_state.weight, 0, "左箱は変化しない")
	_helper.assert_same(session._main_conveyor.get_queue()[0], original[1], "二個目が先頭に進む")
	_helper.assert_equal(session._main_conveyor.get_queue().size(), 3, "待機列から一個だけ除去")
	var left_weight := 0
	for index in range(1, original.size()):
		_helper.assert_same(session._main_conveyor.get_queue()[0], original[index], "FIFOを維持")
		left_weight += original[index].weight
		session._main_conveyor.advance(20.0)
		session.sort_cargo_item(GameSession.BoxSide.LEFT)
	_helper.assert_equal(session._left_box_state.weight, left_weight, "左箱の加算重量")
	_helper.assert_false(session.sort_cargo_item(GameSession.BoxSide.LEFT), "空の待機列は操作不可")
	_helper.assert_true(session._main_conveyor.get_queue().is_empty(), "全処理後は待機列が空")


## 左右同時出荷、目標超過、片箱出荷、空箱出荷と重量のリセットを確認する。
func _test_shipping() -> void:
	_helper.change_test_name("shipping")
	var session := _make_session(FIXED_SETTINGS.duplicate() as DemoSettings)
	var shipments: Array[int] = []
	session.shipped.connect(func(points: int) -> void: shipments.append(points))
	session.start_game()
	_helper.assert_true(session.ship() == 0 and shipments.is_empty(), "両箱空では出荷しない")
	# 左20・右30を作り、合計150点と超過投入を同時に確認する。
	for index in 2:
		session.supply()
		session._main_conveyor.advance(20.0)
		session.sort_cargo_item(GameSession.BoxSide.LEFT)
	for index in 3:
		session.supply()
		session._main_conveyor.advance(20.0)
		session.sort_cargo_item(GameSession.BoxSide.RIGHT)
	_helper.assert_equal(session._right_box_state.weight, 30, "目標超過しても投入できる")
	_helper.assert_equal(session.ship(), 150, "左右の得点を合計")
	_helper.assert_equal(session.score, 150, "累計得点へ加算")
	_helper.assert_true(session._left_box_state.weight == 0 and session._right_box_state.weight == 0, "左右を同時に空にする")
	_helper.assert_array(shipments, [150], "出荷結果を通知")
	session.supply()
	session._main_conveyor.advance(20.0)
	session.sort_cargo_item(GameSession.BoxSide.LEFT)
	_helper.assert_equal(session.ship(), 50, "片方の箱だけでも出荷できる")
	_helper.assert_equal(session.score, 200, "複数回の出荷を累計")


## 開始前の操作停止と供給間隔の蓄積を検証する。
func _test_timing_and_states() -> void:
	_helper.change_test_name("timing_and_states")
	var settings := FIXED_SETTINGS.duplicate() as DemoSettings
	settings.supply_interval = 1.0
	var session := _make_session(settings)
	session.advance(10.0)
	session.supply()
	_helper.assert_equal(session.state, GameSession.State.READY, "初期状態はREADY")
	_helper.assert_true(session._main_conveyor.get_queue().is_empty(), "開始前は供給しない")
	_helper.assert_false(session.sort_cargo_item(GameSession.BoxSide.LEFT), "開始前は仕分け不可")
	session.start_game()
	session.advance(0.75)
	_helper.assert_true(session._main_conveyor.get_queue().is_empty(), "間隔未到達では生成しない")
	session.advance(0.25)
	_helper.assert_equal(session._main_conveyor.get_queue().size(), 1, "間隔到達で一個生成")
	# 一回の更新で複数回分の供給間隔を跨ぐ場合も確認する。
	session.advance(2.5)
	_helper.assert_equal(session._main_conveyor.get_queue().size(), 3, "長いフレームでも供給回数を維持")
	var path := session._main_conveyor.get_node("FruitPath")
	_helper.assert_true(is_equal_approx(path.get_child(0).progress, 900.0), "先頭は供給後の2.5秒分だけ進む")
	_helper.assert_true(is_equal_approx(path.get_child(1).progress, 540.0), "後続も供給時刻から進む")
	_helper.assert_true(is_equal_approx(path.get_child(2).progress, 180.0), "最後の供給後の残り時間も搬送する")
	session.start_game()
	_helper.assert_equal(session._main_conveyor.get_queue().size(), 3, "プレイ中の開始は無視する")


## 上限丁度と上限超過、終了後の停止、リトライ時の完全初期化を検証する。
func _test_overflow_and_retry() -> void:
	_helper.change_test_name("overflow_and_retry")
	var settings := FIXED_SETTINGS.duplicate() as DemoSettings
	settings.queue_capacity = 2
	settings.supply_interval = 1.0
	var session := _make_session(settings)
	session.start_game()
	# リトライ前に得点と箱の重量を残し、初期値同士の比較になることを避ける。
	session.supply()
	session._main_conveyor.advance(20.0)
	session.sort_cargo_item(GameSession.BoxSide.LEFT)
	session.ship()
	session.supply()
	session._main_conveyor.advance(20.0)
	session.sort_cargo_item(GameSession.BoxSide.RIGHT)
	session.advance(2.5)
	_helper.assert_equal(session.state, GameSession.State.PLAYING, "上限丁度では継続")
	session.advance(0.5)
	_helper.assert_equal(session.state, GameSession.State.GAME_OVER, "追加供給でGAME_OVER")
	_helper.assert_equal(session._main_conveyor.get_queue().size(), 2, "上限を超える果実は列に追加しない")
	var follower := session._main_conveyor.get_node("FruitPath").get_child(0) as PathFollow2D
	var progress_before := follower.progress
	session.advance(20.0)
	_helper.assert_equal(follower.progress, progress_before, "終了後は搬送も停止")
	session.supply()
	_helper.assert_false(session.sort_cargo_item(GameSession.BoxSide.LEFT), "終了後は仕分け停止")
	_helper.assert_equal(session.ship(), 0, "終了後は出荷停止")
	_helper.assert_true(session.score == 50 and session._right_box_state.weight == 10, "終了後は得点と箱を維持")
	_helper.assert_equal(session._main_conveyor.get_queue().size(), 2, "終了後は生成停止")
	session.start_game()
	_helper.assert_equal(session.state, GameSession.State.PLAYING, "リトライでPLAYING")
	_helper.assert_true(session.score == 0 and session._main_conveyor.get_queue().is_empty(), "得点と待機列を初期化")
	_helper.assert_true(session._left_box_state.weight == 0 and session._right_box_state.weight == 0, "両方の箱を初期化")
	session.advance(0.5)
	_helper.assert_true(session._main_conveyor.get_queue().is_empty(), "供給タイマーも初期化")
	session.advance(0.5)
	_helper.assert_equal(session._main_conveyor.get_queue().size(), 1, "リトライ後も供給できる")


## 更新境界まで表示を固定し、設定間隔によらず速度と供給頻度を保つ。
func _test_discrete_fruit_flow() -> void:
	_helper.change_test_name("discrete_fruit_flow")
	var session := _make_session(DemoSettings.new())
	session.start_game()
	session.supply()
	var follower := session._main_conveyor.get_node("FruitPath").get_child(0) as PathFollow2D
	session.advance(0.09)
	_helper.assert_equal(follower.progress, 0.0, "果実も更新間隔まで停止")
	session.advance(0.01)
	_helper.assert_true(is_equal_approx(follower.progress, 36.0), "果実の境界で0.1秒分だけ搬送")
	session.advance(0.25)
	_helper.assert_true(is_equal_approx(follower.progress, 108.0), "長いフレームでも固定更新回数を維持")
	session.advance(0.05)
	_helper.assert_true(is_equal_approx(follower.progress, 144.0), "端数を次回の果実更新へ持ち越す")
	for interval in [0.05, 0.1, 0.2]:
		var settings := DemoSettings.new()
		settings.flow_tick_interval = interval
		settings.supply_interval = 0.35
		var timed := _make_session(settings)
		timed.start_game()
		timed.advance(1.4)
		var path := timed._main_conveyor.get_node("FruitPath")
		_helper.assert_equal(path.get_child_count(), 4, "間隔が供給周期を割り切らなくても頻度を保つ")
		_helper.assert_true(is_equal_approx(path.get_child(0).progress, 378.0), "更新間隔を変えても供給後の搬送距離を保つ")
		_helper.assert_true(is_zero_approx(path.get_child(3).progress), "供給した時点では余分に搬送しない")


## 入口の詰まり判定の前に供給時刻まで搬送する順序を維持する。
func _test_supply_order() -> void:
	_helper.change_test_name("supply_order")
	var settings := DemoSettings.new()
	settings.supply_interval = 0.2
	settings.flow_tick_interval = 0.5
	var session := _make_session(settings)
	session.start_game()
	session.advance(0.5)
	_helper.assert_equal(session.state, GameSession.State.PLAYING, "供給前の搬送で入口が空く")
	var path := session._main_conveyor.get_node("FruitPath")
	_helper.assert_equal(path.get_child_count(), 2, "一更新内でも供給時刻を分ける")
	_helper.assert_true(is_equal_approx(path.get_child(0).progress, 108.0), "先頭は0.2秒の供給後に0.3秒搬送")
	_helper.assert_true(is_equal_approx(path.get_child(1).progress, 36.0), "後続は0.4秒の供給後に0.1秒搬送")
	var blocked := DemoSettings.new()
	blocked.supply_interval = 0.1
	var jammed := _make_session(blocked)
	jammed.start_game()
	jammed.advance(0.3)
	_helper.assert_equal(jammed.state, GameSession.State.GAME_OVER, "必要な間隔が空かなければ入口の詰まりで終了")
	_helper.assert_equal(jammed._main_conveyor.get_queue().size(), 1, "終了後の残り更新を実行しない")


## 果実と二回の出荷の起点が異なり、入力を周期の途中でも即時に処理する。
func _test_flow_origins_and_input() -> void:
	_helper.change_test_name("flow_origins_and_input")
	var session := _make_session(DemoSettings.new())
	session.start_game()
	session.supply()
	session._main_conveyor.advance(20.0)
	session.advance(0.23)
	_press(session, "sort_left")
	_helper.assert_true(session._left_box_state.weight > 0, "0.23秒の入力を次の更新まで待たせない")
	var first := session._left_box
	var paired := session._right_box
	_press(session, "ship_boxes")
	_helper.assert_not_equal(session._left_box, first, "出荷入力でその場で空箱を用意する")
	var first_position := first.global_position
	session.supply()
	var fruit := session._main_conveyor.get_node("FruitPath").get_child(0) as PathFollow2D
	session.advance(0.07) # 共通時間0.30: 果実だけが境界を迎える。
	_helper.assert_true(fruit.progress > 0.0, "果実はゲーム開始起点の0.30秒で進む")
	_helper.assert_equal(first.global_position, first_position, "箱は果実の境界へ揃えない")
	session.advance(0.03) # 0.33: 最初の出荷の境界。
	_helper.assert_true(first.global_position.y > first_position.y, "出荷から0.1秒後に初めて進む")
	_helper.assert_equal(first.global_position.y, paired.global_position.y, "同時出荷した左右の周期を共有")
	session.advance(0.04) # 0.37: 次の出荷。
	session._main_conveyor.advance(20.0)
	_press(session, "sort_right")
	var second := session._right_box
	_press(session, "ship_boxes")
	var second_position := second.global_position
	var before := first.global_position
	session.advance(0.06) # 0.43: 既存出荷だけが境界。
	_helper.assert_true(first.global_position.y > before.y, "次の出荷でも先の周期をリセットしない")
	_helper.assert_equal(second.global_position, second_position, "次の出荷は自身の境界を待つ")
	before = first.global_position
	session.advance(0.04) # 0.47: 後の出荷の境界。
	_helper.assert_true(second.global_position.y > second_position.y, "次の出荷も自身の起点から0.1秒で進む")
	_helper.assert_equal(first.global_position, before, "先の出荷を後の境界へ揃えない")


## 終了時に全出荷を止め、再開始で出荷済み・未出荷の箱を片付ける。
func _test_shipping_restart() -> void:
	_helper.change_test_name("shipping_restart")
	var settings := DemoSettings.new()
	settings.queue_capacity = 1
	var session := _make_session(settings)
	session.start_game()
	session._left_box_state.add(CargoItemData.new(5))
	var on_belt := session._left_box
	session.ship()
	session.advance(0.5)
	session._left_box_state.add(CargoItemData.new(5))
	var old := session._left_box
	var old_state := session._left_box_state
	session.ship()
	session.advance(0.15)
	var before := old.global_position
	var belt_before := on_belt.global_position
	session.supply()
	session.supply()
	session.advance(1.0)
	_helper.assert_equal(old.global_position, before, "ゲーム終了後は下向き移動も停止")
	_helper.assert_equal(on_belt.global_position, belt_before, "ゲーム終了後はパス上の箱も停止")
	var unshipped := session._left_box
	var unshipped_state := session._left_box_state
	session.start_game()
	_helper.assert_null(on_belt.get_parent().get_parent(), "再開始でパス上の旧箱もツリーから除去")
	_helper.assert_null(old.get_parent(), "再開始で搬送中の箱をツリーから除去")
	_helper.assert_null(unshipped.get_parent(), "再開始で未出荷の古い箱も除去")
	_helper.assert_false(old_state.weight_changed.has_connections(), "古い出荷箱への接続を残さない")
	_helper.assert_false(unshipped_state.weight_changed.has_connections(), "古い投入先への接続を残さない")
	session.supply()
	var fruit := session._main_conveyor.get_node("FruitPath").get_child(0) as PathFollow2D
	session.advance(0.05)
	_helper.assert_equal(fruit.progress, 0.0, "再開始で果実の周期もゼロから開始")
	session.advance(0.05)
	_helper.assert_true(is_equal_approx(fruit.progress, 36.0), "再開始後の果実を一度だけ更新する")


## 入力イベントをセッションへ渡す。[br]
## [param session]: 対象のセッション。[br]
## [param action]: 実行する操作。
func _press(session: GameSession, action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	session._unhandled_input(event)


## 実際のコンベアと箱を接続したセッションを準備する。[br]
## [param settings]: 各テスト固有の進行設定。
func _make_session(settings: DemoSettings) -> GameSession:
	var session := STAGE_SCENE.instantiate() as GameSession
	session.is_start_automatically = false
	session.settings = settings
	root.add_child(session)
	session.set_process(false)
	_fixtures.append(session)
	return session
