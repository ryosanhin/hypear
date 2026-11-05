class_name FruitGenerator
extends RefCounted
## 設定された重み付き確率から果実を生成する。

var _settings: DemoSettings
var _random := RandomNumberGenerator.new()


## 生成設定を保持する。[br]
## [param settings]: 重量と相対的な出現確率を持つ設定。
func _init(settings: DemoSettings) -> void:
	_settings = settings


## 設定された重量の果実を一個生成する。[br]
## 抽選失敗時には null を返す。
func generate() -> CargoItemData:
	var index := _random.rand_weighted(_settings.fruit_probabilities)
	if index < 0:
		push_error("果実の抽選に失敗しました。")
		return null

	return CargoItemData.new(_settings.fruit_weights[index])
