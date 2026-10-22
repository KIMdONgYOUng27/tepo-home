extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error("FAIL: " + message)
		quit(1)
		assert(condition, message)

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.sound_enabled = false
	game.start_game()
	check(game.state == "running" and game.hp == 100, "round starts")
	check(game.shore.SIZE.x > game.shore.SIZE.y*3, "wide coastal map")
	for i in 16:
		var direction := Vector2.from_angle(float(i)*TAU/16)
		check(absf(direction.angle_to(game.snap_aim(direction)))<0.001,"all 16 aim bearings")
	for u in game.catalog:
		if u.has("requires") and str(u.requires)!="sand":
			check(not game.upgrade_available(u),"unowned weapon passives are locked")
	var wall: Dictionary = game.shore.objects.filter(func(o):return o.index==3)[0]
	var wall_rect: Rect2 = wall.rect
	var at_wall := Vector2(wall_rect.position.x-45,wall_rect.get_center().y)
	for i in 40: at_wall = game.shore.slide(at_wall,Vector2(8,0),18)
	check(at_wall.x < wall_rect.position.x-17,"obstacles stop player traversal")
	var start: Vector2 = game.player
	game.tick(0.1, Vector2.RIGHT)
	check(game.player.x > start.x, "movement")
	game.toggle_pause()
	var stopped: float = game.elapsed
	game._process(0.05)
	check(game.elapsed == stopped, "pause freezes simulation")
	game.toggle_pause()
	game.xp = game.xp_needed() * 2
	game.tick(0.01, Vector2.ZERO)
	check(game.state == "levelup" and game.selected_options.size() == 3, "XP creates three choices")
	check(game.selected_options[0].id == "bowl", "first level introduces orbit")
	game.choose_upgrade("not-a-choice")
	check(game.state == "levelup", "invalid choice is rejected")
	game.choose_upgrade("bowl")
	check(game.upgrades.bowl == 1 and game.state == "running", "selected upgrade applies")
	var bowl_special: Dictionary = game.catalog.filter(func(u):return u.id=="bowl_spin")[0]
	check(game.upgrade_available(bowl_special),"weapon passive unlocks after acquisition")
	# Field chests roll one food/utility item, open once, and never grant XP.
	game.pickups.clear()
	var chest := {"pos":game.player+Vector2(200,0),"opened":false}
	var chest_xp: float = game.xp
	game.open_chest(chest)
	game.open_chest(chest)
	check(game.pickups.size()==1 and game.pickups[0].kind!="xp" and game.xp==chest_xp,"chest utility reward and single opening")
	game.hp=95
	game.apply_pickup("food30")
	check(game.hp==100,"food healing clamps to maximum")
	game.hp=40
	game.apply_pickup("food20")
	check(game.hp==60,"elite food heals twenty")
	game.hp=100
	check(game.weighted_id(game.encounters.field_loot,0.699)=="food15","food common boundary")
	check(game.weighted_id(game.encounters.field_loot,0.70)=="food30","food large boundary")
	check(game.weighted_id(game.encounters.boss_chest,0.8731)=="3","three-item tier boundary")
	check(game.weighted_id(game.encounters.boss_chest,0.9701)=="5","five-item tier boundary")
	game.rng.seed=412
	var counts := {"1":0,"3":0,"5":0}
	for i in 20000:
		var reward: String=game.weighted_id(game.encounters.boss_chest)
		counts[reward]+=1
	check(absf(counts["5"]/20000.0-0.03)<0.008,"seeded five-item frequency")
	check(absf(counts["3"]/20000.0-0.097)<0.012,"seeded three-item frequency")
	var boss_chest := {"pos":game.player,"opened":false,"boss":true}
	game.open_chest(boss_chest)
	var rewards_before: int=game.last_boss_rewards.size()
	game.open_chest(boss_chest)
	check(game.state=="treasure" and game.last_boss_rewards.size()==rewards_before,"boss reward modal opens once")
	game.treasure_clock=game.treasure_duration()
	game.close_treasure()
	for count in [1,3,5]:
		game.grant_boss_chest(count)
		check(game.last_boss_rewards.size()==count,"boss chest exact reward count")
		check(game.upgrades.get("wave",0)==0 and game.upgrades.get("tetra",0)==0,"boss chest cannot acquire unowned weapons")
		game.treasure_clock=game.treasure_duration()
		game.close_treasure()
	var saved_upgrades: Dictionary=game.upgrades.duplicate()
	for u in game.catalog: game.upgrades[str(u.id)]=int(u.max)
	for id in ["sand","bowl","wave","tetra"]: game.upgrades[id]=8
	game.grant_boss_chest(5)
	check(game.round_coins==125,"maxed inventory rewards coins")
	game.treasure_clock=game.treasure_duration()
	game.close_treasure()
	game.upgrades=saved_upgrades
	game.gems.clear()
	game.add_gem(Vector2(200,500),7)
	game.add_gem(Vector2(5900,1000),11)
	var before_magnet: float = game.xp
	game.apply_pickup("magnet")
	check(game.gems.is_empty() and game.xp==before_magnet+18,"magnet collects XP across entire map")
	game.spawn_enemy()
	var frozen_enemy: Dictionary = game.enemies[-1]
	var frozen_pos: Vector2 = frozen_enemy.pos
	game.apply_pickup("freeze")
	game.update_enemies(0.5)
	check(frozen_enemy.pos==frozen_pos,"time stop freezes enemy motion")
	game.freeze_time=0
	game.camera.position=game.player
	frozen_enemy.pos=game.player+Vector2(90,0)
	game.spawn_enemy()
	var offscreen_enemy: Dictionary = game.enemies[-1]
	offscreen_enemy.pos=game.player+Vector2(1700,0)
	game.apply_pickup("wipe")
	check(frozen_enemy.hp<=0 and offscreen_enemy.hp>0,"screen clear removes visible enemies only")
	game.spawn_enemy(true)
	var round_boss: Dictionary=game.enemies[-1]
	round_boss.pos=game.player+Vector2(100,0)
	game.apply_pickup("wipe")
	check(is_equal_approx(round_boss.hp,round_boss.max_hp*0.9),"screen wipe cannot instantly kill round boss")
	game.damage(round_boss,round_boss.hp,Vector2.ZERO)
	check(game.chests[-1].get("boss",false),"round boss drops equipment chest")
	# Test spawn chances and concurrency without relying on a lucky full run.
	game.start_game()
	game.encounters.miniboss.chance=0
	game.elapsed=40
	game.check_miniboss()
	check(game.elite_count==0 and game.elite_check==1,"failed miniboss roll is consumed once")
	game.encounters.miniboss.chance=1
	game.elapsed=70
	game.check_miniboss()
	check(game.elite_count==1,"eligible miniboss roll spawns")
	game.elapsed=100
	game.check_miniboss()
	check(game.elite_count==1,"at most one living miniboss")
	game.encounters.miniboss.chance=0.6
	var before_bonus: float = game.xp
	game.apply_pickup("xp")
	check(game.xp>before_bonus+20,"large XP reward")
	# Check all four attacks against a nearby crowd and simulate a full round.
	game.start_game()
	game.upgrades = {"sand":8,"bowl":8,"wave":8,"tetra":8,"power":5,"haste":5,"area":5,"armor":5,"magnet":5,"regen":5}
	for i in 20:
		game.spawn_enemy()
		game.enemies[-1].pos = game.player + Vector2.from_angle(float(i) / 20 * TAU) * 95
	for i in 300:
		game.hp = 100
		if game.state == "levelup": game.choose_upgrade(str(game.selected_options[0].id))
		game.tick(0.02, Vector2.ZERO)
	check(game.kills > 0, "upgraded attacks defeat enemies")
	game.gems.clear()
	for i in 210: game.add_gem(Vector2(500+i,500),1)
	var total := 0
	for gem in game.gems: total += int(gem.value)
	check(game.gems.size() == 180 and total == 210, "XP cap merges without losing value")
	for i in 9200:
		if game.state == "won": break
		game.hp = 100
		if game.state == "treasure": game.treasure_clock=game.treasure_duration(); game.close_treasure()
		if game.state == "levelup": game.choose_upgrade(str(game.selected_options[0].id))
		var direction := Vector2.from_angle(float(i) * 0.0025)
		game.tick(0.02, direction)
	check(game.state == "won", "180-second clear")
	check(game.boss_spawned, "boss wave")
	check(game.elite_check==4 and game.elite_count<=2,"four probability windows, maximum two minibosses")
	check(game.enemies.size() <= 103 and game.gems.size() <= 180 and game.particles.size() <= 90, "entity limits")
	game.start_game()
	check(game.kills == 0 and game.enemies.is_empty() and game.level == 1, "restart clears round")
	game.hp = 0
	game.tick(0.01, Vector2.ZERO)
	check(game.state == "lost", "death opens result")
	print("PASS v0.3: marine creatures, miniboss probability and concurrency, food, weighted loot, boss chest 1/3/5, capped upgrades, coins, boss wipe resistance, full round")
	game.queue_free()
	await process_frame
	quit(0)
