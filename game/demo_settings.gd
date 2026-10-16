class_name DemoSettings
extends Resource
## デモの難易度と果実の出現設定。

@export var fruit_weights: Array[int] = [2, 3, 5, 7, 10]
@export var fruit_probabilities: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0]
@export_range(0.1, 60.0) var supply_interval: float = 1.5
@export_range(1, 30) var queue_capacity: int = 10
@export_range(1, 1000) var target_weight: int = 20
@export_range(10.0, 2000.0) var conveyor_speed: float = 360.0
@export var show_weights: bool = true


## 設定が生成と進行に使用できるかを返す。
func is_valid() -> bool:
	if fruit_weights.is_empty() or fruit_weights.size() != fruit_probabilities.size():
		return false
	if supply_interval <= 0.0 or queue_capacity <= 0 or target_weight <= 0:
		return false
	if not is_finite(supply_interval) or not is_finite(conveyor_speed) or conveyor_speed <= 0.0:
		return false
	var total := 0.0
	for index in fruit_weights.size():
		if fruit_weights[index] <= 0:
			return false
		var probability := fruit_probabilities[index]
		if not is_finite(probability) or probability < 0.0:
			return false
		total += probability
	return is_finite(total) and total > 0.0
