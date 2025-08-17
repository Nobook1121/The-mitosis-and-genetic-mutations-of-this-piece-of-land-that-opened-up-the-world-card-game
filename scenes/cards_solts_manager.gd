extends Node2D

signal cards_solts_manager_x_center_ready

var screen_size_x
var screen_size_y
var x_center_position

const DEFAULT_READY_ZONE_CARD_Y_POSITION = 700

func _ready() -> void:
	screen_size_x = get_viewport_rect().size.x
	screen_size_y = get_viewport_rect().size.y
	x_center_position = screen_size_x / 2
	
	emit_signal("cards_solts_manager_x_center_ready" , x_center_position)

	
