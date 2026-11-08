extends Sprite2D

const DGREES_RATE := 300.0

@export var _hand: Sprite2D

var _observing_box_state: BoxState


## 監視対象の[BoxState]を登録する。[br]
## [param box_state]: 箱の状態。
func configure_observe_box(box_state: BoxState) -> void:
	_observing_box_state = box_state
	_observing_box_state.weight_changed.connect(_update_weighting_scale)
	_observing_box_state.shipped.connect(_cancel_observing)
	pass


## 重量変化時に表示を切り替える。[br]
## [param current_weight]: 現在の重量。[br]
## [param target_weight]: 目標の重量。
func _update_weighting_scale(current_weight: int, target_weight: int) -> void:
	var ration := float(current_weight) / float(target_weight)
	_hand.rotation = deg_to_rad(ration * DGREES_RATE)


## 出荷時に監視対象の箱のモデルへのシグナル接続を解除し、[br]
## 回転をリセットする。
func _cancel_observing(_current_weight: int, _target_weight: int) -> void:
	if _observing_box_state.weight_changed.is_connected(_update_weighting_scale):
		_observing_box_state.weight_changed.disconnect(_update_weighting_scale)
	if _observing_box_state.shipped.is_connected(_cancel_observing):
		_observing_box_state.shipped.disconnect(_cancel_observing)
	_hand.rotation = 0.0
