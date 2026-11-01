extends SceneTree
## 固定更新の境界、長いフレーム、端数と独立した起点を検証する。

const TestHelper := preload("res://tests/supports/test_helper.gd")
var _helper := TestHelper.new(true)


## テストを遅延開始する。
func _initialize() -> void:
	_run.call_deferred()


## 更新回数とリセット後の挙動を検証する。
func _run() -> void:
	_helper.change_test_name("steps_and_remainder")
	var stepper := DiscreteStepper.new(0.1)
	_helper.assert_equal(stepper.take_steps(0.09), 0, "間隔未到達では更新しない")
	_helper.assert_equal(stepper.take_steps(0.01), 1, "境界到達で一回更新")
	_helper.assert_equal(stepper.take_steps(0.35), 3, "長いフレームの全更新を返す")
	_helper.assert_equal(stepper.take_steps(0.049), 0, "端数は次の境界まで保持")
	_helper.assert_equal(stepper.take_steps(0.001), 1, "持ち越した端数で境界へ到達")
	for invalid in [-1.0, 0.0, INF, NAN]:
		_helper.assert_equal(stepper.take_steps(invalid), 0, "無効な経過時間は無視")
	stepper.take_steps(0.09)
	stepper.reset()
	_helper.assert_equal(stepper.take_steps(0.01), 0, "再開始に端数を残さない")
	var other := DiscreteStepper.new(0.1)
	_helper.assert_equal(other.take_steps(0.09), 0, "別の流れはゼロから開始")
	_helper.assert_equal(stepper.take_steps(0.09), 1, "別の流れの開始で周期を変えない")
	_helper.assert_equal(other.take_steps(0.01), 1, "別の流れも自身の境界で進む")
	await _helper.finish(self, "discrete_stepper")
