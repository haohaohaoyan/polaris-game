extends Node2D

const ROOM_SIZE = 3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await Trailinfo.generate_map()
	for tile in Trailinfo.map:
		# Makes big tiles
		for row in range(ROOM_SIZE):
			for column in range(ROOM_SIZE):
				$TileMapLayer.set_cell(tile * ROOM_SIZE + Vector2(row, column)
				, 0, Vector2i(0,0))
				
	$TileMapLayer.set_cells_terrain_connect($TileMapLayer.get_used_cells(), 0, 0)

# All tiles are blacked out at start and you see them once you walk into them
# Maybe 3x3s that are autotiled???
# Every one has something placed in it
# OKAY SAME SHIT BUT YOU LEAVE CAMPFIRES AND SMOKE SIGNALS AND GIANT ASS FLAGS INSTEAD?????
# Thing on bottom where you can tap in, focus, write things that are saved for the next run
