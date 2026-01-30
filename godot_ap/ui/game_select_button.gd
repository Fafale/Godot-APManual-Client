extends Button

@onready var dialog: FileDialog = $FileDialog

func _ready() -> void:
	dialog.connect("canceled", _on_dialog_cancel)
	dialog.connect("file_selected", _on_file_selected)

func _on_pressed() -> void:
	disabled = true
	dialog.show()

func _on_dialog_cancel():
	disabled = false

func _on_file_selected(path: String):
	disabled = false
	APManual.filepath = path
	
	var reader = ZIPReader.new()
	var err = reader.open(path)
	
	if err != OK:
		APManual.filetype = APManual.types.BASE64JSON
	else:
		if (reader.file_exists("categories.json")):
			APManual.filetype = APManual.types.ZIPPEDFULL
		else:
			APManual.filetype = APManual.types.ZIPPEDNOCATEGORY
		
		reader.close()
	
	
	text = APManual.set_basic_manual_info()
