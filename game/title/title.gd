extends Node

signal start_requested

@export var _start_button: Button
@export var _copyright_button: Button
@export var _copyright_viewer: PackedScene
@export var _cargo_item: PackedScene
@export var _path2d: Path2D
@export var _spawn_timer: Timer

var _entry_point: Vector2
var _end_point: Vector2
var _settings: DemoSettings = preload("res://game/stage/demo_settings.tres")
var _fruit_generator: FruitGenerator


## スタートボタンの入力を開始要求として通知する。
func _ready() -> void:
	_start_button.pressed.connect(start_requested.emit)
	_copyright_button.pressed.connect(_show_copyrights)
	_entry_point = _path2d.curve.get_point_position(0)
	_end_point = _path2d.curve.get_point_position(1)
	_fruit_generator = FruitGenerator.new(_settings)
	_cargo_item_effect()


## スタートボタンを押せるかどうかを切り替える。[br]
## [param is_enabled]: スタートを受け付ける場合はtrue。
func set_start_enabled(is_enabled: bool) -> void:
	_start_button.disabled = not is_enabled


func _show_copyrights() -> void:
	var node := _copyright_viewer.instantiate()
	self.add_child(node)


func _cargo_item_effect() -> void:
	while true:
		_add_cargo_item()

		var interval := randi_range(1, 5)
		_spawn_timer.start(float(interval))
		await _spawn_timer.timeout


func _add_cargo_item() -> void:
	var cargo_data := _fruit_generator.generate()
	var cargo_item := _cargo_item.instantiate() as CargoItem
	cargo_item.construct(cargo_data.weight, false)

	_path2d.add_child(cargo_item)

	var tween := create_tween()
	const DURATION := 10.0
	cargo_item.position = _entry_point
	tween.tween_property(cargo_item, "position", _end_point, DURATION)
	tween.finished.connect(cargo_item.queue_free)
