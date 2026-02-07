extends MarginContainer

@onready var preload_category_item = preload("res://ap_manual/UI/Items/UI_CategoryItem.tscn")

@onready var parent_items = $Tabs/ItemsScroll/Items

func _ready() -> void:
	APManual.finished_receiving_data.connect(create_categories)

func create_categories() -> void:
	var categories_names = []
	for cat_name in APManual.categories.keys():
		categories_names.append(cat_name)
	categories_names.sort()
	
	for category_name in categories_names:
		var category = APManual.categories[category_name]
		
		var ui_cat_inst = preload_category_item.instantiate()
		parent_items.add_child(ui_cat_inst)
		
		ui_cat_inst.fill_info(category)
