class_name FruitFlow
extends RefCounted
## ゲーム開始を起点とする、果実の供給と搬送の共通周期を管理する。

signal supply_failed

var _settings: DemoSettings
var _conveyor: MainConveyor
var _generator: FruitGenerator
var _stepper: DiscreteStepper
var _supply_elapsed: float = 0.0
var _is_running: bool = false


## 供給設定と搬送先を保持する。[br]
## [param settings]: 供給間隔と更新間隔の設定。[br]
## [param conveyor]: 果実を受け入れ、搬送するコンポーネント。
func _init(settings: DemoSettings, conveyor: MainConveyor) -> void:
	_settings = settings
	_conveyor = conveyor
	_generator = FruitGenerator.new(settings)


## 果実の周期と供給時間をゼロから開始する。
func start() -> void:
	_stepper = DiscreteStepper.new(_settings.flow_tick_interval)
	_supply_elapsed = 0.0
	_is_running = true


## 未処理時間を破棄して供給と搬送を停止する。
func stop() -> void:
	_is_running = false
	if _stepper != null:
		_stepper.reset()


## 固定間隔に達した回数だけ供給と搬送を進める。[br]
## [param delta]: 倍率適用済みのゲーム内経過秒数。
func advance(delta: float) -> void:
	if not _is_running:
		return
	for index in _stepper.take_steps(delta):
		if not _is_running:
			break
		_advance_tick(_stepper.interval)


## 果実を一個供給し、入口の詰まりや容量超過なら流れを停止して通知する。
func supply() -> void:
	if _is_running and not _conveyor.add_cargo_item(_generator.generate()):
		stop()
		supply_failed.emit()


## 供給時刻まで搬送してから供給し、更新内の残り時間を搬送に使う。[br]
## [param delta]: 一回分の固定更新秒数。
func _advance_tick(delta: float) -> void:
	while delta > 0.0 and _is_running:
		var until_supply := maxf(0.0, _settings.supply_interval - _supply_elapsed)
		var step := minf(delta, until_supply)
		_conveyor.advance(step)
		_supply_elapsed += step
		delta -= step
		if _supply_elapsed + _settings.supply_interval * 1.0e-10 >= _settings.supply_interval:
			_supply_elapsed = 0.0
			supply()
