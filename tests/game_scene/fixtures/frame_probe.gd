extends Node
## 実際のエンジン更新でセッションと同じdeltaを記録する。

signal finished
var session: GameSession
var elapsed: float = 0.0
var _frames: int = 0


## 同じフレームのセッション更新後に経過時間を記録する。[br]
## [param delta]: Engine.time_scale適用済みのゲーム内秒数。
func _process(delta: float) -> void:
	elapsed += delta
	_frames += 1
	if _frames == 30:
		session.set_process(false)
		set_process(false)
		finished.emit()
