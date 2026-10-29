class_name CargoItem
extends Node2D
## 輸送物シーンの大きさと重量の数値表示を担当する。

const BASE_WEIGHT: float = 5.0

@export var _sprite: Sprite2D
@export var _label: Label


## 基準重量5に対する重量比の立方根で輸送物を拡縮し、デバッグ表示を更新する。[br]
## [param weight]: 輸送物の重量。[br]
## [param show_weight]: 数値を表示するか。
func construct(weight: int, show_weight: bool) -> CargoItem:
	var size_ratio: float = pow(float(weight) / BASE_WEIGHT, 1.0 / 3.0)
	_sprite.scale = Vector2.ONE * size_ratio
	_label.text = "%d" % weight
	_label.visible = show_weight
	return self
