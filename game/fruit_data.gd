class_name FruitData
extends RefCounted
## 表示ノードに依存しない、一個の果実の重量。

var weight: int


## 果実を作成する。[br]
## [param fruit_weight]: この果実の重量。
func _init(fruit_weight: int) -> void:
	weight = fruit_weight
