class_name BoxView
extends Node2D
## 箱の表示を担当する。

const SHIP_ENTRY_SPEED := 72.0 * 2.0

@export var _sprite: Sprite2D
@export var _debug_label: Label

var _box_state: BoxState
var _ship_entry_marker: Marker2D
var _ship_entry_position: Vector2


## コンストラクタの代わり。[br]
## [param init_box_state]: 参照する箱の状態。[br]
## [param init_ship_entry_marker]: 出荷コンベアの乗せ位置。
func construct(init_box_state: BoxState, init_ship_entry_marker: Marker2D) -> BoxView:
	unbind_state()
	_box_state = init_box_state
	_box_state.weight_changed.connect(_debug_display)
	_box_state.shipped.connect(_on_shipped)
	_debug_display(_box_state.weight)
	_ship_entry_marker = init_ship_entry_marker
	return self


## 参照中の箱の状態との接続を解除する。
func unbind_state() -> void:
	if _box_state == null:
		return
	if _box_state.weight_changed.is_connected(_debug_display):
		_box_state.weight_changed.disconnect(_debug_display)
	if _box_state.shipped.is_connected(_on_shipped):
		_box_state.shipped.disconnect(_on_shipped)
	_box_state = null


## 出荷済みの表示が後続の重量更新を受けないようにする。[br]
## [param _shipped_weight]: 出荷した箱の重量。
func _on_shipped(_shipped_weight: int) -> void:
	_ship_entry_position = _ship_entry_marker.global_position
	unbind_state()


## 乗せ位置まで等速で移動し、到達に使わなかった秒数を返す。[br]
## [param delta]: この更新で使用できるゲーム内秒数。
func advance_ship_entry(delta: float) -> float:
	var duration := global_position.distance_to(_ship_entry_position) / SHIP_ENTRY_SPEED
	var consumed := minf(delta, duration)
	global_position = global_position.move_toward(_ship_entry_position, SHIP_ENTRY_SPEED * consumed)
	return maxf(0.0, delta - consumed)


## コンベアの乗せ位置に到着しているかを返す。
func is_at_ship_entry() -> bool:
	return global_position.is_equal_approx(_ship_entry_position)


## 重量表示を更新する。[br]
## [param weight]: 箱の現在重量。
func _debug_display(weight: int) -> void:
	_debug_label.text = "%d" % weight
