extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false);g.persist_results=false;g.sound_enabled=false;g.harbor={"power":0,"vitality":0,"luck":0}
	var builds:={"weak":{"sand":1},"mid":{"sand":8,"bowl":8,"wave":5,"power":3,"haste":3,"armor":2},"strong":{"sand":8,"bowl":8,"wave":8,"tetra":8,"kelp":8,"pearl":8,"power":5,"haste":5,"armor":4,"area":4,"regen":3}}
	var report:Array=[]
	for name in builds:
		g.rng.seed=1414
		g.start_game();g.upgrades=builds[name].duplicate()
		g.hp=g.max_health()
		for i in 12001:
			if g.state in ["lost","won"]: break
			# Fixed builds deliberately decline new upgrades; no HP overrides.
			if g.state=="treasure": g.treasure_clock=g.treasure_duration();g.close_treasure()
			if g.state=="blessing": g.state="running";g.hud.clear_modal()
			if g.state=="levelup": g.xp=0;g.state="running";g.hud.clear_modal()
			var theta:float=g.elapsed*225/320
			g.tick(0.1,Vector2(-sin(theta),cos(theta)))
		report.append({"build":name,"seconds":g.elapsed,"state":g.state,"hp":g.hp,"kills":g.kills,"bosses_seen":g.boss_index})
		print(JSON.stringify(report[-1]))
	FileAccess.open("../output/v14-balance-simulation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	g.queue_free();await process_frame;quit()
