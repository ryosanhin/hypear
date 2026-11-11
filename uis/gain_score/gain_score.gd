class_name GainScore
extends Node2D
## 箱の得点を表示し、浮かび上がって消える。

const RISE_DISTANCE := 40.0
const DURATION := 0.7
const FADE_DELAY := 0.2

@export var _label: Label


## 得点を表示し、演出終了時に自身を解放する。[br]
## [param points]: 箱の得点。
func play(points: int) -> void:
	_label.text = "+%d" % points
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - RISE_DISTANCE, DURATION)
	tween.tween_property(self, "modulate:a", 0.0, DURATION - FADE_DELAY).set_delay(FADE_DELAY)
	tween.chain().tween_callback(queue_free)
