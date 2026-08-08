# Manages everything for this specific setting

extends Node2D

const ROOM_SIZE = 3

@onready var ground_map = $Ground
@onready var overlay = $ShadowOverlay

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Generate ground map
	await Trailinfo.generate_map()
	for tile in Trailinfo.map:
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
		overlay.set_cell(ground_cell, 0, Vector2i(3,2))
		
	$PlayerStamina.start()
		
# Player-specific stuff
var player_stamina = 10

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
				
	# drain player stamina
	if $Player.velocity.length() > 0 and $PlayerStamina.is_stopped():
		player_stamina -= 1
		# update label
		$CanvasLayer/Label.text = str(player_stamina) + " days left"
		$PlayerStamina.start()
		if player_stamina <= 0:
			print("AAGGGHHHHHHHHHHHH")
	
# All tiles are blacked out at start and you see them once you walk into them
# Maybe 3x3s that are autotiled???
# Every one has something placed in it
# OKAY SAME SHIT BUT YOU LEAVE CAMPFIRES AND SMOKE SIGNALS AND GIANT ASS FLAGS INSTEAD?????
# Thing on bottom where you can tap in, focus, write things that are saved for the next run
