extends Node2D
## コンベアの仮描画。果実の並び順や移動は管理しない。


## レール、ローラーと仕分け位置を描画する。
func _draw() -> void:
	draw_style_box(_make_belt_style(), Rect2(445, 235, 490, 90))
	for x in range(460, 930, 28):
		draw_line(Vector2(x, 248), Vector2(x, 312), Color("61788b"), 2.0)
	draw_arc(Vector2(480, 280), 31.0, 0, TAU, 40, Color("ffe19a"), 3.0)


## 仮ベルト用の背景スタイルを作成する。
func _make_belt_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("344a5c")
	style.border_color = Color("90a7b7")
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	return style
