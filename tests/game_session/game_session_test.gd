extends SceneTree
## 待機列、仕分け、出荷、進行状態とリトライを検証する。

const TestHelper := preload("res://tests/supports/test_helper.gd")
const FIXED_SETTINGS := preload("fixtures/fixed_weight_settings.tres")

var _helper := TestHelper.new(true)


## ツリーの準備後にこのスクリプトのテストを開始する。
func _initialize() -> void:
	_run.call_deferred()


## この対象のテストを実行し、共通ヘルパーで結果を集計する。
func _run() -> void:
	_test_fifo_and_sorting()
	_test_shipping()
	_test_timing_and_states()
	_test_overflow_and_retry()
	await _helper.finish(self, "game_session")


## 生成順、左右への投入、処理後の待機列を検証する。
func _test_fifo_and_sorting() -> void:
	_helper.change_test_name("fifo_and_sorting")
	var session := GameSession.new(DemoSettings.new())
	session.start()
	for index in 4:
		session.supply()
	# 重量が偶然一致しても順序違反を検出できるよう、果実の参照を保存する。
	var original := session.get_queue()
	_helper.assert_true(session.sort_fruit(GameSession.BoxSide.RIGHT), "右に仕分け可能")
	_helper.assert_equal(session.right_box.weight, original[0].weight, "先頭だけが右箱に入る")
	_helper.assert_equal(session.left_box.weight, 0, "左箱は変化しない")
	_helper.assert_same(session.get_queue()[0], original[1], "二個目が先頭に進む")
	_helper.assert_equal(session.get_queue().size(), 3, "待機列から一個だけ除去")
	var left_weight := 0
	for index in range(1, original.size()):
		_helper.assert_same(session.get_queue()[0], original[index], "FIFOを維持")
		left_weight += original[index].weight
		session.sort_fruit(GameSession.BoxSide.LEFT)
	_helper.assert_equal(session.left_box.weight, left_weight, "左箱の加算重量")
	_helper.assert_false(session.sort_fruit(GameSession.BoxSide.LEFT), "空の待機列は操作不可")
	_helper.assert_true(session.get_queue().is_empty(), "全処理後は待機列が空")


## 左右同時出荷、目標超過、片箱出荷、空箱出荷と重量のリセットを確認する。
func _test_shipping() -> void:
	_helper.change_test_name("shipping")
	var session := GameSession.new(FIXED_SETTINGS.duplicate() as DemoSettings)
	var shipments: Array[int] = []
	session.shipped.connect(func(points: int) -> void: shipments.append(points))
	session.start()
	_helper.assert_true(session.ship() == 0 and shipments.is_empty(), "両箱空では出荷しない")
	# 左20・右30を作り、合計150点と超過投入を同時に確認する。
	for index in 2:
		session.supply()
		session.sort_fruit(GameSession.BoxSide.LEFT)
	for index in 3:
		session.supply()
		session.sort_fruit(GameSession.BoxSide.RIGHT)
	_helper.assert_equal(session.right_box.weight, 30, "目標超過しても投入できる")
	_helper.assert_equal(session.ship(), 150, "左右の得点を合計")
	_helper.assert_equal(session.score, 150, "累計得点へ加算")
	_helper.assert_true(session.left_box.weight == 0 and session.right_box.weight == 0, "左右を同時に空にする")
	_helper.assert_array(shipments, [150], "出荷結果を通知")
	session.supply()
	session.sort_fruit(GameSession.BoxSide.LEFT)
	_helper.assert_equal(session.ship(), 50, "片方の箱だけでも出荷できる")
	_helper.assert_equal(session.score, 200, "複数回の出荷を累計")


## 開始前の操作停止と供給間隔の蓄積を検証する。
func _test_timing_and_states() -> void:
	_helper.change_test_name("timing_and_states")
	var settings := FIXED_SETTINGS.duplicate() as DemoSettings
	settings.supply_interval = 1.0
	var session := GameSession.new(settings)
	session.advance(10.0)
	session.supply()
	_helper.assert_equal(session.state, GameSession.State.READY, "初期状態はREADY")
	_helper.assert_true(session.get_queue().is_empty(), "開始前は供給しない")
	_helper.assert_false(session.sort_fruit(GameSession.BoxSide.LEFT), "開始前は仕分け不可")
	session.start()
	session.advance(0.75)
	_helper.assert_true(session.get_queue().is_empty(), "間隔未到達では生成しない")
	session.advance(0.25)
	_helper.assert_equal(session.get_queue().size(), 1, "間隔到達で一個生成")
	# 一回の更新で複数回分の供給間隔を跨ぐ場合も確認する。
	session.advance(2.5)
	_helper.assert_equal(session.get_queue().size(), 3, "長いフレームでも供給回数を維持")
	session.start()
	_helper.assert_equal(session.get_queue().size(), 3, "プレイ中の開始は無視する")


## 上限丁度と上限超過、終了後の停止、リトライ時の完全初期化を検証する。
func _test_overflow_and_retry() -> void:
	_helper.change_test_name("overflow_and_retry")
	var settings := FIXED_SETTINGS.duplicate() as DemoSettings
	settings.queue_capacity = 2
	settings.supply_interval = 1.0
	var session := GameSession.new(settings)
	session.start()
	# リトライ前に得点と箱の重量を残し、初期値同士の比較になることを避ける。
	session.supply()
	session.sort_fruit(GameSession.BoxSide.LEFT)
	session.ship()
	session.supply()
	session.sort_fruit(GameSession.BoxSide.RIGHT)
	session.advance(2.5)
	_helper.assert_equal(session.state, GameSession.State.PLAYING, "上限丁度では継続")
	session.advance(0.5)
	_helper.assert_equal(session.state, GameSession.State.GAME_OVER, "追加供給でGAME_OVER")
	_helper.assert_equal(session.get_queue().size(), 2, "上限を超える果実は列に追加しない")
	session.advance(20.0)
	session.supply()
	_helper.assert_false(session.sort_fruit(GameSession.BoxSide.LEFT), "終了後は仕分け停止")
	_helper.assert_equal(session.ship(), 0, "終了後は出荷停止")
	_helper.assert_true(session.score == 50 and session.right_box.weight == 10, "終了後は得点と箱を維持")
	_helper.assert_equal(session.get_queue().size(), 2, "終了後は生成停止")
	session.start()
	_helper.assert_equal(session.state, GameSession.State.PLAYING, "リトライでPLAYING")
	_helper.assert_true(session.score == 0 and session.get_queue().is_empty(), "得点と待機列を初期化")
	_helper.assert_true(session.left_box.weight == 0 and session.right_box.weight == 0, "両方の箱を初期化")
	session.advance(0.5)
	_helper.assert_true(session.get_queue().is_empty(), "供給タイマーも初期化")
	session.advance(0.5)
	_helper.assert_equal(session.get_queue().size(), 1, "リトライ後も供給できる")
