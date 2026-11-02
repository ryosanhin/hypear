class_name ShippingConveyor
extends Node2D
## 出荷ごとの周期で、箱の乗せ位置への移動と経路上の搬送を管理する。

class BoxTransport:
	extends RefCounted
	var box: BoxView
	var follower: PathFollow2D


class Shipment:
	extends RefCounted
	var stepper: DiscreteStepper
	var transports: Array[BoxTransport] = []


@export_range(1.0, 2000.0) var speed: float = 144.0
@export var _path: Path2D

var _shipments: Array[Shipment] = []
var _is_running: bool = true


## 同時出荷する箱の周期をゼロから開始する。既存の出荷の周期には触れない。[br]
## [param boxes]: 同じ起点と周期を共有する出荷済みの箱。[br]
## [param tick_interval]: 一回の更新に使用するゲーム内秒数。
func start_shipment(boxes: Array[BoxView], tick_interval: float) -> void:
	var shipment := Shipment.new()
	shipment.stepper = DiscreteStepper.new(tick_interval)
	for box in boxes:
		var transport := BoxTransport.new()
		transport.box = box
		shipment.transports.append(transport)
	_shipments.append(shipment)


## 各出荷の周期を独立して進め、完了した出荷を取り除く。[br]
## [param delta]: 倍率適用済みのゲーム内経過秒数。
func advance(delta: float) -> void:
	if not _is_running:
		return
	for shipment: Shipment in _shipments.duplicate():
		for index in shipment.stepper.take_steps(delta):
			_advance_shipment(shipment, shipment.stepper.tick_interval)
			if shipment.transports.is_empty():
				break
		if shipment.transports.is_empty():
			_shipments.erase(shipment)


## 一回分の時間を下向き移動と経路移動に分配する。[br]
## [param shipment]: 更新対象の出荷。[br]
## [param delta]: 一回分の固定更新秒数。
func _advance_shipment(shipment: Shipment, delta: float) -> void:
	for transport: BoxTransport in shipment.transports.duplicate():
		var remaining := delta
		if transport.follower == null:
			remaining = transport.box.advance_ship_entry(delta)
			if not transport.box.is_at_ship_entry():
				continue
			transport.follower = _accept_box(transport.box)
		var follower := transport.follower
		var length := _path.curve.get_baked_length()
		follower.progress = minf(follower.progress + speed * remaining, length)
		if follower.progress >= length:
			shipment.transports.erase(transport)
			_path.remove_child(follower)
			follower.queue_free()


## 到着した箱を出荷経路上に配置する。[br]
## [param box]: ベルトの乗せ位置に到着した箱。
func _accept_box(box: BoxView) -> PathFollow2D:
	var follower := PathFollow2D.new()
	follower.loop = false
	follower.rotates = false
	_path.add_child(follower)
	var local_position := _path.to_local(box.global_position)
	follower.progress = _path.curve.get_closest_offset(local_position)
	box.reparent(follower)
	box.position = Vector2.ZERO
	return follower


## ゲーム終了時に全出荷をその場で停止し、蓄積時間を破棄する。
func stop() -> void:
	_is_running = false
	for shipment in _shipments:
		shipment.stepper.reset()


## 全出荷の表示と周期を除去し、新しいゲームの出荷を受け付ける。
func clear() -> void:
	for shipment in _shipments:
		for transport in shipment.transports:
			var view: Node = transport.follower if transport.follower != null else transport.box
			view.get_parent().remove_child(view)
			view.queue_free()
	_shipments.clear()
	_is_running = true
