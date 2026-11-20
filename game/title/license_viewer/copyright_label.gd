extends Label

@export_file_path("*.txt") var license_path: String

func _ready() -> void:
	var file := FileAccess.open(license_path, FileAccess.READ)
	
	if file == null:
		text = "ファイルを読み込めませんでした。"
		push_error(FileAccess.get_open_error())
		return
	
	text = file.get_as_text()
