extends Node2D
## 箱

signal weight_changed(current_weight: float)

@export var cardboard_sprite: Sprite2D

var _weight: int = 0


## 果実の重量を加算する。[br]
## [param fruit]: 投入する果実。
func add(fruit: FruitData) -> void:
	_weight += fruit.weight
	weight_changed.emit(_weight)


## 箱を空にする。
func clear() -> void:
	_weight = 0
	weight_changed.emit(_weight)
