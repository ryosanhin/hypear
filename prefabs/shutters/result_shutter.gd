extends "res://prefabs/shutters/shutter.gd"

signal return_requested

@export var _result_label: Label
@export var _return_button: Button


## ボタンの入力をタイトルへの復帰要求として通知する。
func _ready() -> void:
	_return_button.pressed.connect(return_requested.emit)


## 結果を表示してシャッターを閉め、閉じ終えてから復帰操作を有効にする。[br]
## [param result_text]: 単位を含む確定結果の表示文字列。
func show_result_async(result_text: String) -> void:
	_result_label.text = result_text
	show()
	await close_async()
	set_return_enabled(true)


## タイトルへ戻るボタンを押せるかどうかを切り替える。[br]
## [param is_enabled]: タイトルへの復帰を受け付ける場合はtrue。
func set_return_enabled(is_enabled: bool) -> void:
	_return_button.disabled = not is_enabled
