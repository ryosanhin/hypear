extends Node2D
## 果実の仮描画。重量の色・大きさと数値ラベルだけを担当する。

var _weight: int = 2

@onready var _label: Label = $Weight


## 表示する重量とデバッグ表示を更新する。[br]
## [param weight]: 果実の重量。[br]
## [param show_weight]: 数値を表示するか。
func configure(weight: int, show_weight: bool) -> void:
	_weight = weight
	_label.text = str(weight)
	_label.visible = show_weight
	queue_redraw()


## 重量に応じた円を描画する。
func _draw() -> void:
	var radius := clampf(10.0 + sqrt(float(_weight)) * 3.0, 12.0, 23.0)
	var color := Color.from_hsv(fmod(float(_weight) * 0.087, 1.0), 0.55, 0.95)
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color("24364b"), 2.0)
