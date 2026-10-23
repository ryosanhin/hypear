class_name FruitBox
extends Node2D
## 果実の重量保持と箱の表示を担当する。

var _state := BoxState.new()
var _target: int = 20
var weight: int:
	get:
		return _state.weight

@onready var _label: Label = $Weight


## 単独配置時も初期重量を表示する。
func _ready() -> void:
	_refresh()


## 目標重量を設定して表示を更新する。[br]
## [param target]: 出荷時の目標重量。
func configure(target: int) -> void:
	_target = target
	_refresh()


## 果実を受け入れて重量と表示を更新する。[br]
## [param fruit]: 投入する果実。
func add_fruit(fruit: FruitData) -> void:
	_state.add(fruit)
	_refresh()


## 箱を空にして表示を更新する。
func clear() -> void:
	_state.clear()
	_refresh()


## 現在重量と目標重量を表示する。
func _refresh() -> void:
	_label.text = "%d / %d" % [weight, _target]
	_label.modulate = Color("ffb09b") if weight > _target else Color.WHITE
