extends SceneTree
var g: Node2D
var samples:Array[float]=[]
var start:=0
var previous:=0
var frames:=0
var calls:=0.0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.persist_results=false
	g.sound_enabled=false
	g.start_game()
	g.set_process(false)
	g.elapsed=1150
	g.boss_index=g.encounters.bosses.size()
	g.blessing_index=g.encounters.blessing_bosses.size()
	g.swarm_index=g.encounters.swarms.size()
	g.elite_check=g.encounters.miniboss.checks.size()
	g.upgrades={"sand":8,"chain":8,"shell":8,"rain":8,"bowl":8,"stone":8,"power":5,"amount":2,"area":5,"haste":5}
	var birds:bool="--birds" in OS.get_cmdline_user_args()
	if birds: g.upgrades={"gull_union":8,"wing_union":1,"wave":8,"tetra":8,"rain":8,"bowl":8,"power":5,"amount":2,"area":5,"haste":5,"revive":2}
	g.enemies.clear()
	for n in 112:
		if not g.spawn_enemy(false,false,n%9): continue
		var e:Dictionary=g.enemies[-1]
		e.pos=g.player+Vector2.from_angle(TAU*n/112.0)*(160+n%17*22)
		e.hp=1000000
		e.max_hp=e.hp
	start=Time.get_ticks_usec()
	previous=start
	while Time.get_ticks_usec()-start<32000000:
		await process_frame
		var now:=Time.get_ticks_usec()
		var dt:float=(now-previous)/1000000.0
		previous=now
		if now-start>2000000: samples.append(dt*1000)
		g.hp=g.max_health()
		g.invulnerable=10
		g.tick(minf(dt,0.05),Vector2.from_angle(frames*0.01)*0.3)
		if g.state!="running": g.state="running"; g.hud.clear_modal()
		g.queue_redraw()
		frames+=1
		calls=maxf(calls,Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	samples.sort()
	var sum:=0.0
	for ms in samples: sum+=ms
	var report:={"backend":"native OpenGL Compatibility; not a browser/device certification","duration_seconds":32,"warmup_seconds":2,"samples":samples.size(),"fps":1000/(sum/maxi(1,samples.size())),"p95_frame_ms":samples[int(samples.size()*0.95)],"max_frame_ms":samples[-1],"max_draw_calls":calls,"enemies":g.enemies.size(),"meshes":g.presentation.meshes.size()}
	report.loadout="bird union, beams and ground attacks" if birds else "projectiles, melee and ground attacks"
	FileAccess.open("../output/tepo-v14-native-performance-birds.json" if birds else "../output/tepo-v14-native-performance.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print(JSON.stringify(report))
	quit()
