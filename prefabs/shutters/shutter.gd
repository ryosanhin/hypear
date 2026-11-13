extends TextureRect

const CLOSE_DURATION := 0.5
const SHAKE_DURATION := 0.05
const SHAKE_COUNT := 5

## アニメーション開始地点。
@export var _entry_point: Vector2 = Vector2(-48.0, -816.0)
## アニメーション終了地点。
@export var _end_point: Vector2 = Vector2(-48.0, -48.0)
## 振動アニメーションのX軸範囲。
@export var _shake_range_x: Vector2 = Vector2(-24.0, 24.0)
## 振動アニメーションのY軸範囲。
@export var _shake_range_y: Vector2 = Vector2(-24.0, 24.0)


## シャッターが閉まるアニメーションをする。
func async_close() -> void:
	position = _entry_point
	var close_tween := create_tween()
	close_tween.tween_property(self, "position", _end_point, CLOSE_DURATION)
	
	await close_tween.finished

	var shake_count := 0
	while shake_count < SHAKE_COUNT:
		var target_point := Vector2(
				randf_range(_shake_range_x.x, _shake_range_x.y),
				randf_range(_shake_range_y.x, _shake_range_y.y),
		)
		# 実際に欲しいのはアニメーション終了地点からどれほど離れているか。
		var actual_vector := target_point + _end_point
		var shake_tween := create_tween()
		shake_tween.tween_property(self, "position", actual_vector, SHAKE_DURATION)
		shake_count += 1
		await shake_tween.finished
	
	position = _end_point



