class_name WeighingScale
extends Sprite2D
## 現在の重さを表示する。

const TARGET_ANGLE_DEGREES := 225.0
const INDICATE_LIMIT := 270.0 / TARGET_ANGLE_DEGREES
const ANGLE_OFFSET := -135.0

@export var _hand: Sprite2D

var _observing_box_state: BoxState


## 監視対象の[BoxState]を登録する。[br]
## [param box_state]: 箱の状態。
func configure_observe_box(box_state: BoxState) -> void:
	_unbind_state()
	_observing_box_state = box_state
	box_state.weight_changed.connect(_update_weighting_scale)
	box_state.shipped.connect(_cancel_observing)
	_update_weighting_scale(box_state.current_weight, box_state.target_weight)


## 監視対象の箱との接続と参照を解除する。
func _unbind_state() -> void:
	if _observing_box_state == null:
		return
	if _observing_box_state.weight_changed.is_connected(_update_weighting_scale):
		_observing_box_state.weight_changed.disconnect(_update_weighting_scale)
	if _observing_box_state.shipped.is_connected(_cancel_observing):
		_observing_box_state.shipped.disconnect(_cancel_observing)
	_observing_box_state = null


## 重量変化時に表示を切り替える。[br]
## [param current_weight]: 現在の重量。[br]
## [param target_weight]: 目標の重量。
func _update_weighting_scale(current_weight: int, target_weight: int) -> void:
	var ratio := float(current_weight) / float(target_weight)
	if ratio > INDICATE_LIMIT:
		ratio = INDICATE_LIMIT
	_hand.rotation = deg_to_rad(ratio * TARGET_ANGLE_DEGREES + ANGLE_OFFSET)


## 出荷時に監視対象の箱のモデルへのシグナル接続を解除し、[br]
## 回転をリセットする。
func _cancel_observing(_current_weight: int, _target_weight: int) -> void:
	_unbind_state()
	_hand.rotation = deg_to_rad(ANGLE_OFFSET)
