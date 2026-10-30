class_name ShippingConveyor
extends Node2D

@export var _path: Path2D

var _followers: Array[PathFollow2D]


## 到着した箱を出荷経路上に配置する。[br]
## [param box]: ベルトの乗せ位置に到着した箱。
func accept_box(box: BoxView) -> void:
	var follower := PathFollow2D.new()
	follower.loop = false
	follower.rotates = false
	_path.add_child(follower)

	var local_position := _path.to_local(box.global_position)
	follower.progress = _path.curve.get_closest_offset(local_position)

	box.reparent(follower)
	box.position = Vector2.ZERO
