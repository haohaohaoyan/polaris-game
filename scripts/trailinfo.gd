extends Node

# Map is a 18-20 wide randomly skewed about 30-40 long area
# Every tile can have something attached to it, like danger or things.
# Information about these things is stored with tile
# Tile keys are Vector2is
# Keep information with tile about how many times it's been visited!!!!!
# For trails!!!!!!!
var map := {}

var tile_presets := {
	
}

# Generates map
func generate_map():
	# First generates all tile locations
	var row_total = randi_range(30,35)
	var row_count = 0
	var last_row_info = {"offset": 0, "length": 17}
	
	while row_count <= row_total:
		var row_length = clampi(randi_range(-1, 1) + last_row_info.length, 15, 20)
		var row_offset = randi_range(-2,2) + last_row_info.offset
		for i in range(row_length):
			map[Vector2(i + row_offset, row_count)] = "true"
			
		row_count += 1
		last_row_info.offset = row_offset
		last_row_info.length = row_length
		
	return "please await properly damn it"
