extends Node2D

@export var cell_size: int = 48
@export var grid_radius_cells: int = 20 # draws (2r x 2r) cells around origin
@export var color_a: Color = Color(0.22, 0.22, 0.24, 1.0)
@export var color_b: Color = Color(0.18, 0.18, 0.20, 1.0)

func _draw() -> void:
	var r := grid_radius_cells
	for y in range(-r, r):
		for x in range(-r, r):
			var is_a := ((x + y) & 1) == 0
			var c := color_a if is_a else color_b
			var pos := Vector2(x * cell_size, y * cell_size)
			draw_rect(Rect2(pos, Vector2(cell_size, cell_size)), c, true)

