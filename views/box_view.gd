extends Node2D
## 箱の仮表示。重量の保持やスコア計算は行わない。

@onready var _label: Label = $Weight


## 箱の表示を更新する。[br]
## [param weight]: 現在重量。[br]
## [param target]: 目標重量。
func update_weight(weight: int, target: int) -> void:
	_label.text = "%d / %d" % [weight, target]
	_label.modulate = Color("ffb09b") if weight > target else Color.WHITE


## 仮の箱を描画する。
func _draw() -> void:
	draw_rect(Rect2(-130, -55, 260, 110), Color("74593d"))
	draw_rect(Rect2(-130, -55, 260, 110), Color("dcb77b"), false, 4.0)
	draw_line(Vector2(-130, -30), Vector2(130, -30), Color("dcb77b"), 3.0)
