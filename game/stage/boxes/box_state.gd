class_name BoxState
extends RefCounted
## 箱の累積重量を管理する。

signal shipped(shipped_weight: int, target_weight: int)
signal weight_changed(current_weight: int, target_weight: int)

var target_weight := 0
var current_weight := 0


## コンストラクタ。[br]
## [param init_target_weight]: 目標重量。
func _init(init_target_weight: int) -> void:
	target_weight = init_target_weight


## 輸送物の重量を加算する。[br]
## [param cargo_item_data]: 投入する輸送物。
func add(cargo_item_data: CargoItemData) -> void:
	current_weight += cargo_item_data.weight
	weight_changed.emit(current_weight, target_weight)


## 出荷する。
func ship() -> void:
	shipped.emit(current_weight, target_weight)
