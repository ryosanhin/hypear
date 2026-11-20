class_name ScoreCalculator
extends RefCounted


## 一箱の出荷得点を計算する。[br]
## [param shipped_weight]: 出荷重量。[br]
## [param target_weight]: 目標重量。
static func calculate(shipped_weight: int, target_weight: int) -> int:
	if target_weight <= 0 or shipped_weight <= 0:
		return 0

	var rate := float(shipped_weight) / float(target_weight)

	if rate < 0.5:
		return 0

	if rate < 0.8:
		return roundi(100.0 * (rate - 0.5))

	if rate <= 1.0:
		var t := (rate - 0.8) / 0.2
		return roundi(30.0 + 20.0 * t + 50.0 * t * t)

	var remaining := maxf(0.0, 1.0 - (rate - 1.0) / 0.15)
	return roundi(100.0 * pow(remaining, 4.0))


## 左右の得点と重量差から均等ボーナスを計算する。[br]
## [param left_points]: 左箱の得点。[br]
## [param right_points]: 右箱の得点。[br]
## [param left_weight]: 左箱の重量。[br]
## [param right_weight]: 右箱の重量。[br]
## [param target_weight]: 目標重量。
static func calculate_balance_bonus(
	left_points: int,
	right_points: int,
	left_weight: int,
	right_weight: int,
	target_weight: int,
) -> int:
	if target_weight <= 0:
		return 0

	var difference_rate := float(absi(left_weight - right_weight)) / float(target_weight)
	var closeness := maxf(0.0, 1.0 - difference_rate / 0.3)
	var lower_points := mini(left_points, right_points)

	return roundi(0.6 * lower_points * closeness * closeness)
