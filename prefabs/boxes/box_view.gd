class_name BoxView
extends Node2D
## 箱の表示を担当する。

@export var _sprite: Sprite2D
@export var _debug_label: Label

var _box_state: BoxState


## コンストラクタの代わり。[br]
## [param init_box_state]: 参照する箱の状態。
func construct(init_box_state: BoxState) -> BoxView:
	unbind_state()
	_box_state = init_box_state
	_box_state.weight_changed.connect(_debug_display)
	_box_state.shipped.connect(_ship_animation)
	_debug_display(_box_state.weight)
	return self


## 参照中の箱の状態との接続を解除する。
func unbind_state() -> void:
	if _box_state == null:
		return
	if _box_state.weight_changed.is_connected(_debug_display):
		_box_state.weight_changed.disconnect(_debug_display)
	if _box_state.shipped.is_connected(_ship_animation):
		_box_state.shipped.disconnect(_ship_animation)
	_box_state = null


## 出荷済みの表示が後続の重量更新を受けないようにする。[br]
## [param _shipped_weight]: 出荷した箱の重量。
func _ship_animation(_shipped_weight: int) -> void:
	unbind_state()


## デバッグ用の表示。
func _debug_display(weight: int) -> void:
	_debug_label.text = "%d" % weight
