extends Node2D

const SIZE := Vector2(6400, 1800)
const PLAY := Rect2(110, 390, 6180, 810)
var objects: Array[Dictionary] = []
var terrain: Texture2D
var props: Texture2D
var collision_grid: Dictionary = {}
const COLLISION_CELL := 180.0

func _ready() -> void:
	z_index = -20
	terrain = load("res://assets/gwangalli-v2.png")
	props = load("res://assets/shore-props-v2.png")
	# Visual footprints and collision footprints are deliberately separate.
	for x in [470, 1190, 2630, 4020, 5470, 6050]:
		add_prop(Vector2(x,425),0,Vector2(245,265),Vector2(66,45))
	for x in [740, 1540, 2360, 3420, 4610, 5760]:
		add_prop(Vector2(x,505),2,Vector2(165,115),Vector2(130,32))
	for x in [970, 3180, 5100]:
		add_prop(Vector2(x,640),7,Vector2(235,240),Vector2(170,70))
	for x in [700, 1470, 2610, 3800, 4800, 5680]:
		add_prop(Vector2(x,1040),5,Vector2(170,200),Vector2(84,45))
	for x in [1170, 2190, 3490, 4410, 5900]:
		add_prop(Vector2(x,800),3,Vector2(195,104),Vector2(165,40))
	for x in [350, 650, 1060, 3950, 4380, 5860, 6150]:
		add_prop(Vector2(x,1335),4,Vector2(132,130),Vector2(90,65))
	for x in [500, 1900, 2900, 4200, 5500]:
		add_prop(Vector2(x,580),1,Vector2(125,100),Vector2(80,36))
	queue_redraw()

func add_prop(pos: Vector2, index: int, size: Vector2, footprint: Vector2) -> void:
	var object := {"pos":pos,"index":index,"size":size,"rect":Rect2(pos-Vector2(footprint.x/2,footprint.y),footprint)}
	objects.append(object)
	var broad: Rect2 = object.rect.grow(32)
	for y in range(floori(broad.position.y/COLLISION_CELL),floori(broad.end.y/COLLISION_CELL)+1):
		for x in range(floori(broad.position.x/COLLISION_CELL),floori(broad.end.x/COLLISION_CELL)+1):
			var key := Vector2i(x,y)
			if not collision_grid.has(key): collision_grid[key]=[]
			collision_grid[key].append(object)

func blocked(pos: Vector2, radius: float = 18.0) -> bool:
	if not PLAY.grow(-radius).has_point(pos): return true
	var key := Vector2i(floori(pos.x/COLLISION_CELL),floori(pos.y/COLLISION_CELL))
	for o in collision_grid.get(key,[]):
		if o.rect.grow(radius).has_point(pos): return true
	return false

func slide(pos: Vector2, motion: Vector2, radius: float = 18.0) -> Vector2:
	var result := pos
	var next := result + Vector2(motion.x,0)
	if not blocked(next,radius): result = next
	next = result + Vector2(0,motion.y)
	if not blocked(next,radius): result = next
	return result

func _draw() -> void:
	# Cached canvas commands: the panoramic painting is not rebuilt every frame.
	if terrain: draw_texture_rect(terrain,Rect2(Vector2.ZERO,SIZE),false)
	else: draw_rect(Rect2(Vector2.ZERO,SIZE),Color("c9b98b"))
	draw_rect(Rect2(-1500,-1500,9400,1500),Color("264c3e"))
	draw_rect(Rect2(-1500,1800,9400,1500),Color("21585b"))
