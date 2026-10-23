extends SceneTree
func _initialize() -> void: call_deferred("run")
func shot(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false);g.persist_results=false;g.sound_enabled=false
	root.size=Vector2i(1280,800)
	g.hud.show_start()
	await shot("../output/tepo-v14-title.png")
	g.rankings.rows=[{"id":"review-1","date":g.rankings.today(),"name":"검수용 완주 기록","seconds":1200.0,"kills":3200,"won":true},{"id":"review-2","date":g.rankings.today(),"name":"검수용 생존 기록","seconds":780.5,"kills":1600,"won":false}]
	g.hud.show_rankings(false)
	await shot("../output/tepo-v14-ranking.png")
	g.start_game()
	g.enemies.clear();g.elapsed=220.1
	for i in 3:
		g.spawn_enemy(false,false,3)
		g.enemies[-1].pos=g.player+Vector2(-280+i*260,-150)
		g.enemies[-1].phase=0
	g.update_enemies(0.01)
	g.camera.position=g.player
	g.hud.refresh();g.queue_redraw()
	await shot("../output/tepo-v14-hunter-warning.png")
	quit()
