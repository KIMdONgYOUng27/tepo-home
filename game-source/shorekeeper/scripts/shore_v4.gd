extends Node2D
const SIZE := Vector2(12288,7680)
const PLAY := Rect2(160,220,11968,6820)
const COLLISION_CELL := 180.0
var objects: Array[Dictionary] = []
var terrain: Texture2D
var props: Texture2D
var collision_grid: Dictionary = {}

func _ready() -> void:
	z_index = -20
	terrain = load("res://assets/terrain-v4.png")
	props = load("res://assets/shore-props-v2.png")
	var random := RandomNumberGenerator.new()
	random.seed=28317
	for y in range(650,6600,720):
		for x in range(600,12000,880):
			var pos := Vector2(x+random.randf_range(-170,170),y+random.randf_range(-150,150))
			if pos.distance_to(Vector2(6000,4000))<350: continue
			var index := 0 if y<2500 else (2 if y<3600 else random.randi_range(1,5))
			var sizes := [Vector2(245,265),Vector2(125,100),Vector2(165,115),Vector2(195,104),Vector2(132,130),Vector2(170,200)]
			var feet := [Vector2(66,45),Vector2(80,36),Vector2(130,32),Vector2(165,40),Vector2(90,65),Vector2(84,45)]
			add_prop(pos,index,sizes[index],feet[index])
	for x in range(450,12000,500):
		add_prop(Vector2(x,6990),4,Vector2(132,130),Vector2(90,65))
	queue_redraw()

func add_prop(pos: Vector2,index: int,size: Vector2,footprint: Vector2) -> void:
	var object := {"pos":pos,"index":index,"size":size,"rect":Rect2(pos-Vector2(footprint.x/2,footprint.y),footprint)}
	objects.append(object)
	for y in range(floori(object.rect.position.y/COLLISION_CELL)-1,floori(object.rect.end.y/COLLISION_CELL)+2):
		for x in range(floori(object.rect.position.x/COLLISION_CELL)-1,floori(object.rect.end.x/COLLISION_CELL)+2):
			var key:=Vector2i(x,y)
			if not collision_grid.has(key): collision_grid[key]=[]
			collision_grid[key].append(object)

func blocked(pos: Vector2,radius: float=18) -> bool:
	if not PLAY.grow(-radius).has_point(pos): return true
	var key:=Vector2i(floori(pos.x/COLLISION_CELL),floori(pos.y/COLLISION_CELL))
	for o in collision_grid.get(key,[]):
		if o.rect.grow(radius).has_point(pos): return true
	return false

func slide(pos: Vector2,motion: Vector2,radius: float=18) -> Vector2:
	var result:=pos
	var steps:=maxi(1,ceili(motion.length()/12))
	for i in steps:
		var part:=motion/steps
		if not blocked(result+Vector2(part.x,0),radius): result.x+=part.x
		if not blocked(result+Vector2(0,part.y),radius): result.y+=part.y
	return result

func _draw() -> void:
	var cell:=Vector2(terrain.get_width()/4.0,terrain.get_height()/2.0)
	for y in range(15):
		for x in range(24):
			var index:int=2 if y<5 else (4 if y<7 else 0 if y<13 else (7 if y==13 else 6))
			var source:=Rect2(Vector2(index%4,index/4)*cell,cell)
			draw_texture_rect_region(terrain,Rect2(x*512,y*512,512,512),source)
	for x in [2300,6000,9700]:
		draw_line(Vector2(x,150),Vector2(x+240,3500),Color(0.81,0.71,0.48,0.24),150,true)
