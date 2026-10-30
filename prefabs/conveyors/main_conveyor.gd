class_name MainConveyor
extends Node2D
## 果実の受け入れ、経路上の搬送、待機と取り出しを管理する。

## 輸送物が終点に到達したことを知らせるシグナル。[br]
## [param cargo_item]: 終点に到達した輸送物データ。
signal reached_terminal(cargo_item: CargoItemData)

const CARGO_ITEM_SCENE := preload("res://prefabs/cargo_item/cargo_item.tscn")

@export_range(46.0, 100.0) var fruit_spacing: float = 56.0

var capacity: int = 10
var speed: float = 360.0
var _show_weights: bool = true
var _cargo_items: Array[CargoItemData] = []
var _followers: Array[PathFollow2D] = []

@onready var _path: Path2D = $FruitPath


## 搬送条件と初期表示を設定する。[br]
## [param settings]: 容量、搬送速度と重量表示の設定。
func configure(settings: DemoSettings) -> void:
	capacity = settings.queue_capacity
	speed = settings.conveyor_speed
	set_show_weights(settings.show_weights)


## 果実を入口に追加する。容量超過または入口が塞がっていればfalseを返す。[br]
## [param cargo_item]: 供給する果実。
func add_cargo_item(cargo_item: CargoItemData) -> bool:
	if _cargo_items.size() >= capacity:
		return false
	if not _followers.is_empty() and _followers.back().progress < fruit_spacing:
		return false
	var follower := PathFollow2D.new()
	follower.loop = false
	follower.rotates = false
	_path.add_child(follower)
	var view := CARGO_ITEM_SCENE.instantiate() as CargoItem
	follower.add_child(view)
	view.construct(cargo_item.weight, _show_weights)
	_cargo_items.append(cargo_item)
	_followers.append(follower)
	return true


## 先頭から順に搬送し、新しく終端へ到着した輸送物を通知する。[br]
## [param delta]: 前回の更新からの経過秒数。
func advance(delta: float) -> void:
	if delta <= 0.0 or not is_finite(delta):
		return

	var ready_before := peek_ready_cargo_item()

	var limit := _path.curve.get_baked_length()
	for follower in _followers:
		follower.progress = minf(follower.progress + speed * delta, limit)
		limit = maxf(0.0, follower.progress - fruit_spacing)

	var ready_after := peek_ready_cargo_item()
	if ready_after != null and ready_after != ready_before:
		reached_terminal.emit(ready_after)


## 終端に到着した先頭果実を返す。移動中または空ならnullを返す。
func peek_ready_cargo_item() -> CargoItemData:
	if _followers.is_empty():
		return null
	if not is_equal_approx(_followers[0].progress, _path.curve.get_baked_length()):
		return null
	return _cargo_items[0]


## 到着済みの先頭果実を取り出し、その表示を除去する。
func take_ready_cargo_item() -> CargoItemData:
	var fruit := peek_ready_cargo_item()
	if fruit == null:
		return null
	_cargo_items.pop_front()
	var follower: PathFollow2D = _followers.pop_front()
	_path.remove_child(follower)
	follower.queue_free()
	return fruit


## 搬送中を含む未処理果実を生成順のコピーで返す。
func get_queue() -> Array[CargoItemData]:
	return _cargo_items.duplicate()


## 全果実の重量表示を切り替える。[br]
## [param enabled]: 数値を表示するか。
func set_show_weights(enabled: bool) -> void:
	_show_weights = enabled
	for index in _followers.size():
		var view := _followers[index].get_child(0) as CargoItem
		view.construct(_cargo_items[index].weight, enabled)


## 全果実と表示を取り除き、空の搬送状態へ戻す。
func clear() -> void:
	for follower in _followers:
		_path.remove_child(follower)
		follower.queue_free()
	_followers.clear()
	_cargo_items.clear()


## 到着済みの果実表示を切り替え、搬送中の果実は表示する。[br]
## [param enabled]: 到着済みの果実もコンベア上に表示するか。
func set_ready_fruit_visible(enabled: bool) -> void:
	var ready := peek_ready_cargo_item()
	for index in _followers.size():
		_followers[index].visible = enabled or _cargo_items[index] != ready
