class_name SortingCharacter
extends Node2D
## 手元の果実表示と左右への投入ポーズを担当する。

const FRUIT_SCENE := preload("res://views/fruit_view.tscn")

@export var left_pose_texture: Texture2D
@export var right_pose_texture: Texture2D
@export_range(0.05, 1.0) var pose_duration: float = 0.2

var _front_texture: Texture2D
var _pose_remaining: float = 0.0
var _fruit_view: Node2D
var _has_fruit: bool = false

@onready var _body: Sprite2D = $Body
@onready var _hold_point: Sprite2D = $Body/HoldPoint
@onready var _hands: Sprite2D = $Body/Hands


## 正面画像を保存し、手前の手と奥の胴体の間に果実表示を作成する。
func _ready() -> void:
	_front_texture = _body.texture
	_fruit_view = FRUIT_SCENE.instantiate() as Node2D
	_hold_point.add_child(_fruit_view)
	_fruit_view.visible = false


## 投入ポーズの表示時間を進め、終了時に正面へ戻す。[br]
## [param delta]: 前フレームからの経過秒数。
func _process(delta: float) -> void:
	if _pose_remaining <= 0.0:
		return
	_pose_remaining = maxf(0.0, _pose_remaining - delta)
	if _pose_remaining == 0.0:
		reset_pose()


## 手元に表示する果実を更新する。nullなら非表示にする。[br]
## [param fruit]: 到着した果実。[br]
## [param show_weight]: 重量の数値を表示するか。
func set_fruit(fruit: FruitData, show_weight: bool) -> void:
	_has_fruit = fruit != null
	if _has_fruit:
		# キャラクターの表示倍率にかかわらず、コンベア上と同じ果実サイズを保つ。
		_fruit_view.global_scale = Vector2.ONE
		_fruit_view.configure(fruit.weight, show_weight)
	_fruit_view.visible = _has_fruit and _pose_remaining <= 0.0


## 指定方向の投入画像を表示する。未設定なら反対側を反転して補う。[br]
## [param to_left]: 左の箱へ投入するか。
func show_sort_pose(to_left: bool) -> void:
	var texture := left_pose_texture if to_left else right_pose_texture
	var fallback := right_pose_texture if to_left else left_pose_texture
	if texture == null and fallback == null:
		reset_pose()
		return
	_body.texture = texture if texture != null else fallback
	_body.flip_h = texture == null
	_hands.visible = false
	_fruit_view.visible = false
	_pose_remaining = pose_duration


## 投入ポーズを解除し、正面画像と手元の表示へ戻す。
func reset_pose() -> void:
	_pose_remaining = 0.0
	_body.texture = _front_texture
	_body.flip_h = false
	_hands.visible = true
	_fruit_view.visible = _has_fruit
