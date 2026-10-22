extends SceneTree
var g: Node2D
func _initialize() -> void: call_deferred("run")
func run() -> void:
	g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.persist_results=false
	g.sound_enabled=false
	g.start_game()
	g.set_process(false)
	g.enemies.clear()
	g.upgrades={"sand":8,"bowl":5,"chain":4,"shell":3,"rain":3,"anchor":3}
	for kind in 9:
		g.spawn_enemy(false,false,kind)
		g.enemies[-1].pos=g.player+Vector2((kind%5-2)*150,(-1 if kind<5 else 1)*160)
	for i in 48:
		g.presentation.walk_clock+=0.04
		for e in g.enemies: e.anim_clock=i*0.035; e.moving=true
		g.arsenal.update(0.016)
		g.move_dir=Vector2.RIGHT
		g.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("../output/tepo-v08-combat.png")
	if g.presentation.walk_sheet: g.presentation.walk_sheet.get_image().save_png("../output/tepo-v08-motion-sheet.png")
	g.state="paused"
	g.hud.show_settings()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("../output/tepo-v08-settings.png")
	root.size=Vector2i(844,390)
	for i in 5: await process_frame
	g.selected_options=g.roll_choices()
	g.state="levelup"
	g.hud.show_choices(g.selected_options)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("../output/tepo-v08-landscape.png")
	quit()
