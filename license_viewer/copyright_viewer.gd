extends Node

@export var _input_blocker: Control


## 背景の GUI 入力を受け取る。
func _ready() -> void:
	_input_blocker.grab_focus()
	_input_blocker.gui_input.connect(_on_input_blocker_gui_input)


## 背景で左クリックが完了したときにビューアを破棄する。[br]
## [param event]: 背景の Control が受け取った入力イベント。
func _on_input_blocker_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		queue_free()
