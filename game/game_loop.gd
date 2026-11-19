extends Node
## タイトルとステージを切り替え、ステージの終了結果を表示する。

const Title := preload("res://scenes/title.gd")
const ResultShutter := preload("res://prefabs/shutters/result_shutter.gd")

const TITLE_SCENE := "res://scenes/title.tscn"
const STAGE_SCENE := "res://scenes/stages/stage.tscn"
const LOADING_SHUTTER := "res://prefabs/shutters/now_loading_shutter/now_loading_shutter.tscn"

@export var _scene_controller: SceneController
@export var _main_scene_parent: Node


## 起動時に表示されるタイトルの開始要求を受け取る。
func _ready() -> void:
	_connect_title()


## 現在のタイトルを操作できるようにし、開始要求を接続する。
func _connect_title() -> void:
	var title := _main_scene_parent.get_child(0) as Title
	title.start_requested.connect(_on_start_requested.bind(title))
	title.set_start_enabled(true)


## シャッターでステージに切り替え、画面が開いてからゲームを開始する。[br]
## [param title]: 開始を要求したタイトル画面。
func _on_start_requested(title: Title) -> void:
	if _scene_controller.is_changing:
		return
	title.set_start_enabled(false)
	var change_result := await _scene_controller.change_main_scene_async(
			STAGE_SCENE,
			LOADING_SHUTTER,
	)
	if change_result != SceneController.ChangeResult.SUCCESS:
		title.set_start_enabled(true)
		push_error(
				"ステージへの切り替えに失敗しました: %s"
				% SceneController.ChangeResult.keys()[change_result],
		)
		return

	var stage := _main_scene_parent.get_child(0) as GameSession
	stage.game_finished.connect(_on_game_finished.bind(stage))
	stage.start_game()


## 確定した結果を対応するシャッターに表示し、タイトルへの復帰要求を接続する。[br]
## [param result]: クリアまたはゲームオーバーの状態。[br]
## [param final_score]: 終了時の累計得点。[br]
## [param elapsed_seconds]: 開始から終了までのプレイ秒数。[br]
## [param stage]: 終了を通知したステージ。
func _on_game_finished(
		result: GameSession.State,
		final_score: int,
		elapsed_seconds: float,
		stage: GameSession,
) -> void:
	var shutter: ResultShutter
	var result_text: String
	if result == GameSession.State.CLEARED:
		shutter = stage.game_clear_shutter
		result_text = "%.2f秒" % elapsed_seconds
	else:
		shutter = stage.game_over_shutter
		result_text = "%d点" % final_score
	shutter.return_requested.connect(_on_return_requested.bind(shutter))
	await shutter.show_result_async(result_text)


## 結果画面を覆ってタイトルに戻り、失敗した場合は結果画面で操作を再開する。[br]
## [param shutter]: タイトルへの復帰を要求した結果シャッター。
func _on_return_requested(shutter: ResultShutter) -> void:
	if _scene_controller.is_changing:
		return
	shutter.set_return_enabled(false)
	var change_result := await _scene_controller.change_main_scene_async(
			TITLE_SCENE,
			LOADING_SHUTTER,
	)
	if change_result != SceneController.ChangeResult.SUCCESS:
		shutter.set_return_enabled(true)
		push_error(
				"タイトルへの切り替えに失敗しました: %s"
				% SceneController.ChangeResult.keys()[change_result],
		)
		return
	_connect_title()
