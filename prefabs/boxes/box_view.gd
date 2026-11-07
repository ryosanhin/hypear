class_name BoxView
extends Node2D
## 箱の表示を担当する。

signal reached_ship_entry_position(box_view: BoxView)

const ANIMATION_NAME := &"close"
const BORDER_FRAME := 2

@export var _sprite: Sprite2D
@export var _animated_sprite: AnimatedSprite2D
@export var _debug_label: Label

const SHIP_ENTRY_SPEED := 72.0 * 2.0

var _box_state: BoxState
var _ship_entry_marker: Marker2D


## コンストラクタの代わり。[br]
## [param init_box_state]: 参照する箱の状態。
func construct(init_box_state: BoxState, init_ship_entry_marker: Marker2D) -> BoxView:
	_box_state = init_box_state
	_box_state.weight_changed.connect(_update_weight_display)
	_box_state.shipped.connect(_ship_animation_async)
	_update_weight_display(_box_state.current_weight)
	_ship_entry_marker = init_ship_entry_marker
	_animated_sprite.hide()
	return self


## 参照中の箱の状態との接続を解除する。
func unbind_state() -> void:
	if _box_state == null:
		return
	if _box_state.weight_changed.is_connected(_update_weight_display):
		_box_state.weight_changed.disconnect(_update_weight_display)
	if _box_state.shipped.is_connected(_ship_animation_async):
		_box_state.shipped.disconnect(_ship_animation_async)
	_box_state = null


## 出荷済みの表示が後続の重量更新を受けないようにする。[br]
## [param _shipped_weight]: 出荷した箱の重量。
func _ship_animation_async(_shipped_weight: int) -> void:
	unbind_state()
	
	_animated_sprite.frame_changed.connect(_delete_unlidded_box_view)
	_animated_sprite.show()
	_animated_sprite.play(ANIMATION_NAME)

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



## 箱の表示切替。
func _update_weight_display(current_weight: int) -> void:
	_sprite.frame = _calculate_sprite_frame(current_weight, _box_state.target_weight)
	_debug_label.text = "%d" % current_weight


## スプライトの表示フレームを計算する。[br]
## [param current_weight]: 現在の重さ。[br]
## [param current_weight]: 目標の重さ。
func _calculate_sprite_frame(current_weight: int, target_weight: int) -> int:
	var rate := float(current_weight) / float(target_weight)
	if rate <= 0.0:
		return 0
	if rate < 0.2:
		return 1
	if rate < 0.4:
		return 2
	if rate < 0.6:
		return 3
	if rate < 0.8:
		return 4
	return 5


func _delete_unlidded_box_view() -> void:
	if _animated_sprite.frame == BORDER_FRAME:
		_sprite.hide()
