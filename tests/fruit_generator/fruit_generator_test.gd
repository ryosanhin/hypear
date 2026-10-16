extends SceneTree
## 設定された重量と出現確率に従う果実生成を検証する。

const TestHelper := preload("res://tests/supports/test_helper.gd")
const SingleWeightSettings := preload("fixtures/single_weight_settings.gd")
const ONLY_FIVE_SETTINGS := preload("fixtures/only_five_settings.tres")

var _helper := TestHelper.new(true)


## ツリーの準備後にこのスクリプトのテストを開始する。
func _initialize() -> void:
	_run.call_deferred()


## この対象のテストを実行し、共通ヘルパーで結果を集計する。
func _run() -> void:
	_test_generation()
	await _helper.finish(self, "fruit_generator")


## 設定された重量と出現確率を検証する。
func _test_generation() -> void:
	_helper.change_test_name("generation")
	for weight in [2, 3, 5, 7, 10]:
		var generator := FruitGenerator.new(SingleWeightSettings.new(weight))
		_helper.assert_equal(generator.generate().weight, weight, "生成重量: %d" % weight)
	# 出現させる重量を一種類に絞り、確率に依存したテストの不安定さを避ける。
	var settings := ONLY_FIVE_SETTINGS.duplicate() as DemoSettings
	var generator := FruitGenerator.new(settings)
	for index in 30:
		_helper.assert_equal(generator.generate().weight, 5, "確率0の重量は生成しない")
