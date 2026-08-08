# Manages everything for this specific setting

extends Node2D

const ROOM_SIZE = 3

@onready var ground_map = $Ground
@onready var overlay = $ShadowOverlay
@onready var flags = $Flags

@onready var ui = $UI/MarginContainer

var player_start_pos = Vector2(0,0)

# Generates map
func generate_map() -> Dictionary:
	var map := {}
	# First generates all tile locations
	var row_total = randi_range(30,35)
	var row_count = 0
	var last_row_info = {"offset": 0, "length": 17}
	
	while row_count <= row_total:
		var row_length = clampi(randi_range(-1, 1) + last_row_info.length, 15, 20)
		var row_offset = randi_range(-2,2) + last_row_info.offset
		for i in range(row_length):
			map[Vector2(i + row_offset, -1 * row_count)] = "true"
			
		# Set player spawn on first row
		if row_count == 0:
			player_start_pos = Vector2(round(row_length * 0.5) + randi_range(-1,1), 0)
			
		row_count += 1
		last_row_info.offset = row_offset
		last_row_info.length = row_length
		
	return map

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Generate ground map
	var map = generate_map()
	for tile in map:
		# Makes big tiles
		for row in range(ROOM_SIZE):
			for column in range(ROOM_SIZE):
				ground_map.set_cell(tile * ROOM_SIZE + Vector2(row, column)
				, 0, Vector2i(0,0))
	
	# Add surrounding empty tiles to fix terrain
	var used_cells := []
	for cell in ground_map.get_used_cells():
		for direction in [
			Vector2i(0,1),
			Vector2i(1,1),
			Vector2i(1,0),
			Vector2i(1,-1),
			Vector2i(0,-1),
			Vector2i(-1,-1),
			Vector2i(-1,0),
			Vector2i(-1,1)
		]:
			if not used_cells.has(cell + direction):
				used_cells.append(cell + direction)
	
	ground_map.set_cells_terrain_connect(used_cells, 0, 0)
	
	# Blackout tiles
	for ground_cell in ground_map.get_used_cells():
		overlay.set_cell(ground_cell, 1, Vector2i(1,1))
		
	# Place player and start stamina
	$Player.position = ground_map.map_to_local(player_start_pos * Vector2(3,0)) 
	$PlayerStamina.start()
		
# Player-specific stuff
var player_stamina = 10
var player_flags = {
	"blue": 5,
	"green": 2,
	"red": 2,
}

func _physics_process(_delta: float) -> void:
	# Process overlay for revealing paths
	var player_current_cell = overlay.local_to_map(overlay.to_local($Player.position))
	for direction in [
			Vector2i(0,0), # bonus middle one!
			Vector2i(0,1),
			Vector2i(1,1),
			Vector2i(1,0),
			Vector2i(1,-1),
			Vector2i(0,-1),
			Vector2i(-1,-1),
			Vector2i(-1,0),
			Vector2i(-1,1)
		]:
			overlay.set_cell(
				player_current_cell + direction,
				-1
				)
		
	# tile ONLY THOSE for performance maybe
	# overlay.set_cells_terrain_connect(overlay.get_used_cells(), 0, 0)
	
	# place flags if necessary
	if Input.is_action_just_pressed("PLACE"):
		var location = flags.local_to_map(flags.to_local($Player.position))
		if flags.get_cell_source_id(location) == -1:
			flags.set_cell(location, 0, Vector2(0,0))

	# drain player stamina
	if $Player.velocity.length() > 0 and $PlayerStamina.is_stopped():
		player_stamina -= 1
		# update label
		ui.get_node("DayCount").text = str(player_stamina) + " days left"
		$PlayerStamina.start()
		if player_stamina <= 0:
			# Player has ran out of stamina, pull screen transition and 
			respawn()
			
func respawn():
	# Start screen transition
	$ScreenTransition.visible = true
	var transition_on = create_tween()
	transition_on.tween_property($ScreenTransition/ColorRect, "color", Color(0,0,0,1), 0.2)
	await transition_on.finished
	
	# reset player pos
	$Player.position = ground_map.map_to_local(player_start_pos * Vector2(3,0)) 
	$PlayerStamina.start()
	# reset stamina
	player_stamina = 10
	ui.get_node("DayCount").text = str(player_stamina) + " days left"
	# reset blackout
	for ground_cell in ground_map.get_used_cells():
		overlay.set_cell(ground_cell, 1, Vector2i(1,1))
	
	# Screen transition off
	var transition_off = create_tween()
	transition_off.tween_property($ScreenTransition/ColorRect, "color", Color(0,0,0,0), 0.2)
	await transition_off.finished
	$ScreenTransition.visible = false
	
# All tiles are blacked out at start and you see them once you walk into them
# Maybe 3x3s that are autotiled???
# Every one has something placed in it
# OKAY SAME SHIT BUT YOU LEAVE CAMPFIRES AND SMOKE SIGNALS AND GIANT ASS FLAGS INSTEAD?????
# Thing on bottom where you can tap in, focus, write things that are saved for the next run
