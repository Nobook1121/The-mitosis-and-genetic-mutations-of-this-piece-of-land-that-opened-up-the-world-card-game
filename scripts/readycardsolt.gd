extends Node2D


var card_in_slot = false
var x_center
var cards_solts_manager_reference
var new_position
var x_position
var y_position
var card_slot_type = "ready"


#func _ready() -> void:
#	cards_solts_manager_reference = get_parent().get_parent()
#	cards_solts_manager_reference.cards_solts_manager_x_center_ready.connect(_on_cards_solts_manager_x_center_ready)

#func _on_cards_solts_manager_x_center_ready(center_value):
#	x_center = center_value
#	x_position = x_center
#	y_position = cards_solts_manager_reference.DEFAULT_READY_ZONE_CARD_Y_POSITION
#	new_position = Vector2(x_center,y_position)
#	self.position = new_position
