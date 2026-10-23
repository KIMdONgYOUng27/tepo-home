extends SceneTree
func _initialize() -> void: call_deferred("run")
func old_query(grid: Dictionary,pos: Vector2,radius: float) -> Array:
	var result:Array=[]
	var reach:=ceili((radius+70)/100)
	var cell:=Vector2i(floori(pos.x/100),floori(pos.y/100))
	for y in range(-reach,reach+1):
		for x in range(-reach,reach+1): result.append_array(grid.get(cell+Vector2i(x,y),[]))
	return result
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false); g.persist_results=false; g.sound_enabled=false;g.start_game()
	g.elapsed=1190
	for i in 300: g.spawn_enemy()
	var old_grid:Dictionary={}
	for i in g.enemies.size():
		var e:Dictionary=g.enemies[i]
		e.pos=g.player+Vector2((i%12)*100-550,(i/12)*100-450)
		var key:=Vector2i(floori(e.pos.x/100),floori(e.pos.y/100))
		if not old_grid.has(key): old_grid[key]=[]
		old_grid[key].append(e)
	g.build_grid()
	var queries:Array=[]
	for i in 4000: queries.append([g.player+Vector2((i%17-8)*40,(i%11-5)*40),[80,120,240,850][i%4]])
	var started:=Time.get_ticks_usec()
	var old_candidates:=0
	for q in queries: old_candidates+=old_query(old_grid,q[0],q[1]).size()
	var old_ms:float=(Time.get_ticks_usec()-started)/1000.0
	started=Time.get_ticks_usec()
	var new_candidates:=0
	for q in queries: new_candidates+=g.nearby(q[0],q[1]).size()
	var new_ms:float=(Time.get_ticks_usec()-started)/1000.0
	print(JSON.stringify({"queries":queries.size(),"enemies":g.enemies.size(),"old_ms":old_ms,"new_ms":new_ms,"old_candidates":old_candidates,"new_candidates":new_candidates,"scope":"CPU broad-phase microbenchmark, not browser FPS"}))
	g.queue_free();await process_frame;quit()
