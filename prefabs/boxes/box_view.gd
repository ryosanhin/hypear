class_name BoxView
extends Node2D
## 箱の表示を担当する。

signal reached_ship_entry_position(box_view: BoxView)

@export var _sprite: Sprite2D
@export var _debug_label: Label

const SHIP_ENTRY_SPEED := 72.0

var _box_state: BoxState
var _ship_entry_marker: Marker2D


## コンストラクタの代わり。[br]
## [param init_box_state]: 参照する箱の状態。
func construct(init_box_state: BoxState, init_ship_entry_marker: Marker2D) -> BoxView:
	unbind_state()
	_box_state = init_box_state
	_box_state.weight_changed.connect(_debug_display)
	_box_state.shipped.connect(_ship_animation_async)
	_debug_display(_box_state.weight)
	_ship_entry_marker = init_ship_entry_marker
	return self


## 参照中の箱の状態との接続を解除する。
func unbind_state() -> void:
	if _box_state == null:
		return
	if _box_state.weight_changed.is_connected(_debug_display):
		_box_state.weight_changed.disconnect(_debug_display)
	if _box_state.shipped.is_connected(_ship_animation_async):
		_box_state.shipped.disconnect(_ship_animation_async)
	_box_state = null


## 出荷済みの表示が後続の重量更新を受けないようにする。[br]
## [param _shipped_weight]: 出荷した箱の重量。
func _ship_animation_async(_shipped_weight: int) -> void:
	unbind_state()

	var distance := (_ship_entry_marker.global_position - global_position).length()
	var elapse_time := distance / SHIP_ENTRY_SPEED
	var tween := create_tween()
	tween.tween_property(
			self,
			"global_position",
			_ship_entry_marker.global_position,
			elapse_time,
	)
	
	await tween.finished

	reached_ship_entry_position.emit(self)



## デバッグ用の表示。
func _debug_display(weight: int) -> void:
	_debug_label.text = "%d" % weight
