class_name ScoreCalculator
extends RefCounted
## 指定重量との差を評価する暫定スコア計算。


## 一箱の得点を返す。空箱は0点、超過と不足は同じ差として評価する。[br]
## [param weight]: 箱の現在重量。[br]
## [param target]: 目標重量。
static func calculate(weight: int, target: int) -> int:
	if weight == 0:
		return 0
	return maxi(0, 100 - absi(weight - target) * 5)
