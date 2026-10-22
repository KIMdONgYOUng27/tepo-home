extends SceneTree
var errors:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok: errors+=1; push_error("FX: "+message)
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.persist_results=false
	g.sound_enabled=false
	g.start_game()
	g.enemies.clear()
	g.spawn_enemy(false,false,0)
	var enemy:Dictionary=g.enemies[0]
	enemy.pos=g.player+Vector2(100,-12)
	enemy.hp=1000
	enemy.max_hp=1000
	g.build_grid()
	var a:RefCounted=g.arsenal
	a.cast("chain",a.stats("chain"))
	a.update_strokes(0.04)
	check(a.strokes[0].age>0 and enemy.hp==1000,"chain windup animates without premature damage")
	a.update_strokes(0.07)
	check(enemy.hp<1000 and a.strokes[0].hit,"chain damage starts at the forward sweep")
	a.reset()
	enemy.hp=1000
	a.add_zone(enemy.pos,30,50,0.35,"bird","gull_white")
	check(a.zones.is_empty() and a.flights[0].delay>=0.32 and a.flights[0].flight==0.32,"airborne bird has flight without consuming a ground-zone slot")
	a.update_zones(0.15)
	check(enemy.hp==1000,"airborne bird bomb cannot damage the ground")
	a.update_zones(0.18)
	check(enemy.hp==950 and a.zones[0].landed,"bird damages exactly at visible landing")
	a.update_zones(0.05)
	check(enemy.hp==950,"one bomb cannot repeatedly hit the same enemy")
	check(a.zones[0].hit,"bomb follow-through is visual rather than a repeatedly queried damage field")
	a.reset()
	g.upgrades={"gull_white":1}
	g.elapsed=0.1
	a.update_birds()
	check(not a.flights.is_empty() and a.flights[0].origin.y<g.player.y,"bird bomb starts in the air at the flying gull")
	for i in 100: a.add_zone(enemy.pos,20,1,0.35,"bird","gull_white")
	check(a.flights.size()<=48 and a.zones.size()<=48,"flight and ground zones have independent hard caps")
	a.reset()
	g.upgrades={"sand":1}
	a.queue_missile("sand",a.stats("sand"),Vector2.RIGHT,0.1)
	g.player+=Vector2(50,40)
	a.update_pending(0.2)
	check(g.bullets[-1].pos==g.player+Vector2(0,-12),"delayed shots leave the current player, not an abandoned position")
	for i in 150:
		g.elapsed+=0.2
		g.combat_fx.event("sand",g.player)
	check(g.combat_fx.events.size()<=28,"visual events capped independently of damage entities")
	g.combat_fx.update(1)
	check(g.combat_fx.events.is_empty(),"visual events expire")
	g.presentation.reduced_motion=true
	g.shake=0
	g.combat_fx.hit(enemy,"tetra",Vector2.RIGHT)
	check(g.shake==0,"reduced-motion setting suppresses offensive camera shake")
	g.start_game()
	check(g.combat_fx.events.is_empty() and g.combat_fx.recoil_time==0,"restart clears attack envelopes")
	print("COMBAT FX: %d errors. Sweep timing, aerial flight, landing damage, no repeat hit, moving emitter, bounded FX and reduced motion."%errors)
	g.queue_free()
	await process_frame
	quit(1 if errors else 0)
