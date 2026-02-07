extends VBoxContainer

@onready var button: Button = $BtCategory
@onready var label: RichTextLabel = $TextLabel

@onready var category: ManualCategory
@onready var total_count: int = 0

func _on_bt_category_pressed() -> void:
	label.visible = not label.visible

func fill_info(cat: ManualCategory) -> void:
	category = cat
	
	label.clear()
	
	for item_name:String in category.items.keys():
		if (not APManual.inventory.get(item_name) == null):
			var item:ManualItem = APManual.items.get(item_name)
			label.add_text("%s (%d)\n" % [item.name, item.count])
			total_count += item.count
	
	button.text = "%s (%d)" % [category.name, total_count]
