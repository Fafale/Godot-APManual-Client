extends Node

enum types {
	UNDEFINED = -1,
	BASE64JSON = 0,
	ZIPPEDNOCATEGORY = 1,
	ZIPPEDFULL = 2
}

signal finished_receiving_data

@onready var game_name: String = ""
@onready var json_items: Dictionary = {}
@onready var json_locations: Dictionary = {}
@onready var json_categories: Dictionary = {}
@onready var json_regions: Dictionary = {}


@onready var filetype: types = types.UNDEFINED
@onready var filepath: String = ""

@onready var categories: Dictionary[String, ManualCategory] = {}

@onready var item_categories: Dictionary[String, bool] = {}
@onready var location_categories: Dictionary[String, bool] = {}

# Received items
@onready var inventory: Dictionary[String, ManualItem] = {}

# Available items/locations
@onready var items: Dictionary[String, ManualItem] = {}
@onready var items_id_to_string: Dictionary[int, String] = {}
@onready var locations: Dictionary[String, ManualLocation] = {}

func _ready() -> void:
	Archipelago.connect("connected", read_apmanual_info)

# Reads the JSON and saves on dictionaries, and sets the game name.
# Also returns the game name for it to appear on the connection box
func set_basic_manual_info() -> String:
	clear_jsons()
	
	if filetype == types.BASE64JSON:
		var file = FileAccess.open(filepath, FileAccess.READ)
		var json: Dictionary = JSON.parse_string(Marshalls.base64_to_utf8(file.get_line()))
		
		game_name = json["game"]
		json_items = json["items"]
		json_locations = json["locations"]
		json_regions = json.get("regions", {})
		json_categories = json.get("categories", {})
		
		
		file.close()
	else:
		var reader: ZIPReader = ZIPReader.new()
		reader.open(filepath)
		
		var buffer = reader.read_file("archipelago.json")
		var json_ap: Dictionary = JSON.parse_string(buffer.get_string_from_utf8())
		game_name = json_ap["game"]
		
		buffer = reader.read_file("items.json")
		json_items = JSON.parse_string(buffer.get_string_from_utf8())
		
		buffer = reader.read_file("locations.json")
		json_locations = JSON.parse_string(buffer.get_string_from_utf8())
		
		buffer = reader.read_file("regions.json")
		json_regions = JSON.parse_string(buffer.get_string_from_utf8())
		
		if filetype == types.ZIPPEDFULL:
			buffer = reader.read_file("categories.json")
			json_categories = JSON.parse_string(buffer.get_string_from_utf8())
		
		
		reader.close()
	
	
	Archipelago.update_game_name(game_name)
	return game_name

func read_apmanual_info(conn: ConnectionInfo, _json: Dictionary):
	conn.refresh_items.connect(receive_items)
	
	for item_dict:Dictionary in json_items.values():
		var item_name: String = item_dict["name"]
		var item: ManualItem = create_item(item_name, item_dict["id"])
		items[item_name] = item
		
		var item_id = int(item_dict["id"])
		items_id_to_string[item_id] = item_name
		
		var curr_categories: Array = item_dict.get("category", [])
		for category_name: String in curr_categories:
			var cat: ManualCategory = categories.get(category_name)
			if cat == null:
				cat = create_category(category_name)
				categories[category_name] = cat
			
			cat.items[item_name] = item
			item_categories[category_name] = true
	
	# ver quais items/locations tão no jogo pelos network protocol da vida
	
	for loc_dict:Dictionary in json_locations.values():
		var loc_name: String = loc_dict["name"]
		if (conn.locs_by_name.get(loc_name) != null):
			var loc: ManualLocation = create_location(loc_name, loc_dict["id"])
			locations[loc_name] = loc
			
			var curr_categories: Array = loc_dict.get("category", [])
			for category_name: String in curr_categories:
				if json_categories.get(category_name):
					if (json_categories[category_name].get("hidden") == true):
						continue
				
				var cat: ManualCategory = categories.get(category_name)
				if cat == null:
					cat = create_category(category_name)
					categories[category_name] = cat
				
				cat.locations[loc_name] = loc
				location_categories[category_name] = true
		

# Load/Read received items from server, and save their count at inventory/item variables
func receive_items(received_items: Array[NetworkItem]) -> void:
	# Wait a bit to make sure the dictionaries have been created
	await get_tree().create_timer(1.0).timeout
	
	for net_item:NetworkItem in received_items:
		var item_name = items_id_to_string[net_item.id]
		var item = items[item_name]
		item.count += 1
		
		inventory[item_name] = item
		
	
	finished_receiving_data.emit()

# Clear/Empty the json variables, for when changing .apmanuals before connecting
func clear_jsons() -> void:
	game_name = ""
	json_items = {}
	json_locations = {}
	json_regions = {}
	json_categories = {}

func create_item(item_name: String, id: int) -> ManualItem:
	var item: ManualItem = ManualItem.new()
	item.name = item_name
	item.id = id
	return item

func create_location(loc_name: String, id: int) -> ManualLocation:
	var loc: ManualLocation = ManualLocation.new()
	loc.name = loc_name
	loc.id = id
	return loc

func create_category(n: String) -> ManualCategory:
	var cat: ManualCategory = ManualCategory.new()
	cat.name = n
	return cat
