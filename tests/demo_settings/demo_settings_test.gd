extends SceneTree
## デモ設定の妥当性を検証する。

const TestHelper := preload("res://tests/supports/test_helper.gd")

var _helper := TestHelper.new(true)


## ツリーの準備後にこのスクリプトのテストを開始する。
func _initialize() -> void:
	_run.call_deferred()


## この対象のテストを実行し、共通ヘルパーで結果を集計する。
func _run() -> void:
	_test_invalid_probabilities()
	await _helper.finish(self, "demo_settings")


## 生成できない確率設定を無効と判定することを確認する。
func _test_invalid_probabilities() -> void:
	_helper.change_test_name("invalid_probabilities")
	var settings := DemoSettings.new()
	settings.fruit_probabilities = [0.0, 0.0, 0.0, 0.0, 0.0]
	_helper.assert_false(settings.is_valid(), "全確率0を拒否")
	settings.fruit_probabilities = [1.0]
	_helper.assert_false(settings.is_valid(), "重量と確率の個数不一致を拒否")
	settings.fruit_probabilities = [1.0, -1.0, 1.0, 1.0, 1.0]
	_helper.assert_false(settings.is_valid(), "負の出現確率を拒否")
