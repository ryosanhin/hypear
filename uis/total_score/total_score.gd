extends Label
## 合計得点を表示する。


## 合計得点をラベルに反映する。[br]
## [param total_score]: 現在の合計得点。
func set_score(total_score: int) -> void:
	text = "%d点" % total_score
