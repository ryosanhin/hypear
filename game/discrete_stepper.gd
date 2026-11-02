class_name DiscreteStepper
extends RefCounted
## 流れごとの経過時間を蓄積し、固定間隔の更新回数を取り出す。

## 時間の境界判定で許容する、更新間隔に対する誤差の割合。
const TIME_TOLERANCE_RATIO: float = 1.0e-10

var tick_interval: float
var _elapsed: float = 0.0


## 更新間隔を設定する。[br]
## [param init_tick_interval]: 有限かつ正のゲーム内秒数。
func _init(init_tick_interval: float) -> void:
	assert(is_finite(init_tick_interval) and init_tick_interval > 0.0)
	tick_interval = init_tick_interval


## 経過時間を加え、実行できる更新回数を返す。端数は次回へ持ち越す。[br]
## [param delta]: 倍率適用済みのゲーム内経過秒数。
func take_steps(delta: float) -> int:
	if delta <= 0.0 or not is_finite(delta):
		return 0
	_elapsed += delta
	# 境界での浮動小数点の丸め誤差だけを吸収する。
	var tolerance := tick_interval * TIME_TOLERANCE_RATIO
	var count := int(floor((_elapsed + tolerance) / tick_interval))
	_elapsed = maxf(0.0, _elapsed - count * tick_interval)
	return count


## 開始前の状態へ戻し、前の流れの端数を破棄する。
func reset() -> void:
	_elapsed = 0.0
