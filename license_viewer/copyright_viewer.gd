extends Node

@export var _input_blocker: Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_input_blocker.grab_focus()
	_input_blocker.pressed.connect(_delete)


func _delete() -> void:
	queue_free()
