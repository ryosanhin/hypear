extends Node

signal start_requested

@export var _start_button: Button
@export var _copyright_button: Button
@export var _copyright_viewer: PackedScene


## スタートボタンの入力を開始要求として通知する。
func _ready() -> void:
	_start_button.pressed.connect(start_requested.emit)
	_copyright_button.pressed.connect(_show_copyrights)


## スタートボタンを押せるかどうかを切り替える。[br]
## [param is_enabled]: スタートを受け付ける場合はtrue。
func set_start_enabled(is_enabled: bool) -> void:
	_start_button.disabled = not is_enabled


func _show_copyrights() -> void:
	var node := _copyright_viewer.instantiate()
	self.add_child(node)
