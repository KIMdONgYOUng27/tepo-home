extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.persist_results=false
	g.sound_enabled=false
	root.size=Vector2i(1280,800)
	g.start_game()
	g.upgrades={"sand":3,"bowl":3,"wave":2,"power":2,"area":1}
	for count in [1,3,5]:
		g.upgrades={"sand":7,"bowl":7,"wave":7,"power":4,"area":4}
		g.grant_boss_chest(count,false)
		for time in [1.2,4.2]:
			g.treasure_clock=time
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("../output/tepo-v10-treasure-%d-%s.png"%[count,"spin" if time<2 else "done"])
		g.treasure_clock=g.treasure_duration()
		g.close_treasure()
	g.chests.clear()
	for i in 4:
		g.chests.append({"pos":g.player+Vector2(-300+i*230,-200),"opened":false,"boss":i%2==0})
	for i in 8:
		g.spawn_pickup(g.player+Vector2(-430+i*120,170),["water","magnet","freeze","food30","xp","wipe","relic_left","coin"][i])
	g.camera.position=g.player
	g.hud.refresh()
	g.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("../output/tepo-v10-items.png")
	g.boss_warning=2.9
	g.banner="무단 낚시 대장 등장!"
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("../output/tepo-v10-warning.png")
	quit()
