extends "res://game/demo_settings.gd"
## 一種類の果実だけを生成する、生成テスト専用の設定。


## 指定重量だけが生成される設定を作成する。[br]
## [param weight]: 生成する果実の重量。
func _init(weight: int) -> void:
	fruit_weights = [weight]
	fruit_probabilities = [1.0]
