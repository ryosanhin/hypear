extends Node2D
## 後からキャラクター画像へ差し替える仮表示。


## 頭と胴体を簡易図形で描画する。
func _draw() -> void:
	draw_circle(Vector2(0, -20), 26.0, Color("f2d0a9"))
	draw_rect(Rect2(-30, 10, 60, 55), Color("7eafc8"))
	draw_line(Vector2(-30, 20), Vector2(-55, 40), Color("7eafc8"), 12.0)
	draw_line(Vector2(30, 20), Vector2(55, 40), Color("7eafc8"), 12.0)
