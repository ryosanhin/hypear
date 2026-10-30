class_name ShippingConveyor
extends Node2D
## 出荷された箱を経路に沿って搬送し、終端で解放する。

@export_range(1.0, 2000.0) var speed: float = 144.0
@export var _path: Path2D

var _followers: Array[PathFollow2D] = []


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
	_followers.append(follower)


## 経路の進行方向へ箱を搬送し、終端に到着した箱を除去する。[br]
## [param delta]: 前回の更新からの経過秒数。
func advance(delta: float) -> void:
	if delta <= 0.0 or not is_finite(delta):
		return
	var length := _path.curve.get_baked_length()
	for index in range(_followers.size() - 1, -1, -1):
		var follower := _followers[index]
		follower.progress = minf(follower.progress + speed * delta, length)
		if follower.progress >= length:
			_followers.remove_at(index)
			_path.remove_child(follower)
			follower.queue_free()
