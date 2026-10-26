extends SceneTree
func _initialize() -> void: call_deferred("run")
func shot(g: Node,path: String) -> void:
	g.hud.refresh()
	g.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.persist_results=false
	g.sound_enabled=false
	root.size=Vector2i(1280,800)
	var groups:Array=[
		{"sand":8,"chain":8,"shell":8,"snack":8,"stone":8,"pearl":8,"area":3,"amount":1},
		{"gull_union":8,"wing_union":1,"wave":8,"tetra":8,"rain":8,"bowl":8,"area":3,"amount":1},
		{"kelp":8,"anchor":8,"feather":8,"gust":8,"heat":8,"area":3}]
	for index in groups.size():
		g.start_game()
		g.upgrades=groups[index]
		g.enemies.clear()
		g.chests.clear()
		g.pickups.clear()
		g.elapsed=0.15
		g.timers.spawn=100
		for n in 28:
			g.spawn_enemy(false,false,n%9)
			g.enemies[-1].pos=g.player+Vector2.from_angle(TAU*n/28.0)*(260+(n%4)*65)
			g.enemies[-1].hp=100000
			g.enemies[-1].max_hp=100000
		for n in 12:
			g.invulnerable=10
			g.tick(0.016,Vector2.ZERO)
			await process_frame
		g.camera.position=g.player
		if index==2: g.water_time=8
		var current=g.combat_fx
		g.combat_fx=load("res://tests/feedback_v15_baseline.gd").new()
		g.combat_fx.g=g
		await shot(g,"../output/tepo-v15-before-%d.png"%index)
		g.combat_fx=current
		await shot(g,"../output/tepo-v15-after-%d.png"%index)
	g.start_game()
	g.enemies.clear()
	g.camera.position=g.player
	g.banner="자석 · 온 바다의 경험치가 테포에게!"
	g.banner_time=5
	for n in 55: g.add_gem(g.player+Vector2.from_angle(n*2.4)*(200+n*12),1+n%5)
	g.apply_pickup("magnet")
	for n in 12:
		g.update_gems(0.016)
		g.update_player_motion(0.016)
	await shot(g,"../output/tepo-v15-magnet.png")
	g.try_dash(Vector2.RIGHT)
	for n in 4: g.update_player_motion(0.03)
	await shot(g,"../output/tepo-v15-dash.png")
	print("V15 preview: 3 before/after loadouts, magnet and dash captured.")
	quit()
