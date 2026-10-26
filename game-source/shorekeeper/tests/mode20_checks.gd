extends SceneTree
var errors:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok: errors+=1; push_error(message)
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.persist_results=false
	g.sound_enabled=false
	g.start_game()
	check(g.ROUND_TIME==1200 and g.encounters.waves.size()==20,"twenty-minute mode")
	check(g.encounters.bosses.map(func(b):return int(b.time))==[180,360,540,720,900,1140],"boss cadence")
	check(g.xp_needed()==5,"initial growth")
	g.level=20
	check(g.xp_needed()<250,"no old level-twenty XP wall")
	g.enemies.clear()
	for i in 300: g.spawn_enemy()
	check(g.enemies.size()<=46,"early roster caps instead of infinite crowd accumulation")
	g.elapsed=1190
	for i in 300: g.spawn_enemy()
	check(g.enemies.size()<=g.ORDINARY_CAP,"late ordinary cap")
	for i in 50: g.spawn_enemy(false,false,5,true)
	check(g.enemies.size()<=g.TOTAL_CAP,"total creature cap")
	g.spawn_enemy(true)
	check(g.enemies.size()<=g.TOTAL_CAP and g.enemies[-1].boss,"boss arrival reserves capacity without losing the cap")
	g.presentation.low_fx=false
	check(g.presentation.light_effects(),"dense crowds reduce only decorative effects automatically")
	for i in g.enemies.size(): g.enemies[i].pos=g.player+Vector2((i%13)*100-600,(i/13)*100-400)
	g.build_grid()
	for radius in [10,80,240,850,2000]:
		var list:Array=g.nearby(g.player,radius)
		for e in g.enemies:
			if e.pos.distance_to(g.player)<=radius: check(list.has(e),"broad phase never misses a candidate")
	# Interception differs from simple tail pursuit and warning precedes a charge.
	g.enemies.clear()
	g.elapsed=200
	g.spawn_enemy(false,false,3)
	var hunter:Dictionary=g.enemies[-1]
	hunter.pos=g.player+Vector2(-500,0)
	hunter.phase=0
	g.move_dir=Vector2.UP
	var before:Vector2=hunter.pos
	g.update_enemies(0.01)
	check(hunter.pos.y<before.y,"hunter leads a moving target")
	g.elapsed=220.01
	g.update_enemies(0.01)
	check(hunter.get("charge_warning",0)>0,"dash has a visible warning window")
	# New mode records are separate, sorted by survival then kills, once per run.
	var ranking=g.rankings
	ranking.rows=[]
	g.elapsed=300;g.kills=100;ranking.record(false)
	ranking.record(false)
	check(ranking.rows.size()==1,"one result per run")
	ranking.submitted=false
	g.elapsed=1200;g.kills=20;ranking.record(true)
	ranking.submitted=false
	g.elapsed=1200;g.kills=30;ranking.record(true)
	var list:Array=ranking.ordered()
	check(list[0].kills==30 and list[1].kills==20 and list[2].seconds==300,"survival ranking and tie break")
	ranking.rows.append({"id":"older-rules","mode":"shore20-v14","date":ranking.today(),"seconds":1200,"kills":99999})
	check(ranking.ordered().size()==3,"dash-mode ranking does not mix older combat rules")
	check(not ranking.online and ranking.endpoint.is_empty(),"local records never masquerade as global ranking")
	g.hud.show_rankings(false)
	check(g.hud.ranking_open,"ranking board opens")
	print("MODE20: %d errors. Caps, growth, pursuit warning, broad-phase coverage, ranking ordering and local isolation."%errors)
	g.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	quit(1 if errors else 0)
