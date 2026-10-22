extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.persist_results=false
	g.sound_enabled=false
	root.size=Vector2i(960,600)
	var groups:=[["sand","pearl","shell","snack","stone","chain"],["bowl","kelp","wave","rain","tetra","anchor"],["gull_white","gull_dark","feather","gust","wing_union","pearl"],["gull_union","wave","tetra","chain","bowl","rain"],["heat"]]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("../output/fx-v09-frames"))
	for group in groups.size():
		g.start_game()
		g.enemies.clear()
		g.upgrades={"area":2,"power":2}
		for id in groups[group]: g.upgrades[id]=3
		g.elapsed=0.05
		if group==3:
			for id in groups[group]: g.evolved[id]=true
		for n in 60:
			g.spawn_enemy(false,false,n%5)
			var e:Dictionary=g.enemies[-1]
			e.pos=g.player+Vector2.from_angle(TAU*n/60.0)*(100+n%7*34)
			e.hp=100000
			e.max_hp=e.hp
			e.speed=0
		g.build_grid()
		g.camera.position=g.player
		for frame in 64:
			g.hp=g.max_health()
			g.tick(1.0/30,Vector2.ZERO)
			g.state="running"
			g.hud.clear_modal()
			g.hud.refresh()
			g.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			if frame==12 or frame==27:
				root.get_texture().get_image().save_png("../output/tepo-v09-attacks-%d-%d.png"%[group,frame])
			if group==2 and frame%2==0:
				root.get_texture().get_image().save_png("../output/fx-v09-frames/frame-%d.png"%(frame/2))
	quit()
