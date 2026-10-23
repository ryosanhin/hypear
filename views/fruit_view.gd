extends Node2D
## 果実シーンの大きさと重量の数値表示を担当する。

const BASE_WEIGHT: float = 5.0

@onready var _pear: Sprite2D = $Pear
@onready var _label: Label = $Weight


## 基準重量5に対する比で果実を拡縮し、デバッグ表示を更新する。[br]
## [param weight]: 果実の重量。[br]
## [param show_weight]: 数値を表示するか。
func configure(weight: int, show_weight: bool) -> void:
	var size_ratio := float(weight) / BASE_WEIGHT
	_pear.scale = Vector2.ONE * size_ratio
	_label.position.y = _pear.offset.y * size_ratio - _label.size.y / 2.0
	_label.text = str(weight)
	_label.visible = show_weight
