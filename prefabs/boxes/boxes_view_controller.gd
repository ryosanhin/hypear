class_name BoxesViewController
extends Node
## 箱の表示と状態を対応付け、出荷演出からコンベアへの引き渡しを管理する。

@export var _box_view_prefab: PackedScene
@export var _boxes_view_root: Node2D
@export var _boxes_entry_view_root: Node2D
@export var _shipping_conveyor: ShippingConveyor
@export var _left_box_spawn_marker: Marker2D
@export var _right_box_spawn_marker: Marker2D
@export var _left_box_ship_marker: Marker2D
@export var _right_box_ship_marker: Marker2D

var _left_box_view: BoxView
var _right_box_view: BoxView
var _waiting_boxes: Dictionary[BoxState, BoxView] = {}


## Controllerの終了時に、投入待ちの状態との接続を解除する。
func _exit_tree() -> void:
	for box_state in _waiting_boxes:
		box_state.shipped.disconnect(_on_box_shipped.bind(box_state))
		_waiting_boxes[box_state].unbind_state()
	_waiting_boxes.clear()


## 左右の状態に対応する新しい箱表示を用意する。出荷中の箱は残す。[br]
## [param left_state]: 左の投入先となる箱の状態。[br]
## [param right_state]: 右の投入先となる箱の状態。
func create_boxes(left_state: BoxState, right_state: BoxState) -> void:
	_clear_waiting_boxes()
	_left_box_view = _create_box(left_state, _left_box_spawn_marker)
	_right_box_view = _create_box(right_state, _right_box_spawn_marker)


## 状態と表示を対応付け、先に追加した箱が手前になるよう配置する。[br]
## [param box_state]: 表示する箱の状態。[br]
## [param spawn_marker]: 初期配置の目印。
func _create_box(box_state: BoxState, spawn_marker: Marker2D) -> BoxView:
	var box := _box_view_prefab.instantiate() as BoxView
	_boxes_view_root.add_child(box)
	_boxes_view_root.move_child(box, 0)
	box.global_position = spawn_marker.global_position
	box.construct(box_state)
	_waiting_boxes[box_state] = box
	box_state.shipped.connect(_on_box_shipped.bind(box_state), CONNECT_ONE_SHOT)
	box.reached_ship_entry_position.connect(_on_box_reached_ship_entry, CONNECT_ONE_SHOT)
	return box


## 出荷時の表示を固定し、移動中の表示先へ親を変えてから演出を始める。[br]
## [param _shipped_weight]: 出荷した箱の重量。[br]
## [param _target_weight]: 出荷した箱の目標重量。[br]
## [param box_state]: 出荷通知を送った箱の状態。
func _on_box_shipped(_shipped_weight: int, _target_weight: int, box_state: BoxState) -> void:
	var box := _waiting_boxes[box_state]
	var ship_marker := _left_box_ship_marker if box == _left_box_view else _right_box_ship_marker
	_waiting_boxes.erase(box_state)
	if box == _left_box_view:
		_left_box_view = null
	else:
		_right_box_view = null
	box.unbind_state()
	box.reparent(_boxes_entry_view_root)
	_boxes_entry_view_root.move_child(box, 0)
	box.ship_to(ship_marker.global_position)


## 到着を通知した箱自身をコンベアへ渡す。[br]
## [param box]: ベルトの乗せ位置へ到着した箱。
func _on_box_reached_ship_entry(box: BoxView) -> void:
	_shipping_conveyor.accept_box(box)


## 交換前の投入待ちの箱を解除し、表示を取り除く。
func _clear_waiting_boxes() -> void:
	for box_state in _waiting_boxes:
		var box := _waiting_boxes[box_state]
		box_state.shipped.disconnect(_on_box_shipped.bind(box_state))
		box.unbind_state()
		box.get_parent().remove_child(box)
		box.queue_free()
	_waiting_boxes.clear()
	_left_box_view = null
	_right_box_view = null
