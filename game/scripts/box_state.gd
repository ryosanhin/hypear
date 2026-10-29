class_name BoxState
extends RefCounted
## 箱の累積重量を管理する。

signal shipped(shipped_weight: int)
signal weight_changed(current_weight: int)

var weight := 0


## 輸送物の重量を加算する。[br]
## [param cargo_item_data]: 投入する輸送物。
func add(cargo_item_data: CargoItemData) -> void:
	weight += cargo_item_data.weight
	weight_changed.emit(weight)


## 出荷する。
func ship() -> void:
	shipped.emit(weight)
