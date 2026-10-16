extends SceneTree
## 指定重量方式の得点計算を検証する。

const TestHelper := preload("res://tests/supports/test_helper.gd")

var _helper := TestHelper.new(true)


## ツリーの準備後にこのスクリプトのテストを開始する。
func _initialize() -> void:
	_run.call_deferred()


## この対象のテストを実行し、共通ヘルパーで結果を集計する。
func _run() -> void:
	_test_score_calculation()
	await _helper.finish(self, "score_calculator")


## 目標一致、不足、超過、空箱と最低得点を確認する。
func _test_score_calculation() -> void:
	_helper.change_test_name("score_calculation")
	_helper.assert_equal(ScoreCalculator.calculate(20, 20), 100, "目標一致は100点")
	_helper.assert_equal(ScoreCalculator.calculate(17, 20), 85, "不足は差に応じて減点")
	_helper.assert_equal(ScoreCalculator.calculate(23, 20), 85, "超過も同じ差として評価")
	_helper.assert_equal(ScoreCalculator.calculate(0, 20), 0, "空箱は0点")
	_helper.assert_equal(ScoreCalculator.calculate(50, 20), 0, "得点は負にならない")
