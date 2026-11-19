extends Node

signal start_requested

@export var _start_button: Button


## スタートボタンの入力を開始要求として通知する。
func _ready() -> void:
	_start_button.pressed.connect(start_requested.emit)


## スタートボタンを押せるかどうかを切り替える。[br]
## [param is_enabled]: スタートを受け付ける場合はtrue。
func set_start_enabled(is_enabled: bool) -> void:
	_start_button.disabled = not is_enabled
