class_name BoxState
extends RefCounted
## 箱の累積重量を管理する。

signal shipped(shipped_weight: int)
signal weight_changed(current_weight: int)

var _target_weight: int

var weight := 0


## コンストラクタ。目標重量を設定する。[br]
## [param init_target_weight]: 目標重量。
func _init(init_target_weight: int) -> void:
	_target_weight = init_target_weight


## 輸送物の重量を加算する。[br]
## [param cargo_item_data]: 投入する輸送物。
func add(cargo_item_data: CargoItemData) -> void:
	weight += cargo_item_data.weight


## 出荷する。
func ship() -> void:
	shipped.emit(weight)
	weight = 0
	weight_changed.emit(weight)


## 箱を空にする。
func clear() -> void:
	weight = 0
	weight_changed.emit(weight)
