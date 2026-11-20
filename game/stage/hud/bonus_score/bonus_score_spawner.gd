class_name BonusScoreSpawner
extends Marker2D
## 自身の位置にボーナス得点の演出を出す。

@export var _bonus_score_scene: PackedScene


## 獲得したボーナス得点の演出を開始する。[br]
## [param points]: 今回の出荷で獲得したボーナス得点。
func show_bonus(points: int) -> void:
	var bonus_score := _bonus_score_scene.instantiate() as BonusScore
	add_child(bonus_score)
	bonus_score.play(points)
