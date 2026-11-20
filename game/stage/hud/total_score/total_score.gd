class_name TotalScore
extends Label
## 合計得点を表示する。

var _tatget_score: float


func configure(tatget_score: float) -> void:
	_tatget_score = tatget_score


## 合計得点をラベルに反映する。[br]
## [param total_score]: 現在の合計得点。
func set_score(total_score: int) -> void:
	text = "%d/%d点" % [total_score, _tatget_score]
