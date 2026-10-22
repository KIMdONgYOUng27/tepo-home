extends SceneTree
var errors:=0

func _initialize() -> void: call_deferred("run")

func check(ok: bool,message: String) -> void:
	if not ok:
		errors+=1
		push_error("FAIL: "+message)

func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.persist_results=false
	g.harbor={"power":0,"vitality":0,"luck":0}
	g.sound_enabled=false
	g.rng.seed=417
	g.harbor_coins=300
	g.buy_harbor("power")
	check(g.harbor.power==1 and g.harbor_coins==200,"harbor purchase spends exact price")
	g.buy_harbor("power")
	g.buy_harbor("power")
	check(g.harbor.power==2 and g.harbor_coins==0,"unaffordable harbor purchase rejected")
	g.harbor={"power":0,"vitality":0,"luck":0}
	g.hud.show_start()
	for b in g.hud.modal.find_children("*","Button",true,false):
		if b.text.begins_with("출항하기"):
			b.pressed.emit()
			break
	check(g.state=="blessing","actual departure button opens blessing selection")
	g.start_game()
	check(g.shore.PLAY.size.y>6000 and g.shore.SIZE.x>12000,"expanded beach and park")
	check(g.camera.zoom.x<0.7,"wider camera")
	check(g.orbit_radius()>140,"orbit safely outside hero silhouette")
	check(g.catalog.filter(func(u):return u.kind=="weapon" and not u.get("chest_only",false)).size()==17,"seventeen agreed base weapons")
	check(g.catalog.filter(func(u):return u.kind=="passive").size()==14,"fourteen linked common passive choices")
	check(g.catalog.filter(func(u):return u.kind=="special").is_empty(),"no redundant weapon-special cards")
	check(g.encounters.creatures.size()==9,"nine sea creature types")
	check(g.encounters.waves.size()==30,"all thirty minute waves configured")
	for wave in g.encounters.waves:
		var sum:=0
		for w in wave.weights: sum+=int(w)
		check(sum==100,"species weights sum to one hundred")
		check(wave.weights.size()==g.encounters.creatures.size(),"every wave includes all creature slots")
		check(wave.weights.filter(func(w):return int(w)>0).size()<=3,"minute roster limited to three species")
		check(wave.weights.max()>=70,"every minute has a clear dominant species")
	var wall: Dictionary=g.shore.objects.filter(func(o):return o.index==3)[0]
	var pos: Vector2=wall.rect.position-Vector2(50,-10)
	var moved: Vector2=g.shore.slide(pos,Vector2(250,0),18)
	check(moved.x<wall.rect.position.x,"fast movement cannot tunnel through wall")
	for i in 16:
		var direction:=Vector2.from_angle(float(i)*TAU/16)
		check(absf(direction.angle_to(g.snap_aim(direction)))<0.001,"sixteen aim directions")
	for u in g.catalog:
		if u.has("requires") and str(u.requires)!="sand": check(not g.upgrade_available(u),"weapon gates")
	var chosen: Array=g.roll_choices()
	check(chosen.size()==3,"three initial unique choices")
	var ids: Array=chosen.map(func(u):return str(u.id))
	var unique: Dictionary={}
	for id in ids: unique[id]=true
	check(ids.size()==unique.size(),"unique choices")
	g.selected_options=chosen
	g.state="levelup"
	var previous:int=g.rerolls
	g.reroll_choices()
	check(g.rerolls==previous-1,"reroll resource spent")
	for u in g.selected_options: check(not ids.has(str(u.id)),"reroll excludes previous screen")
	var removed:String=g.selected_options[0].id
	g.banish_choice(removed)
	check(g.banished.has(removed),"banished entry removed")
	g.skip_choices()
	check(g.state=="running" and g.skips==4,"skip resumes combat")
	# Six common passives fill the inventory; seventh new passive is blocked.
	for u in g.catalog.filter(func(u):return u.kind=="passive").slice(0,6): g.apply_upgrade(u)
	var seventh: Dictionary=g.catalog.filter(func(u):return u.kind=="passive")[6]
	check(not g.upgrade_available(seventh),"six passive slot limit")
	g.start_game()
	g.enemies.clear()
	g.build_grid()
	g.apply_pickup("water")
	check(g.water_time==10,"water lasts ten seconds")
	g.spawn_enemy()
	var front: Dictionary=g.enemies[-1]
	front.pos=g.player+Vector2(100,0)
	front.hp=1000
	g.spawn_enemy()
	var behind: Dictionary=g.enemies[-1]
	behind.pos=g.player-Vector2(100,0)
	behind.hp=1000
	g.build_grid()
	g.aim=Vector2.RIGHT
	g.update_water_cannon(0.5)
	check(front.hp<1000 and behind.hp==1000,"water damages front cone only")
	g.update_water_cannon(20)
	check(g.water_time==0,"water expires")
	# Monster kill actually routes into the pickup list.
	g.encounters.water_cannon.normal_drop_chance=1
	g.pickups.clear()
	g.damage(behind,1001,Vector2.ZERO)
	check(g.pickups.size()==1 and g.pickups[0].kind=="water","normal enemy water drop route")
	g.encounters.water_cannon.normal_drop_chance=0.002
	g.spawn_enemy(true)
	var boss: Dictionary=g.enemies[-1]
	boss.pos=g.player+Vector2(90,0)
	g.camera.position=g.player
	g.upgrades.crit=100
	g.apply_pickup("wipe")
	check(is_equal_approx(boss.hp,boss.max_hp*0.9),"boss wipe stays ten percent even at guaranteed crit")
	g.upgrades.crit=0
	g.upgrades.vitality=2
	g.hp=139
	g.apply_pickup("food30")
	check(g.hp==140,"food respects upgraded max HP")
	# A chest created before ten minutes cannot evolve even if opened later.
	g.upgrades.sand=8
	g.upgrades.projectilespeed=1
	g.elapsed=700
	g.grant_boss_chest(1,false)
	check(not g.evolved.has("sand"),"early chest has no evolution")
	g.treasure_clock=g.treasure_duration()
	g.close_treasure()
	g.grant_boss_chest(3,true)
	check(g.evolved.has("sand") and g.last_boss_rewards.size()==3,"evolution plus remaining rewards")
	g.treasure_clock=g.treasure_duration()
	g.close_treasure()
	check(not g.upgrade_available(g.catalog.filter(func(u):return u.id=="sand_level")[0]),"evolved base no longer upgrades")
	g.offer_blessing()
	check(g.state=="blessing" and g.selected_options.size()==4,"four blessing choices")
	var blessing:String=g.selected_options[0].id
	g.choose_blessing(blessing)
	check(g.blessings.has(blessing) and g.state=="running","blessing applies")
	for u in g.catalog: check(not g.upgrade_preview(u).is_empty(),"every card has effects")
	check(g.stats_rows().size()==17,"complete visible stat sheet")
	g.hp=0
	g.upgrades.revive=1
	g.tick(0.01,Vector2.ZERO)
	check(g.state=="running" and g.hp>0 and g.revivals_used==1,"one real revival")
	var arsenal_audit=load("res://tests/arsenal_checks.gd").new()
	errors+=arsenal_audit.run(g)
	# Eligibility belongs to the scheduled boss wave, never its delayed death/open time.
	for boss_time in [300,600]:
		g.start_game()
		g.elapsed=boss_time
		g.check_stage_events()
		var bosses:Array=g.enemies.filter(func(e):return e.boss)
		var target:Dictionary=bosses[-1]
		g.elapsed=700
		g.upgrades={"sand":8,"projectilespeed":1}
		g.damage(target,target.hp+1,Vector2.ZERO,false)
		var chest:Dictionary=g.chests[-1]
		check(bool(chest.can_evolve)==(boss_time>=600),"drop preserves boss wave eligibility")
		g.open_chest(chest)
		check(g.evolved.has("sand")== (boss_time>=600),"actual chest route respects wave time")
		g.treasure_clock=g.treasure_duration()
		g.close_treasure()
	# Early waves have no ranged creature; barnacles never shoot, even late.
	g.start_game()
	g.enemies.clear()
	for kind in range(8):
		g.spawn_enemy(false,false,kind)
		g.enemies[-1].attack_cd=0
		g.enemies[-1].pos=g.player+Vector2(350,0)
	g.update_enemies(0.01)
	check(g.enemy_shots.is_empty(),"early melee creatures never shoot")
	g.spawn_enemy(false,false,8)
	check(g.enemies[-1].kind==0,"early forced ranged spawn falls back to melee")
	g.elapsed=500
	g.enemies.clear()
	for i in 12: g.spawn_enemy(false,false,8)
	check(g.enemies.filter(func(e):return e.kind==8).size()==3,"maximum three ranged creatures alive")
	for e in g.enemies:
		e.pos=g.player+Vector2(350,0)
		e.attack_cd=0
	g.update_enemies(0.01)
	check(g.enemy_shots.size()==3,"late ranged creatures fire single shots")
	for e in g.enemies: e.attack_cd=0
	g.update_enemies(0.01)
	check(g.enemy_shots.size()<=4,"creature projectile cap")
	g.enemy_shots.clear()
	g.enemies.clear()
	g.spawn_enemy(false,false,1)
	g.enemies[-1].pos=g.player+Vector2(350,0)
	g.enemies[-1].attack_cd=0
	g.update_enemies(0.01)
	check(g.enemy_shots.is_empty(),"late barnacle stays melee")
	# A swarm is a coherent weak straight crossing, with no homing or expiry rewards.
	g.enemies.clear()
	g.elapsed=128
	g.spawn_swarm({"kind":5,"count":24})
	check(not g.enemies.is_empty(),"swarm finds safe offscreen entries")
	var rush_direction:Vector2=g.enemies[0].rush_dir
	for e in g.enemies:
		check(e.kind==5 and e.hp<12 and e.speed==290,"swarm uses correct weak fast species stats")
		check(e.rush_dir==rush_direction,"swarm shares a fixed direction")
	g.player+=Vector2(100,80)
	g.update_enemies(0.1)
	check(g.enemies[0].rush_dir==rush_direction,"swarm does not retarget player")
	var lifetime:float=g.enemies[0].rush_life
	g.freeze_time=5
	g.update_enemies(0.5)
	check(g.enemies[0].rush_life==lifetime,"freeze pauses swarm passage")
	g.freeze_time=0
	var previous_kills:int=g.kills
	var previous_gems:int=g.gems.size()
	for e in g.enemies: e.rush_life=0.01
	g.update_enemies(0.02)
	check(g.enemies.all(func(e):return e.hp<=0),"swarms expire without recycling")
	check(g.kills==previous_kills and g.gems.size()==previous_gems,"expiry grants no free kills or XP")
	# All wave transitions and attacks run in a complete deterministic 30-minute simulation.
	g.start_game()
	g.upgrades={"sand":8,"bowl":8,"wave":8,"tetra":8,"kelp":8,"pearl":8,"power":5,"haste":5,"area":5,"armor":5,"magnet":5,"regen":5}
	for i in 3602:
		if g.state=="won": break
		if g.state=="levelup": g.choose_upgrade(str(g.selected_options[0].id))
		if g.state=="treasure": g.treasure_clock=g.treasure_duration(); g.close_treasure()
		if g.state=="blessing": g.choose_blessing(str(g.selected_options[0].id))
		g.hp=g.max_health()
		g.tick(0.5,Vector2.from_angle(i*0.035))
	check(g.state=="won" and g.elapsed==1800,"thirty-minute victory")
	check(g.boss_index==6 and g.blessing_index==2,"six major and two blessing boss windows")
	check(g.swarm_index==g.encounters.swarms.size(),"all swarm events evaluated")
	check(g.enemies.size()<=248 and g.particles.size()<=90 and g.gems.size()<=180,"entity limits after full stage")
	# Include the new projectile, summon, shield and screen-clear families in long runs.
	for loadout in [["chain","shell","snack","rain","stone","tetra"],["heat","gull_white","gull_dark","feather","gust","anchor"]]:
		g.start_game()
		g.upgrades={"power":5,"haste":5,"area":5,"duration":5,"amount":2,"projectilespeed":5}
		for weapon in loadout: g.upgrades[weapon]=8
		for frame in 3602:
			if g.state=="won": break
			if g.state=="levelup": g.choose_upgrade(str(g.selected_options[0].id))
			if g.state=="treasure": g.treasure_clock=g.treasure_duration(); g.close_treasure()
			if g.state=="blessing": g.choose_blessing(str(g.selected_options[0].id))
			g.hp=g.max_health()
			g.tick(0.5,Vector2.from_angle(frame*0.025))
		check(g.state=="won" and g.elapsed==1800,"new arsenal loadout completes full thirty-minute stage")
		check(g.arsenal.pending.size()+g.bullets.size()<=180 and g.arsenal.zones.size()<=48 and g.arsenal.flights.size()<=48,"new arsenal and flight bounds throughout long loadout")
	g.start_game()
	check(g.water_time==0 and g.evolved.is_empty() and g.blessings.is_empty(),"restart clears temporary and evolution state")
	g.hp=0
	g.tick(0.01,Vector2.ZERO)
	check(g.state=="lost","defeat flow")
	print("FULL STAGE: %d errors. 30-minute flow, 17 weapons, 14 passives, restricted rosters, arsenal, stat applicability, evolutions, equipment caps, water, blessings, reroll/banish/skip, revival, collision."%errors)
	g.queue_free()
	await process_frame
	quit(1 if errors else 0)
