class_name SortingCharacter
extends Node2D
## 手元の果実表示と左右への投入ポーズを担当する。

var _front_texture: Texture2D
@export var _left_pose_texture: Texture2D
@export var _right_pose_texture: Texture2D
@export_range(0.05, 1.0) var _pose_duration: float = 0.2

var _has_cargo_item: bool = false
var _is_sorting: bool = false

@export var _body: Sprite2D
@export var _cargo_item_view: CargoItem
@export var _hands: Sprite2D

@export var _timer: Timer


## 正面画像を保存し、手前の手と奥の胴体の間に果実表示を作成する。
func _ready() -> void:
	_front_texture = _body.texture
	_cargo_item_view.visible = false
	_timer.wait_time = _pose_duration
	_timer.timeout.connect(reset_pose)


## 手元に表示する果実を更新する。nullなら非表示にする。[br]
## [param fruit]: 到着した果実。[br]
## [param show_weight]: 重量の数値を表示するか。
func set_fruit(fruit: CargoItemData, show_weight: bool) -> void:
	_has_cargo_item = fruit != null
	if _has_cargo_item:
		# キャラクターの表示倍率にかかわらず、コンベア上と同じ果実サイズを保つ。
		_cargo_item_view.global_scale = Vector2.ONE
		_cargo_item_view.construct(fruit.weight, show_weight)
	_cargo_item_view.visible = _has_cargo_item and not _is_sorting


## 指定方向の投入画像を表示する。未設定なら反対側を反転して補う。[br]
## [param to_left]: 左の箱へ投入するか。
func show_sort_pose(to_left: bool) -> void:
	var texture := _left_pose_texture if to_left else _right_pose_texture
	var fallback := _right_pose_texture if to_left else _left_pose_texture
	if texture == null and fallback == null:
		reset_pose()
		return
	_is_sorting = true
	_body.texture = texture if texture != null else fallback
	_body.flip_h = texture == null
	_hands.visible = false
	_cargo_item_view.visible = false
	_timer.start()


## 投入ポーズを解除し、正面画像と手元の表示へ戻す。
func reset_pose() -> void:
	_timer.stop()
	_is_sorting = false
	_body.texture = _front_texture
	_body.flip_h = false
	_hands.visible = true
	_cargo_item_view.visible = _has_cargo_item
