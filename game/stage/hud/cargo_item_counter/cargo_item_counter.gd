class_name CargoItemCounter
extends PanelContainer
## 未処理の果実数とコンベアの容量を表示する。

@export var _label: Label


## 未処理の果実数とコンベアの容量を表示に反映する。[br]
## [param count]: 搬送中と仕分け待ちの果実数。[br]
## [param capacity]: コンベアの容量。
func set_count(count: int, capacity: int) -> void:
	_label.text = "%d/%d" % [count, capacity]
