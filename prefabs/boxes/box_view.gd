class_name BoxView
extends Node2D
## 箱の表示を担当する。

signal reached_ship_entry_position(box_view: BoxView)

const ANIMATION_NAME := &"close"
const BORDER_FRAME := 2
const SHIP_ENTRY_SPEED := 72.0 * 2.0

@export var _sprite: Sprite2D
@export var _animated_sprite: AnimatedSprite2D
@export var _debug_label: Label

var _box_state: BoxState


## コンストラクタの代わり。[br]
## [param init_box_state]: 参照する箱の状態。
func construct(init_box_state: BoxState) -> BoxView:
	unbind_state()
	_box_state = init_box_state
	_box_state.weight_changed.connect(_update_weight_display)
	_update_weight_display(_box_state.current_weight)
	_animated_sprite.hide()
	return self


## 参照中の箱の状態との接続を解除する。
func unbind_state() -> void:
	if _box_state == null:
		return
	if _box_state.weight_changed.is_connected(_update_weight_display):
		_box_state.weight_changed.disconnect(_update_weight_display)
	_box_state = null


## 蓋を閉じながら指定位置へ移動し、到着した箱自身を通知する。[br]
## [param ship_entry_position]: 移動先のグローバル座標。
func ship_to(ship_entry_position: Vector2) -> void:
	_animated_sprite.frame_changed.connect(_delete_unlidded_box_view)
	_animated_sprite.show()
	_animated_sprite.play(ANIMATION_NAME)

	var distance := (ship_entry_position - global_position).length()
	var elapse_time := distance / SHIP_ENTRY_SPEED
	var tween := create_tween()
	tween.tween_property(
			self,
			"global_position",
			ship_entry_position,
			elapse_time,
	)

	await tween.finished

	reached_ship_entry_position.emit(self)


## 重量に合わせて箱の表示を切り替える。[br]
## [param current_weight]: 現在の重さ。
func _update_weight_display(current_weight: int) -> void:
	_sprite.frame = _calculate_sprite_frame(current_weight, _box_state.target_weight)
	_debug_label.text = "%d" % current_weight


## スプライトの表示フレームを計算する。[br]
## [param current_weight]: 現在の重さ。[br]
## [param target_weight]: 目標の重さ。
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


## 蓋が閉じたフレームで開いた箱の表示を隠す。
func _delete_unlidded_box_view() -> void:
	if _animated_sprite.frame == BORDER_FRAME:
		_sprite.hide()
