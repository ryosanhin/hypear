class_name CargoItemData
extends RefCounted
## 表示ノードに依存しない、一個の重量。

var weight: int


## 輸送物データを作成する。[br]
## [param fruit_weight]: 重量。
func _init(init_weight: int) -> void:
	weight = init_weight
