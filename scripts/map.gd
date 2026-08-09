# Manages everything for this specific setting

extends Node2D

const ROOM_SIZE = 3

@onready var ground_map = $Ground
@onready var overlay = $ShadowOverlay
@onready var flags = $Flags

@onready var ui = $UI/MarginContainer

var player_start_pos = Vector2(0,0)

var row_total = 0

# Generates map
func generate_map() -> Dictionary:
	var map := {}
	# First generates all tile locations
	row_total = randi_range(25,30)
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

# Generate the persistent floor
func _ready() -> void:
	# Generate ground map
	var map = generate_map()
	for tile in map:
		# Makes big tiles
		for row in range(ROOM_SIZE):
			for column in range(ROOM_SIZE):
				ground_map.set_cell(tile * ROOM_SIZE + Vector2(row, column)
				, 0, Vector2i(0,0))
				$Grass.set_cell(tile * ROOM_SIZE + Vector2(row, column),
				1, Vector2i(randi_range(0,2), 0))
	
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
				# add to grass layer as well
				$Grass.set_cell(cell + direction,
				1, Vector2i(randi_range(0,2), 0))
	
	ground_map.set_cells_terrain_connect(used_cells, 0, 0)
	
	# Create home tiles
	ground_map.set_cell(player_start_pos * Vector2(3,0), 0, Vector2i(6,0))
	for direction in [
		Vector2.UP,
		Vector2.RIGHT,
		Vector2.DOWN,
		Vector2.LEFT,
		Vector2(1,1),
		Vector2(-1,1),
		Vector2(-1,-1),
		Vector2(1,-1)
	]:
		if randf() <= 0.6:
			ground_map.set_cell(player_start_pos * Vector2(3,0) + direction, 0, 
			Vector2i(randi_range(6,7),randi_range(0,1)))
	
	# Blackout tiles
	for ground_cell in ground_map.get_used_cells():
		overlay.set_cell(ground_cell, 1, Vector2i(round(randf()) * 3,0)) # 50/50 between 0 and 3
		
	# Place player and start stamina
	$Player.global_position = ground_map.to_global(
		ground_map.map_to_local(player_start_pos * Vector2(3,0)) 
		)
	$PlayerStamina.start()
	
	# Random player color
	$Player.modulate = [Color.RED, Color.ORANGE, Color.YELLOW, Color.GREEN, Color.BLUE, Color.PURPLE].pick_random()
		
	# Fade instructions out
	var tuto_tween = ui.get_node("TutorialLabel").create_tween()
	tuto_tween.tween_property(ui.get_node("TutorialLabel"), "modulate", Color(0,0,0,0), 8)
	
# Player-specific stuff
var player_stamina = 14
var player_distance_pb = 0
var player_flags = {
	"blue": 8,
	"green": 5,
	"red": 5,
}

var current_flag = "blue"
const all_flags = ["blue", "red", "green"]

