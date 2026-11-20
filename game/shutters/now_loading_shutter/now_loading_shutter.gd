extends "res://utils/transition_management/transition_effect.gd"

const Shutter := preload("res://game/shutters/shutter.gd")

@export var _shutter: Shutter


## 再生に使用するシャッターが演出シーンの配下にあるかを返す。
func is_configured() -> bool:
	return _shutter != null and is_ancestor_of(_shutter)


## ロード用シャッターを閉め、画面を覆った状態にする。
func cover_async() -> void:
	await _shutter.close_async()


## ロード用シャッターを開き、差し替え後の画面を表示する。
func reveal_async() -> void:
	await _shutter.open_async()
