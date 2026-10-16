class_name BoxState
extends RefCounted
## 箱の累積重量を管理する。

var weight: int = 0


## 果実の重量を加算する。[br]
## [param fruit]: 投入する果実。
func add(fruit: FruitData) -> void:
	weight += fruit.weight


## 箱を空にする。
func clear() -> void:
	weight = 0
