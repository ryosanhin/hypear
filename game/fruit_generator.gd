class_name FruitGenerator
extends RefCounted
## 設定された重み付き確率から果実を生成する。

var _settings: DemoSettings
var _random := RandomNumberGenerator.new()


## 生成設定を保持する。[br]
## [param settings]: 重量と相対的な出現確率を持つ設定。
func _init(settings: DemoSettings) -> void:
	_settings = settings


## 設定された重量の果実を一個生成する。
func generate() -> FruitData:
	var total := 0.0
	for probability in _settings.fruit_probabilities:
		total += probability
	var value := _random.randf() * total
	var last_positive := 0
	for index in _settings.fruit_weights.size():
		var probability := _settings.fruit_probabilities[index]
		if probability <= 0.0:
			continue
		last_positive = index
		value -= probability
		if value < 0.0:
			return FruitData.new(_settings.fruit_weights[index])
	return FruitData.new(_settings.fruit_weights[last_positive])