# Main thing, ish.
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
		if player_flags[current_flag] > 0:
			# Offsets for the flag atlas are prob gonna be hardcoded
			match current_flag:
				"blue":
					flags.set_cell(location, 0, Vector2(0,0))
				"red":
					flags.set_cell(location, 0, Vector2(1,0))
				"green":
					flags.set_cell(location, 0, Vector2(2,0))
					
			# Remove flag
			player_flags[current_flag] -= 1
			# Update display to match
			ui.get_node("Flags/FlagCount").text = str(player_flags[current_flag]) + " flags"
	
	# check if player rotated flags
	if Input.is_action_just_pressed("ROTATE"):
		# Swap the string
		# Gets index of current flag from array, adds 1, modulo len flag list, then get from that again
		current_flag = all_flags[(all_flags.find(current_flag) + 1) % len(all_flags)]
		# Swap mini icon
		ui.get_node("Flags/TextureRect").texture.region = Rect2(
			(all_flags.find(current_flag) * 16) % 48, 0, 16, 16
		)
		# Change remaining flag count to match
		ui.get_node("Flags/FlagCount").text = str(player_flags[current_flag]) + " flags"
	
	# drain player stamina
	if $Player.velocity.length() > 0 and $PlayerStamina.is_stopped():
		player_stamina -= 1
		# update label
		ui.get_node("DayCount").text = str(player_stamina) + " days left"
		$PlayerStamina.start()
		if player_stamina <= 0:
			# Player has ran out of stamina, retreat to base and restart
			respawn()
			
	# Small chance to make trail
	if randf() <= 0.02 and $Player.velocity.length() > 0:
		var player_location = ground_map.local_to_map(ground_map.to_local($Player.position))
		$Trail.set_cell(
			player_location,
			0, Vector2i(min($Trail.get_cell_atlas_coords(player_location).x + 1, 3), 0)
			)
			
	# Update player elevation
	var player_distance = ground_map.local_to_map(ground_map.to_local($Player.position)).y * -1
	ui.get_node("VBoxContainer/DistanceLabel").text = "Current Distance: " + str(
		player_distance
		) + "u"
		
	if player_distance > player_distance_pb:
		player_distance_pb = player_distance
		ui.get_node("VBoxContainer/DistancePB").text = "Best Distance: " + str(player_distance_pb) + "u"
			
	# Show resupplies label and fill them
	ui.get_node("ConsumeLabel").visible = $Player.is_resupply_available
	
	if $Player.is_resupply_available and Input.is_action_just_pressed("CONSUME"):
		player_stamina = min(player_stamina + 4, 14) # Max 14
		ground_map.set_cell(ground_map.local_to_map(ground_map.to_local($Player.position)), 0, Vector2i(1,1))
		# update UI to match
		ui.get_node("DayCount").text = str(player_stamina) + " days left"
		
	# Check if you won (very crappy)
	if ground_map.local_to_map(ground_map.to_local($Player.position)).y <= -3 * row_total:
		var victory_tween = create_tween()
		$VictoryScreen.visible = true
		victory_tween.tween_property($VictoryScreen/ColorRect, "color", Color(1,1,1,1), 1)
		victory_tween.tween_property($VictoryScreen/VBoxContainer/Label.label_settings, 
		"font_color", Color(0,0,0,1), 1)
		victory_tween.tween_property($VictoryScreen/TextureRect, "modulate:a", 100, 0.2)
		victory_tween.tween_property($VictoryScreen/ColorRect, "modulate:a", 0.7, 1)
		victory_tween.parallel().tween_property($VictoryScreen/VBoxContainer/Replay, "modulate:a", 1, 1)
		# Connect button to restarting scene
		$VictoryScreen/VBoxContainer/Replay.connect("pressed", func () :
			for child in get_children():
				child.queue_free()
			get_tree().call_deferred("change_scene_to_file", "res://scenes/map.tscn")
		)
			
func respawn():
	# Start screen transition
	$ScreenTransition.visible = true
	var transition_on = create_tween()
	transition_on.tween_property($ScreenTransition/ColorRect, "color", Color(0,0,0,1), 0.4)
	await transition_on.finished
	
	# reset player pos
	$Player.global_position = ground_map.to_global(
		ground_map.map_to_local(player_start_pos * Vector2(3,0)) 
		)
	$PlayerStamina.start()
	$Player.modulate = [Color.RED, Color.ORANGE, Color.YELLOW, Color.GREEN, Color.BLUE, Color.PURPLE].pick_random()
	# reset stamina
	player_stamina = 14
	# reset distance
	player_distance_pb = 0
	ui.get_node("DayCount").text = str(player_stamina) + " days left"
	# reset flags 
	player_flags = {
		"blue": 8,
		"green": 5,
		"red": 5,
	}
	# Update display anyway
	ui.get_node("Flags/FlagCount").text = str(player_flags[current_flag]) + " flags"
	# reset blackout
	for ground_cell in ground_map.get_used_cells():
		overlay.set_cell(ground_cell, 1, Vector2i(round(randf()) * 3,0))
	
	# Screen transition off
	var transition_off = create_tween()
	transition_off.tween_property($ScreenTransition/ColorRect, "color", Color(0,0,0,0), 0.4)
	await transition_off.finished
	$ScreenTransition.visible = false
	
# All tiles are blacked out at start and you see them once you walk into them
# Maybe 3x3s that are autotiled???
# Every one has something placed in it
# OKAY SAME SHIT BUT YOU LEAVE CAMPFIRES AND SMOKE SIGNALS AND GIANT ASS FLAGS INSTEAD?????
# Thing on bottom where you can tap in, focus, write things that are saved for the next run
