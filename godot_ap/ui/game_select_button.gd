extends Button

@onready var dialog: FileDialog = $FileDialog

@onready var filepath: String = ""

enum types {
	UNDEFINED = -1,
	BASE64JSON = 0,
	ZIPPED = 1
}
@onready var filetype: types = types.UNDEFINED

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
	filepath = path
	
	var reader = ZIPReader.new()
	var err = reader.open(filepath)
	
	if err != OK:
		filetype = types.BASE64JSON
	else:
		filetype = types.ZIPPED
		reader.close()
	
	update_game_name()

func update_game_name():
	if filetype == types.BASE64JSON:
		var file = FileAccess.open(filepath, FileAccess.READ)
		var json: Dictionary = JSON.parse_string(Marshalls.base64_to_utf8(file.get_line()))
		
		print(json["game"])
		Archipelago.update_game_name(json["game"])
		
		file.close()
	elif filetype == types.ZIPPED:
		var reader: ZIPReader = ZIPReader.new()
		reader.open(filepath)
		
		var buffer = reader.read_file("archipelago.json")
		var json: Dictionary = JSON.parse_string(buffer.get_string_from_utf8())
		
		print(json["game"])
		Archipelago.update_game_name(json["game"])
		
		reader.close()

func import_file():
	pass
