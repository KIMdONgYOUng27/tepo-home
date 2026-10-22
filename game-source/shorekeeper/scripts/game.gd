extends Node2D

const HUD = preload("res://scripts/hud_v4.gd")
const ARSENAL = preload("res://scripts/arsenal_v7.gd")
const SHORE = preload("res://scripts/shore_v4.gd")
const PRESENTATION = preload("res://scripts/presentation_v8.gd")
const COMBAT_FX = preload("res://scripts/combat_fx_v9.gd")
var combat_fx: RefCounted
var presentation: RefCounted
var music: RefCounted
const WORLD_SIZE := Vector2(12288, 7680)
const ROUND_TIME := 1800.0
const CELL := 100.0
var state := "title"
var player := Vector2(6000, 4000)
var facing := Vector2.RIGHT
var move_dir := Vector2.ZERO
var elapsed := 0.0
var hp := 100.0
var xp := 0.0
var level := 1
var kills := 0
var best_time := 0.0
var invulnerable := 0.0
var boss_spawned := false
var next_enemy_id := 0
var upgrades: Dictionary = {"sand": 1}
var catalog: Array = []
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var gems: Array[Dictionary] = []
var waves: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var pops: Array[Dictionary] = []
var enemy_grid: Dictionary = {}
var timers := {"sand": 0.0, "wave": 1.0, "tetra": 2.0, "spawn": 0.0,"kelp":0.0,"pearl":0.0}
var orbit_angle := 0.0
var scene_time := 0.0
var shake := 0.0
var banner := ""
var banner_time := 0.0
var selected_options: Array = []
var camera: Camera2D
var hud: CanvasLayer
var rng := RandomNumberGenerator.new()
var touch_start := Vector2.ZERO
var touch_now := Vector2.ZERO
var touch_active := false
var touch_id := -1
var sound_enabled := true
var audio_players: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var sound_index := 0
var shore: Node2D
var hero_atlas: Texture2D
var villain_atlas: Texture2D
var pickups: Array[Dictionary] = []
var chests: Array[Dictionary] = []
var enemy_shots: Array[Dictionary] = []
var elite_count := 0
var freeze_time := 0.0
var flash_time := 0.0
var chest_timer := 55.0
var last_reward_icons: Array[int]=[]
var treasure_clock:=0.0
var boss_warning:=0.0
var aim := Vector2.RIGHT
var manual_aim := false
var hud_timer := 0.0
var pickup_sound_cd := 0.0
var bowl_style: StyleBoxFlat
var encounters: Dictionary = {}
var creature_atlas: Texture2D
var extra_creature_atlas: Texture2D
var elite_check := 0
var round_coins := 0
var last_boss_rewards: Array[String] = []
var effects: Texture2D
var icons: Texture2D
var evolved: Dictionary = {}
var blessings: Array[String] = []
var banished: Array[String] = []
var rerolls := 5
var skips := 5
var banishes := 5
var revivals_used := 0
var boss_index := 0
var harbor_coins := 0
var harbor: Dictionary = {"power":0,"vitality":0,"luck":0}
var persist_results := true
var swarm_index := 0
var blessing_index := 0
var water_time := 0.0
var water_reach := 340.0
var arsenal: RefCounted
var arsenal_icons: Texture2D
var retired_weapons: Array[String]=[]

func _ready() -> void:
	rng.randomize()
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/upgrades.json"))
	hero_atlas = load("res://assets/tepo-eight-v2.png")
	villain_atlas = load("res://assets/beach-villains-v2.png")
	creature_atlas = load("res://assets/marine-creatures-v3.png")
	extra_creature_atlas = load("res://assets/marine-creatures-v4-extra.png")
	encounters = JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))
	effects = load("res://assets/effects-v4.png")
	icons = load("res://assets/inventory-v4b.png")
	arsenal_icons=load("res://assets/arsenal-v7.png")
	arsenal=ARSENAL.new()
	arsenal.g=self
	combat_fx=COMBAT_FX.new()
	combat_fx.g=self
	presentation=PRESENTATION.new()
	presentation.g=self
	presentation.setup()
	music=load("res://scripts/music_v12.gd").new()
	music.g=self
	music.setup()
	shore = SHORE.new()
	add_child(shore)
	camera = Camera2D.new()
	camera.position = player
	camera.zoom = Vector2.ONE*0.66
	add_child(camera)
	hud = HUD.new()
	hud.game = self
	add_child(hud)
	bowl_style = hud.style(Color("4b423e"),8)
	init_audio()
	var save := ConfigFile.new()
	if save.load("user://tepo.cfg") == OK:
		best_time = float(save.get_value("records", "best", 0.0))
		sound_enabled = bool(save.get_value("settings", "sound", true))
		harbor_coins = int(save.get_value("harbor","coins",0))
		harbor = save.get_value("harbor","upgrades",harbor)
		presentation.volume=clampf(float(save.get_value("settings","effects_volume",0.65)),0,1)
		presentation.ui_volume=clampf(float(save.get_value("settings","ui_volume",0.7)),0,1)
		music.volume=clampf(float(save.get_value("settings","music_volume",0.55)),0,1)
		presentation.reduced_motion=bool(save.get_value("settings","reduced_motion",false))
		presentation.low_fx=bool(save.get_value("settings","low_fx",false))
	hud.show_start()
	hud.refresh()
	get_viewport().focus_exited.connect(_focus_lost)
	get_viewport().focus_entered.connect(func():music.foreground=true)

func _exit_tree() -> void:
	if music!=null: music.shutdown()

func start_game() -> void:
	boss_warning=0.0
	treasure_clock=0.0
	state = "running"
	player = Vector2(6000, 4000)
	facing = Vector2.RIGHT
	move_dir = Vector2.ZERO
	elapsed = 0.0
	hp = max_health()
	xp = 0.0
	level = 1
	kills = 0
	invulnerable = 0.0
	boss_spawned = false
	upgrades = {"sand":1}
	for collection in [enemies, bullets, gems, waves, drops, particles, pops, pickups, chests, enemy_shots]:
		collection.clear()
	enemy_grid.clear()
	timers = {"sand":0.1, "wave":1.0, "tetra":2.0, "spawn":0.0,"kelp":0.0,"pearl":0.0}
	orbit_angle = 0.0
	retired_weapons.clear()
	arsenal.reset()
	combat_fx.reset()
	presentation.reset()
	shake = 0.0
	touch_active = false
	touch_id = -1
	selected_options.clear()
	elite_count = 0
	elite_check = 0
	round_coins = 0
	last_boss_rewards.clear()
	last_reward_icons.clear()
	water_time = 0
	evolved.clear()
	blessings.clear()
	hp=max_health()
	banished.clear()
	rerolls=5
	skips=5
	banishes=5
	revivals_used=0
	boss_index=0
	swarm_index=0
	blessing_index=0
	water_reach = float(encounters.water_cannon.range)
	freeze_time = 0
	flash_time = 0
	chest_timer = next_supply_interval()
	manual_aim = false
	aim = Vector2.RIGHT
	chests.append({"pos":player+Vector2(300,100),"opened":false})
	for relic in ["relic_left","relic_right"]:
		var sign_value:= -1 if relic=="relic_left" else 1
		var pos:=player+Vector2(1700*sign_value,400)
		for tries in 30:
			if not shore.blocked(pos,30): break
			pos+=Vector2(0,45)
		spawn_pickup(pos,relic)
	for i in 14: spawn_enemy()
	hud.clear_modal()
	banner = "광안리 · 바다를 지키는 30분"
	banner_time = 3.0
	hud.refresh()

func _process(delta: float) -> void:
	music.update(minf(delta,0.1))
	# Portrait is an orientation gate, never a separate game layout.
	if OS.has_feature("web") and DisplayServer.is_touchscreen_available() and get_window().size.y>get_window().size.x and state=="running": toggle_pause()
	presentation.performance_sample(delta)
	var dt := minf(delta, 0.05)
	scene_time += dt
	if state=="running": boss_warning=maxf(0,boss_warning-dt)
	if state=="treasure": treasure_clock+=dt
	if state=="lost" and scene_time-float(get_meta("finish_clock",scene_time))>=0.5 and not is_instance_valid(hud.modal): hud.show_end(false)
	if state == "running":
		tick(dt)
	var offset := Vector2.ZERO
	if shake > 0 and state == "running" and not presentation.reduced_motion:
		offset = Vector2(rng.randf_range(-shake, shake), rng.randf_range(-shake, shake))
		shake = move_toward(shake, 0, dt * 30)
	camera.position = player.clamp(view_half(),WORLD_SIZE-view_half()) + offset
	hud_timer -= dt
	if hud_timer <= 0:
		hud.refresh()
		hud_timer = 0.1
	queue_redraw()

func tick(dt: float, input_override: Vector2 = Vector2.INF) -> void:
	if resolve_death(): return
	elapsed += dt
	invulnerable = maxf(0, invulnerable - dt)
	banner_time = maxf(0, banner_time - dt)
	freeze_time = maxf(0,freeze_time-dt)
	flash_time = maxf(0,flash_time-dt)
	pickup_sound_cd = maxf(0,pickup_sound_cd-dt)
	hp = minf(max_health(), hp + dt * recovery())
	move_dir = movement() if input_override == Vector2.INF else input_override.limit_length()
	if move_dir.length_squared() > 0.01:
		facing = move_dir.normalized()
		player = shore.slide(player,move_dir * 225 * move_speed() * dt,18)
	orbit_angle += dt * (2.8 + maxf(0,upgrades.get("bowl",0)-1)*0.1) * projectile_speed()
	timers.spawn -= dt
	if timers.spawn <= 0:
		var current := wave_data()
		var amount := int(current.batch)
		var minimum:=mini(180,roundi(float(current.minimum)*curse()))
		if enemies.size() < minimum: amount = mini(12,minimum-enemies.size())
		for i in amount: spawn_enemy()
		timers.spawn = float(current.interval)/curse()
	check_miniboss()
	check_stage_events()
	update_enemies(dt)
	if resolve_death(): return
	build_grid()
	update_aim()
	update_weapons(dt)
	update_gems(dt)
	update_rewards(dt)
	update_effects(dt)
	presentation.tick(dt)
	enemies = enemies.filter(func(e): return e.hp > 0)
	if state != "running": return
	if hp <= 0:
		resolve_death()
	elif elapsed >= ROUND_TIME:
		finish(true)
	elif xp >= xp_needed():
		open_level_up()

func resolve_death() -> bool:
	if hp>0: return false
	if revivals_used < upgrades.get("revive",0):
		revivals_used+=1
		hp=max_health()*0.5
		invulnerable=3
		presentation.sound("revive",true)
		banner="구명튜브 · 다시 일어나!"
		banner_time=3
		return false
	finish(false)
	return true

func movement() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): v.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): v.x += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): v.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): v.y += 1
	if v.length_squared() > 0: return v.normalized()
	if not Input.get_connected_joypads().is_empty():
		var stick := Vector2(Input.get_joy_axis(0,JOY_AXIS_LEFT_X),Input.get_joy_axis(0,JOY_AXIS_LEFT_Y))
		if stick.length() > 0.2: return stick.limit_length()
	if touch_active: return ((touch_now - touch_start) / 65.0).limit_length()
	return Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed and event.keycode in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT]) or event is InputEventScreenDrag or event is InputEventScreenTouch:
		presentation.note_input()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			toggle_pause()
		if event.keycode == KEY_M:
			manual_aim = not manual_aim
			banner = "마우스 16방향 조준" if manual_aim else "16방향 자동 조준 보정"
			banner_time = 2
	if state != "running": return
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:
			touch_id = event.index
			touch_start = event.position
			touch_now = event.position
			touch_active = true
		elif not event.pressed and event.index == touch_id:
			touch_active = false
			touch_id = -1
	elif event is InputEventScreenDrag and event.index == touch_id:
		touch_now = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		touch_active = event.pressed
		touch_start = event.position
		touch_now = event.position
	elif event is InputEventMouseMotion and touch_active and touch_id == -1:
		touch_now = event.position

func _focus_lost() -> void:
	music.foreground=false
	if state == "running": toggle_pause()

func toggle_pause() -> void:
	if state == "running":
		state = "paused"
		touch_active = false
		touch_id = -1
		hud.show_pause()
	elif state == "paused":
		state = "running"
		hud.clear_modal()

func xp_needed() -> float:
	if level<20: return 5.0+(level-1)*10
	if level==20: return 795
	if level<40: return 195.0+(level-20)*13
	if level==40: return 2855
	return 455.0+(level-40)*16

func open_level_up() -> void:
	xp -= xp_needed()
	level += 1
	state = "levelup"
	touch_active = false
	touch_id = -1
	selected_options = roll_choices()
	hud.show_choices(selected_options)
	play_sound("level")

func roll_choices(excluded: Array = []) -> Array:
	var pool: Array = catalog.filter(func(u): return upgrade_available(u) and not excluded.has(str(u.id)))
	if pool.is_empty():
		return [{"id":"heal","name":"따뜻한 한 끼","icon":22,"kind":"bonus","description":"체력 30 회복","max":999},{"id":"coins","name":"해변의 보물","icon":27,"kind":"bonus","description":"해변 코인 25 획득","max":999}]
	var count := 4 if rng.randf()<maxf(0,1-1/luck()) else 3
	var chosen: Array = []
	var owned: Array=pool.filter(func(u):return upgrades.get(str(u.id),0)>0 or u.has("requires"))
	var owned_chance:=clampf(1+0.3*(2 if level%2==0 else 1)-1/luck(),0,1)
	for i in 2:
		if not owned.is_empty() and rng.randf()<owned_chance:
			var item: Dictionary=owned[rng.randi_range(0,owned.size()-1)]
			if not chosen.has(item): chosen.append(item)
	while chosen.size()<count and not pool.is_empty():
		var table: Array=[]
		for u in pool: table.append({"id":u.id,"weight":float(u.get("rarity",80))})
		var id:=weighted_id(table)
		var item: Dictionary=pool.filter(func(u):return str(u.id)==id)[0]
		pool.erase(item)
		if not chosen.has(item): chosen.append(item)
	return chosen

func upgrade_available(u: Dictionary) -> bool:
	var id:=str(u.id)
	if banished.has(id) or upgrades.get(id,0)>=int(u.max): return false
	if u.get("chest_only",false): return false
	if u.get("map_only",false) and upgrades.get(id,0)==0: return false
	if retired_weapons.has(id) or retired_weapons.has(str(u.get("weapon",""))): return false
	var req:=str(u.get("requires",""))
	if not req.is_empty() and upgrades.get(req,0)==0: return false
	if u.has("weapon") and (upgrades.get(str(u.weapon),0)>=8 or (evolved.has(str(u.weapon)) and not encounters.evolutions.get(str(u.weapon),{}).get("levelable",false))): return false
	if u.get("kind","")=="weapon" and upgrades.get(id,0)==0 and owned_items("weapon").size()>=6: return false
	if u.get("kind","")=="passive" and upgrades.get(id,0)==0 and owned_items("passive").size()>=6: return false
	return true

func owned_items(kind: String) -> Array:
	return catalog.filter(func(u):return u.get("kind","")==kind and upgrades.get(str(u.id),0)>0)

func reroll_choices() -> void:
	if state!="levelup" or rerolls<=0: return
	rerolls-=1
	var excluded:=selected_options.map(func(u):return str(u.id))
	selected_options=roll_choices(excluded)
	hud.show_choices(selected_options)

func skip_choices() -> void:
	if state!="levelup" or skips<=0: return
	skips-=1
	state="running"
	invulnerable=0.8
	hud.clear_modal()

func banish_choice(id: String) -> void:
	if state!="levelup" or banishes<=0: return
	if not selected_options.any(func(u):return str(u.id)==id): return
	banishes-=1
	banished.append(id)
	selected_options=roll_choices()
	hud.show_choices(selected_options)

func choose_upgrade(id: String) -> void:
	if state != "levelup": return
	if not selected_options.any(func(u): return str(u.id) == id): return
	if id == "heal": hp = minf(max_health(), hp + 30)
	elif id == "coins": round_coins+=int(25*greed())
	else:
		for u in selected_options:
			if str(u.id) == id: apply_upgrade(u)
	state = "running"
	selected_options.clear()
	invulnerable=0.8
	hud.clear_modal()
	play_sound("pick")

func finish(won: bool) -> void:
	if state != "running": return
	elapsed = minf(elapsed, ROUND_TIME)
	state = "won" if won else "lost"
	set_meta("finish_clock",scene_time)
	best_time = maxf(best_time, elapsed)
	harbor_coins += round_coins
	save_settings()
	touch_active = false
	if won: hud.show_end(true)
	else: hud.clear_modal()
	play_sound("win" if won else "lose")

func save_settings() -> void:
	if not persist_results: return
	var save := ConfigFile.new()
	save.set_value("records", "best", best_time)
	save.set_value("settings", "sound", sound_enabled)
	save.set_value("settings","effects_volume",presentation.volume)
	save.set_value("settings","ui_volume",presentation.ui_volume)
	save.set_value("settings","music_volume",music.volume)
	save.set_value("settings","reduced_motion",presentation.reduced_motion)
	save.set_value("settings","low_fx",presentation.low_fx)
	save.set_value("harbor","coins",harbor_coins)
	save.set_value("harbor","upgrades",harbor)
	save.save("user://tepo.cfg")

func weighted_id(table: Array, roll: float = -1.0) -> String:
	var total := 0.0
	for entry in table: total += float(entry.weight)
	var value := (rng.randf() if roll < 0 else clampf(roll,0,0.999999)) * total
	for entry in table:
		value -= float(entry.weight)
		if value < 0: return str(entry.id)
	return str(table[-1].id)

func check_miniboss() -> void:
	var config: Dictionary = encounters.miniboss
	while elite_check < config.checks.size() and elapsed >= float(config.checks[elite_check]):
		elite_check += 1
		var alive := enemies.filter(func(e): return e.elite and e.hp > 0).size()
		if elite_count >= int(config.max_total) or alive >= int(config.max_alive): continue
		if rng.randf() >= float(config.chance): continue
		if spawn_enemy(false,true):
			elite_count += 1
			banner = "중간보스 · " + str(config.name)
			banner_time = 3

func spawn_enemy(boss: bool = false, elite: bool = false, forced_kind: int = -1, event_spawn: bool = false) -> bool:
	if not boss and not elite:
		if enemies.size()>=232: return false
		if not event_spawn and enemies.filter(func(e):return not e.get("swarm",false)).size()>=180: return false
	var angle := rng.randf() * TAU
	var pos := player + Vector2.from_angle(angle) * rng.randf_range(1100, 1350)
	pos = pos.clamp(shore.PLAY.position+Vector2(40,40),shore.PLAY.end-Vector2(40,40))
	for tries in 20:
		if not shore.blocked(pos,25) and pos.distance_to(player) > 300: break
		pos = (player+Vector2.from_angle(rng.randf()*TAU)*1250).clamp(shore.PLAY.position+Vector2(40,40),shore.PLAY.end-Vector2(40,40))
	if shore.blocked(pos,25): return false
	var weights: Array = wave_data().weights
	var table: Array = []
	for i in weights.size(): table.append({"id":str(i),"weight":weights[i]})
	var kind := forced_kind if forced_kind>=0 else int(weighted_id(table))
	# Ranged creatures are a rare late pressure, with at most three alive.
	if kind==8 and not boss and not elite:
		if elapsed<480 or enemies.filter(func(e):return e.kind==8 and not e.boss and not e.elite and e.hp>0).size()>=3: kind=0
	var spec: Dictionary = encounters.creatures[kind]
	var health: float = (1200.0 if boss else (float(encounters.miniboss.hp) if elite else float(spec.hp))) * float(wave_data().health)*curse()
	var radius: float = 42.0 if boss else (23.0 if elite else float(spec.radius))
	var speed: float = 38.0 if boss else (70.0 if elite else float(spec.speed))
	next_enemy_id += 1
	enemies.append({"id":next_enemy_id, "pos":pos, "hp":health, "max_hp":health, "kind":kind,"elite":elite,"boss":boss,"swarm":event_spawn,"attack_cd":rng.randf_range(3.0,6.5), "radius":radius, "speed":speed*float(wave_data().speed)*curse(), "frozen":0.0, "slow":0.0, "warning":0.0, "hit":0.0, "orbit_hit":0.0, "knock":Vector2.ZERO, "phase":rng.randf() * TAU})
	return true

func spawn_swarm(event: Dictionary) -> void:
	var available:=mini(int(event.count),48-enemies.filter(func(e):return e.get("swarm",false) and e.hp>0).size())
	if available<=0: return
	var dir:=Vector2.from_angle(rng.randf()*TAU)
	var side:=dir.orthogonal()
	var half_view:=Vector2(640,400)/camera.zoom
	var reach:=absf(dir.x)*half_view.x+absf(dir.y)*half_view.y+140
	for i in available:
		var column:=i%8
		var row:=i/8
		var pos:=player-dir*(reach+row*42)+side*((column-3.5)*42)
		# Reject blocked/off-map entries instead of popping a pack onto the player.
		if not shore.PLAY.has_point(pos) or shore.blocked(pos,12): continue
		if spawn_enemy(false,false,int(event.kind),true):
			var e:Dictionary=enemies[-1]
			e.pos=pos
			e.rush_dir=dir
			e.rush_life=12.0
			e.hp=float(encounters.creatures[e.kind].hp)*(1+elapsed/900)
			e.max_hp=e.hp
			e.speed=float(encounters.creatures[e.kind].speed)
			e.contact_damage=6.0

func update_enemies(dt: float) -> void:
	if freeze_time > 0:
		for e in enemies:
			e.hit = maxf(0,e.hit-dt)
			e.orbit_hit = maxf(0,e.orbit_hit-dt)
		return
	for e in enemies:
		if e.hp <= 0: continue
		var to_player: Vector2 = player - e.pos
		var distance := to_player.length()
		if e.get("swarm",false):
			if e.frozen<=0: e.rush_life-=dt
			if e.rush_life<=0 or distance>2600:
				e.hp=0
				continue
		if distance>2600:
			# Previous-wave survivors remain nearby, but cannot recycle forever.
			if not e.elite and not e.boss and float(wave_data().weights[e.kind])<=0:
				e.hp=0
				continue
			for attempt in 12:
				var candidate: Vector2=(player+Vector2.from_angle(rng.randf()*TAU)*1250).clamp(shore.PLAY.position+Vector2(50,50),shore.PLAY.end-Vector2(50,50))
				if not shore.blocked(candidate,float(e.radius)) and candidate.distance_to(player)>900:
					e.pos=candidate
					break
			continue
		var dir := to_player / maxf(1.0, distance)
		if e.get("swarm",false): dir=e.rush_dir
		elif e.kind==7 and not e.elite and not e.boss: dir=dir.rotated(sin(scene_time*2+e.phase)*0.65)
		var speed: float = e.speed
		var human_ranged:bool=(e.elite or e.boss) and elapsed>=300
		var creature_ranged:bool=e.kind==8 and not e.elite and not e.boss and not e.get("swarm",false)
		if (human_ranged and e.elite or creature_ranged) and distance < 420: speed = 0
		e.frozen=maxf(0,e.get("frozen",0.0)-dt)
		e.slow=maxf(0,e.get("slow",0.0)-dt)
		e.exposed=maxf(0,e.get("exposed",0.0)-dt)
		if e.frozen>0: speed=0
		elif e.slow>0: speed*=0.5
		if e.kind==3 and not e.elite and not e.boss and fmod(scene_time+e.phase,4.5)<0.8: speed*=1.4
		var motion: Vector2 = (dir*speed+e.knock)*dt
		var next: Vector2 = shore.slide(e.pos,motion,14)
		if next.distance_squared_to(e.pos) < 0.1 and speed > 0:
			# Simple local detours keep people from walking through benches/walls.
			for a in [0.9,-0.9,1.55,-1.55]:
				var alternative: Vector2 = shore.slide(e.pos,dir.rotated(a)*speed*dt,14)
				if alternative.distance_squared_to(e.pos) > 0.1:
					next = alternative
					break
		var actually_moving:bool=next.distance_squared_to(e.pos)>0.01
		e.moving=actually_moving
		e.anim_clock=float(e.get("anim_clock",e.phase))+dt*(1.9 if actually_moving else 0.35)
		if e.boss and e.frozen<=0:
			var special_motion:Vector2=presentation.boss_motion(e,dt,dir)
			next=shore.slide(e.pos,(special_motion*(0.5 if e.slow>0 else 1.0)+e.knock)*dt,14)
		e.pos = next
		e.knock = e.knock.move_toward(Vector2.ZERO, dt * 750)
		e.hit = maxf(0, e.hit - dt)
		e.orbit_hit = maxf(0, e.orbit_hit - dt)
		e.attack_cd -= dt
		e.warning=maxf(0,0.85-e.attack_cd) if (human_ranged or creature_ranged) and distance<600 else 0.0
		if (human_ranged or creature_ranged) and distance < 600 and e.attack_cd <= 0 and e.frozen<=0:
			var shot_count := 3 if e.elite or e.boss else 1
			for j in shot_count:
				if enemy_shots.size() >= 28: break
				if creature_ranged and enemy_shots.filter(func(s):return not s.human).size()>=4: break
				presentation.sound("enemy_shot")
				enemy_shots.append({"pos":e.pos,"dir":dir.rotated((j-(shot_count-1)*0.5)*0.3),"life":4.5,"human":e.elite or e.boss})
			e.attack_cd = 6.5 if creature_ranged else (4.5 if not e.boss else 3.5)
		if distance < float(e.radius) + 21 and invulnerable <= 0:
			hp -= arsenal.block_damage(maxf(1, (24 if e.boss else float(e.get("contact_damage",12))) - armor()))
			invulnerable = 0.8
			shake = 5
			burst(player, Color("ed9e85"), 9)
			play_sound("hurt")
			presentation.player_hurt=0.25
	for i in range(enemy_shots.size()-1,-1,-1):
		var shot := enemy_shots[i]
		shot.pos += shot.dir * 190 * dt
		shot.life -= dt
		if shot.pos.distance_to(player) < 24 and invulnerable <= 0:
			hp -= arsenal.block_damage(maxf(1,10-armor()))
			invulnerable = 0.7
			shot.life = 0
			play_sound("hurt")
		if shot.life <= 0 or shore.blocked(shot.pos,2): enemy_shots.remove_at(i)

func snap_aim(direction: Vector2) -> Vector2:
	if direction.length_squared() < 0.001: return aim
	return Vector2.from_angle(roundf(direction.angle()/(TAU/16))*(TAU/16))

func update_aim() -> void:
	if manual_aim:
		aim = snap_aim(get_global_mouse_position()-player)
		return
	var best := facing
	var best_distance := 820.0
	for e in enemies:
		if e.hp <= 0: continue
		var offset: Vector2 = e.pos-player
		var distance := offset.length()
		var in_cone := absf(facing.angle_to(offset)) < deg_to_rad(65)
		if (in_cone or move_dir.length_squared()<0.01) and distance < best_distance:
			best_distance = distance
			best = offset
	aim = snap_aim(best)

func grid_key(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CELL), floori(pos.y / CELL))

func build_grid() -> void:
	enemy_grid.clear()
	for e in enemies:
		if e.hp <= 0: continue
		var key := grid_key(e.pos)
		if not enemy_grid.has(key): enemy_grid[key] = []
		enemy_grid[key].append(e)

func nearby(pos: Vector2, radius: float) -> Array:
	var result: Array = []
	var reach := ceili((radius + 70.0) / CELL)
	var cell := grid_key(pos)
	for y in range(-reach, reach + 1):
		for x in range(-reach, reach + 1):
			result.append_array(enemy_grid.get(cell + Vector2i(x, y), []))
	return result

func power() -> float:
	return 1.0+upgrades.get("power",0)*0.1+harbor.get("power",0)*0.05

func max_health() -> float:
	return 100*(1+upgrades.get("vitality",0)*0.2+maxi(0,upgrades.get("relic_left",0)-1)*0.05)+(50 if blessings.has("bastion") else 0)+harbor.get("vitality",0)*10

func recovery() -> float:
	return upgrades.get("regen",0)*0.2+maxi(0,upgrades.get("relic_left",0)-1)*0.1+(0.5 if blessings.has("healing") else 0)

func move_speed() -> float:
	return 1+upgrades.get("movespeed",0)*0.1+(0.15 if blessings.has("tempest") else 0)

func luck() -> float:
	return 1+upgrades.get("luck",0)*0.1+(0.5 if blessings.has("fortune") else 0)+harbor.get("luck",0)*0.1

func duration() -> float:
	return 1+upgrades.get("duration",0)*0.1+(0.2 if blessings.has("tide") else 0)

func projectile_speed() -> float:
	return 1+upgrades.get("projectilespeed",0)*0.1

func bonus_amount() -> int:
	return int(upgrades.get("amount",0))

func curse() -> float:
	return 1+upgrades.get("curse",0)*0.1+maxi(0,upgrades.get("relic_right",0)-1)*0.1

func greed() -> float:
	return 1+upgrades.get("greed",0)*0.1+(0.25 if blessings.has("fortune") else 0)

func growth() -> float:
	return 1+upgrades.get("growth",0)*0.08+(1 if level==20 or level==40 else 0)

func armor() -> float:
	return upgrades.get("armor",0)+(3 if blessings.has("bastion") else 0)

func crit_chance() -> float:
	return minf(1,(upgrades.get("crit",0)*0.05+(0.15 if blessings.has("stars") else 0))*luck())

func orbit_radius() -> float:
	return 150+maxf(0,area()-1)*32

func weapon_power(id: String) -> float:
	return power()*(1.75 if evolved.has(id) else 1.0)

func bowl_active() -> bool:
	return not arsenal.orbits.is_empty()

func kelp_reach() -> float:
	return float(arsenal.stats("kelp").radius)

func view_half() -> Vector2:
	return get_viewport_rect().size*0.5/camera.zoom

func wave_data() -> Dictionary:
	return encounters.waves[mini(29,int(elapsed/60))]

func check_stage_events() -> void:
	while boss_index<encounters.bosses.size() and elapsed>=float(encounters.bosses[boss_index].time):
		var event: Dictionary=encounters.bosses[boss_index]
		if spawn_enemy(true):
			var e: Dictionary=enemies[-1]
			e.hp=float(event.hp)*sqrt(maxf(1,level/5.0))
			e.max_hp=e.hp
			e.evolution_chest=float(event.time)>=600
			e.final=bool(event.final)
			e.pattern=boss_index
			e.portrait=[2,4,3,0,1,6][boss_index]
			e.special_cd=5.0
			boss_spawned=true
			boss_warning=3.6
			presentation.sound("warning",true)
			banner=str(event.name).strip_edges()+" 등장!"
			banner_time=4
		boss_index+=1
	while blessing_index<encounters.blessing_bosses.size() and elapsed>=float(encounters.blessing_bosses[blessing_index]):
		if spawn_enemy(false,true): enemies[-1].blessing=true
		blessing_index+=1
	while swarm_index<encounters.swarms.size() and elapsed>=float(encounters.swarms[swarm_index].time):
		var event: Dictionary=encounters.swarms[swarm_index]
		if float(event.chance)>=1 or rng.randf()<float(event.chance)/luck():
			spawn_swarm(event)
			banner="갯바람을 타고 몰려온다!"
			banner_time=2.5
		swarm_index+=1

func offer_blessing() -> void:
	var pool: Array=encounters.blessings.filter(func(b):return not blessings.has(str(b.id)))
	if pool.is_empty(): return
	pool.shuffle()
	selected_options=pool.slice(0,mini(4,pool.size()))
	state="blessing"
	hud.show_blessings(selected_options)

func choose_blessing(id: String) -> void:
	if state!="blessing" or not selected_options.any(func(b):return str(b.id)==id): return
	blessings.append(id)
	state="running"
	hud.clear_modal()

func area() -> float:
	return 1+upgrades.get("area",0)*0.1+(0.2 if blessings.has("tide") else 0)

func cooldown() -> float:
	return maxf(0.1,1-upgrades.get("haste",0)*0.08-(0.12 if blessings.has("tempest") else 0))

func update_weapons(dt: float) -> void:
	update_water_cannon(dt)
	arsenal.update(dt)

func update_water_cannon(dt: float) -> void:
	if water_time <= 0: return
	var active_dt := minf(dt,water_time)
	water_time = maxf(0,water_time-dt)
	if water_time<=0: presentation.sound("water_end",true)
	var config: Dictionary = encounters.water_cannon
	water_reach = float(config.range)
	# One shared center-line wall check per frame, with no new projectile entities.
	for step in range(20,int(water_reach)+1,20):
		if shore.blocked(player+aim*step,3):
			water_reach = float(step-10)
			break
	var spread := tan(deg_to_rad(float(config.half_angle_degrees)))
	for e in nearby(player,water_reach+50):
		if e.hp <= 0: continue
		var relative: Vector2 = e.pos-player
		var forward := relative.dot(aim)
		var side := absf(relative.dot(aim.orthogonal()))
		if forward > 0 and forward <= water_reach and side <= 12+forward*spread+float(e.radius):
			damage(e,float(config.damage_per_second)*active_dt*power(),aim*140*active_dt,false)

func damage(e: Dictionary, amount: float, knock: Vector2, can_crit: bool = true, source: String="water") -> void:
	if e.hp <= 0: return
	if can_crit and rng.randf()<crit_chance(): amount*=2
	presentation.record_hit(e,amount,source,knock)
	e.hp -= amount
	e.hit = 0.1
	e.knock += knock * (0.25 if e.boss else (1.5 if e.get("exposed",0)>0 else 1.0))
	if pops.size() < 18:
		pops.append({"pos":e.pos + Vector2(rng.randf_range(-10,10), -25), "life":0.65, "text":str(int(amount))})
	if e.hp <= 0:
		kills += 1
		burst(e.pos, Color("91c6b6"), 30 if e.boss else 5)
		add_gem(e.pos, 25 if e.boss else (10 if e.elite else int(encounters.creatures[e.kind].xp)))
		if e.get("blessing",false):
			chests.append({"pos":e.pos,"opened":false,"blessing":true})
		elif e.elite and rng.randf() < float(encounters.miniboss.drop_chance):
			spawn_pickup(e.pos, roll_loot(encounters.elite_loot))
		elif not e.elite and not e.boss and rng.randf() < float(encounters.water_cannon.normal_drop_chance):
			spawn_pickup(e.pos,"water")
		elif not e.elite and not e.boss and rng.randf()<0.03:
			spawn_pickup(e.pos,"coin")
		if e.boss:
			presentation.sound("boss_down",true)
			chests.append({"pos":e.pos,"opened":false,"boss":true,"born":elapsed,"can_evolve":bool(e.get("evolution_chest",false))})
			banner = "자리대장 퇴장! 황금 장비 상자를 획득하세요"
			banner_time = 3

func add_gem(pos: Vector2, value: int) -> void:
	if gems.size() >= 180:
		# Preserve XP by merging into the nearest drop instead of discarding it.
		var closest := 0
		var closest_dist := INF
		for i in gems.size():
			var dist: float = pos.distance_squared_to(gems[i].pos)
			if dist < closest_dist:
				closest_dist = dist
				closest = i
		gems[closest].value += value
	else:
		gems.append({"pos":pos, "value":value, "pulled":false})

func update_gems(dt: float) -> void:
	var radius: float = 100.0 * (1 + upgrades.get("magnet", 0) * 0.35)
	for i in range(gems.size() - 1, -1, -1):
		var gem := gems[i]
		var dist: float = gem.pos.distance_to(player)
		if dist < radius: gem.pulled = true
		if gem.pulled: gem.pos = gem.pos.move_toward(player, dt * 500)
		if gem.pos.distance_to(player) < 22:
			xp += gem.value*growth()
			gems.remove_at(i)
			if pickup_sound_cd <= 0:
				play_sound("pick")
				pickup_sound_cd = 0.12

func spawn_pickup(pos: Vector2, kind: String) -> void:
	if pickups.size() >= 64:
		var expendable:=pickups.find_custom(func(p):return str(p.kind).begins_with("food") or p.kind=="coin")
		if expendable<0: expendable=pickups.find_custom(func(p):return not str(p.kind).begins_with("relic_"))
		if expendable<0: return
		pickups.remove_at(expendable)
	pickups.append({"pos":pos,"kind":kind})

func open_chest(chest: Dictionary) -> void:
	if chest.opened: return
	chest.opened = true
	if chest.get("blessing",false):
		offer_blessing()
	elif chest.get("boss",false):
		grant_boss_chest(0,bool(chest.get("can_evolve",false)))
	else:
		spawn_pickup(chest.pos+Vector2(0,-20),roll_loot(encounters.field_loot))
	burst(chest.pos,Color("efcb76"),10)
	if not chest.get("boss",false): presentation.sound("chest_open",true)

func apply_pickup(kind: String) -> void:
	var sound_id: String="food" if kind.begins_with("food") else ("relic" if kind.begins_with("relic_") else ("water_start" if kind=="water" else kind))
	presentation.sound(sound_id,true)
	if kind.begins_with("relic_"):
		var before:=max_health()
		upgrades[kind]=mini(9,upgrades.get(kind,0)+1)
		hp+=max_health()-before
		banner=item_name(kind)+" · 닻 진화 유물"
		banner_time=3
		return
	match kind:
		"water":
			water_time = maxf(water_time,float(encounters.water_cannon.duration)*duration())
			water_reach = float(encounters.water_cannon.range)
			banner = "물대포! · %.0f초 연속 분사"%water_time
		"coin":
			round_coins+=maxi(1,roundi(greed()))
			play_sound("pick")
			return
		"food15", "food20", "food30":
			var healing := int(kind.trim_prefix("food"))*(2 if blessings.has("healing") else 1)
			var recovered := minf(float(healing),max_health()-hp)
			hp = minf(max_health(),hp+healing)
			banner = "따끈한 바다 간식 · 체력 +%d" % int(recovered)
		"magnet":
			for gem in gems: xp += gem.value*growth()
			gems.clear()
			banner = "자석 · 맵 전체의 경험치를 모두 회수!"
		"xp":
			xp += maxf(25,xp_needed()*1.5)
			banner = "큰 경험치 · 성장의 파도!"
		"freeze":
			freeze_time = 5.0
			banner = "시간 정지 · 적과 적의 투사체가 5초간 정지!"
		"wipe":
			var view := Rect2(camera.position-view_half(),view_half()*2)
			for e in enemies:
				if e.hp > 0 and view.grow(float(e.radius)).has_point(e.pos):
					damage(e,e.max_hp*0.1 if e.boss else e.hp,Vector2.ZERO,false,"pickup")
			flash_time = 0.4
			banner = "바다의 심판 · 화면 정리! 라운드 보스는 최대 체력의 10% 피해"
	banner_time = 3.0
	burst(player,Color("9fdfca"),15)

func apply_upgrade(item: Dictionary) -> void:
	var id := str(item.id)
	var before_hp:=max_health()
	upgrades[id] = upgrades.get(id,0)+1
	if id=="vitality": hp+=max_health()-before_hp
	if item.has("weapon"):
		var weapon := str(item.weapon)
		upgrades[weapon] = upgrades.get(weapon,0)+1
		if timers.has(weapon): timers[weapon]=0.0

func grant_boss_chest(forced_count: int = 0, can_evolve: bool = false) -> void:
	var count := forced_count if forced_count > 0 else roll_chest_count()
	last_boss_rewards.clear()
	last_reward_icons.clear()
	round_coins+=roundi(rng.randi_range(40,100)*greed())
	var evolved_this_chest:=false
	for i in count:
		if can_evolve and not evolved_this_chest:
			var options:=evolution_candidates()
			if not options.is_empty():
				var weapon:=str(options[rng.randi_range(0,options.size()-1)])
				perform_evolution(weapon)
				last_boss_rewards.append("진화 · "+str(encounters.evolutions[weapon].name))
				last_reward_icons.append(reward_icon(weapon))
				evolved_this_chest=true
				continue
		# Rebuild after each roll, allowing duplicates but never exceeding a cap.
		var pool := catalog.filter(func(u): return upgrade_available(u) and (u.has("requires") or upgrades.get(str(u.id),0)>0))
		if pool.is_empty():
			round_coins += int(25*greed())
			last_boss_rewards.append("해변 코인 +25")
			last_reward_icons.append(27)
		else:
			var item: Dictionary = pool[rng.randi_range(0,pool.size()-1)]
			apply_upgrade(item)
			last_boss_rewards.append(str(item.name)+" +1")
			last_reward_icons.append(int(item.icon))
	treasure_clock=0.0
	state = "treasure"
	touch_active = false
	touch_id = -1
	hud.show_treasure(last_boss_rewards)
	presentation.sound("chest_open",true)

func close_treasure() -> void:
	if state != "treasure" or treasure_clock<treasure_duration(): return
	state = "running"
	hud.clear_modal()

func next_supply_interval() -> float:
	# Custom supply containers, not VS equipment treasure chests.
	return maxf(30.0,rng.randf_range(45,65)/luck())

func reward_icon(id: String) -> int:
	for item in catalog:
		if str(item.id)==id: return int(item.icon)
	return 27

func treasure_duration() -> float:
	return 2.6+last_boss_rewards.size()*0.28

func update_rewards(dt: float) -> void:
	chests=chests.filter(func(c):return not c.opened)
	chest_timer -= dt
	if chest_timer <= 0 and chests.filter(func(c):return not c.opened and not c.get("boss",false) and not c.get("blessing",false)).size() < 6:
		for tries in 15:
			var pos := (player+Vector2(rng.randf_range(-850,850),rng.randf_range(-500,500))).clamp(shore.PLAY.position+Vector2(70,70),shore.PLAY.end-Vector2(70,70))
			if not shore.blocked(pos,26) and pos.distance_to(player)>160:
				chests.append({"pos":pos,"opened":false})
				break
		chest_timer = next_supply_interval()
	for chest in chests:
		if not chest.opened and chest.pos.distance_to(player) < 55:
			open_chest(chest)
			if state != "running": return
	for i in range(pickups.size()-1,-1,-1):
		if pickups[i].pos.distance_to(player) < 56:
			var kind: String = pickups[i].kind
			pickups.remove_at(i)
			apply_pickup(kind)

func burst(pos: Vector2, color: Color, count: int) -> void:
	for i in count:
		if particles.size() >= (30 if presentation.low_fx else 90): break
		particles.append({"pos":pos, "vel":Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(35, 155), "life":rng.randf_range(0.2, 0.55), "color":color})

func update_effects(dt: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		particles[i].pos += particles[i].vel * dt
		particles[i].life -= dt
		if particles[i].life <= 0: particles.remove_at(i)
	for i in range(pops.size() - 1, -1, -1):
		pops[i].pos.y -= dt * 35
		pops[i].life -= dt
		if pops[i].life <= 0: pops.remove_at(i)

func init_audio() -> void:
	# Foley clips and reserved UI channels are owned by presentation_v8.
	pass

func play_sound(id: String) -> void:
	presentation.sound(id)

func toggle_sound() -> void:
	sound_enabled = not sound_enabled
	if not sound_enabled:
		for audio in presentation.voices: audio.stop()
	save_settings()

func _draw() -> void:
	for gem in gems:
		if not on_screen(gem.pos,30): continue
		var pos: Vector2 = gem.pos
		atlas_draw(icons,25,pos,Vector2(23,27) if gem.value<3 else Vector2(30,34),8,4,0,Color.WHITE if gem.value<3 else Color("f8d89c"))
	for d in drops:
		if d.age < 0.65:
			draw_circle(d.pos, d.radius, Color(0.86,0.4,0.23,0.13))
			draw_arc(d.pos, d.radius, 0, TAU, 48, Color("cb8760"), 2, true)
	var actors: Array = [{"type":"player","pos":player}]
	for e in enemies:
		if e.hp>0 and on_screen(e.pos): actors.append({"type":"enemy","pos":e.pos,"data":e})
	for o in shore.objects:
		if on_screen(o.pos,270): actors.append({"type":"prop","pos":o.pos,"data":o})
	actors.sort_custom(func(a,b): return a.pos.y<b.pos.y)
	# Shadows share one pass so the common animation atlas can batch actors.
	for actor in actors:
		if actor.type=="prop": continue
		var width:float=108 if actor.type=="player" else (185 if actor.data.boss else (float(encounters.miniboss.size) if actor.data.elite else float(encounters.creatures[actor.data.kind].get("draw_size",92))))
		paint_ellipse(actor.pos+Vector2(0,8),Vector2(width*0.25,9),Color(0.12,0.2,0.16,0.22))
	for actor in actors:
		match actor.type:
			"player": draw_player()
			"enemy": draw_enemy(actor.data)
			"prop": draw_prop(actor.data)
	if water_time > 0: draw_water_cannon()
	for e in enemies:
		if e.hp<=0 or not e.boss or on_screen(e.pos,0): continue
		var offset: Vector2=e.pos-camera.position
		var limits:=view_half()-Vector2(70,100)
		var factor:=minf(limits.x/maxf(1,absf(offset.x)),limits.y/maxf(1,absf(offset.y)))
		var marker:=camera.position+offset*factor
		atlas_draw(icons,28,marker,Vector2(50,50),8,4,offset.angle()+PI/4)
		draw_string(hud.font,marker+Vector2(-25,38),"보스",HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("394d3b"))
	for chest in chests:
		if chest.opened: continue
		if chest.get("boss",false): draw_chest_marker(chest)
		if not on_screen(chest.pos): continue
		draw_arc(chest.pos+Vector2(0,4),30,0,TAU,24,Color(0.95,0.8,0.3,0.5),2,true)
		atlas_draw(effects,12,chest.pos+Vector2(0,-14),Vector2(85,85) if chest.get("boss",false) else Vector2(62,62),4,4)
		if chest.get("boss",false):
			draw_arc(chest.pos,40,0,TAU,32,Color("ffdf82"),3,true)
			draw_string(hud.font,chest.pos+Vector2(-43,-56),"장비 상자",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("fff0ba"))
		elif not chest.get("blessing",false):
			draw_string_outline(hud.font,chest.pos+Vector2(-24,-47),"보급품",HORIZONTAL_ALIGNMENT_LEFT,-1,19,4,Color("faf0d8"))
			draw_string(hud.font,chest.pos+Vector2(-24,-47),"보급품",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("334637"))
	for pickup in pickups:
		if on_screen(pickup.pos): draw_reward(pickup)
		elif str(pickup.kind).begins_with("relic_"):
			var offset:Vector2=pickup.pos-camera.position
			var limits:=view_half()-Vector2(65,100)
			var factor:=minf(limits.x/maxf(1,absf(offset.x)),limits.y/maxf(1,absf(offset.y)))
			var marker:Vector2=camera.position+offset*factor
			draw_item(45 if pickup.kind=="relic_left" else 46,marker,Vector2(40,40))
			draw_string(hud.font,marker+Vector2(-40,31),"왼고리" if pickup.kind=="relic_left" else "오른고리",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("334637"))
	for shot in enemy_shots:
		if not on_screen(shot.pos): continue
		atlas_draw(effects,9 if shot.get("human",false) else 8,shot.pos,Vector2(36,36),4,4,shot.dir.angle()+PI)
	arsenal.draw()
	presentation.draw()
	for p in particles:
		var c: Color = p.color
		c.a = minf(1, p.life * 4)
		atlas_draw(effects,10,p.pos,Vector2(17,17),4,4,0,c)
	for p in pops:
		draw_string_outline(hud.font,p.pos,p.text,HORIZONTAL_ALIGNMENT_LEFT,-1,24,3,Color(1,0.97,0.85,minf(1,p.life*3)))
		draw_string(hud.font,p.pos,p.text,HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color(0.2,0.3,0.25,minf(1,p.life*3)))
	if freeze_time>0:
		draw_rect(Rect2(camera.position-view_half(),view_half()*2),Color(0.3,0.6,0.85,0.08))
	if flash_time>0:
		draw_rect(Rect2(camera.position-view_half(),view_half()*2),Color(0.95,1.0,0.8,flash_time*0.7))
	if touch_active and state == "running":
		var screen_origin := camera.position-view_half()
		draw_circle(screen_origin + touch_start, 65, Color(1,1,1,0.1))
		draw_arc(screen_origin + touch_start, 65, 0, TAU, 40, Color(1,1,1,0.35), 2, true)
		draw_circle(screen_origin + touch_start + (touch_now-touch_start).limit_length(65), 24, Color(1,1,1,0.3))

func draw_water_cannon() -> void:
	var origin:=player+Vector2(0,-24)
	var length_value:=maxf(30,water_reach)
	var width:=80+length_value*0.4
	atlas_draw(effects,5,origin+aim*(length_value*0.5),Vector2(length_value,width),4,4,aim.angle(),Color(1,1,1,0.8+sin(scene_time*24)*0.12))
	for n in 4:
		var phase:=fmod(elapsed*2.8+n*0.25,1.0)
		atlas_draw(effects,4,origin+aim*length_value*phase,Vector2(40+phase*55,30+phase*width*0.5),4,4,aim.angle(),Color(0.8,0.95,0.9,0.65*(1-phase)))

func draw_chest_marker(chest: Dictionary) -> void:
	var offset:Vector2=chest.pos-camera.position
	var limits:Vector2=view_half()-Vector2(95,170)
	var factor:float=minf(1.0,minf(limits.x/maxf(1,absf(offset.x)),limits.y/maxf(1,absf(offset.y))))
	var marker:Vector2=chest.pos+Vector2(0,-110+sin(scene_time*3.5)*10)
	var direction:=Vector2.DOWN
	if factor<1:
		marker=camera.position+offset*factor
		direction=offset.normalized()
		marker+=Vector2(0,sin(scene_time*3.5)*8)
	var side:Vector2=direction.orthogonal()
	var points:=PackedVector2Array([marker+direction*28,marker-direction*5+side*25,marker-direction*5+side*11,marker-direction*34+side*11,marker-direction*34-side*11,marker-direction*5-side*11,marker-direction*5-side*25])
	draw_colored_polygon(points,Color("ffdc7e"))
	points.append(points[0])
	draw_polyline(points,Color("405a48"),4,true)
	draw_string_outline(hud.font,marker+Vector2(-46,-48),"보물 상자",HORIZONTAL_ALIGNMENT_LEFT,-1,24,5,Color("faf0d8"))
	draw_string(hud.font,marker+Vector2(-46,-48),"보물 상자",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("334637"))

func draw_reward(reward: Dictionary) -> void:
	var index: int={"water":21,"magnet":24,"xp":25,"freeze":23,"wipe":26,"food15":22,"food20":22,"food30":6,"coin":27,"relic_left":45,"relic_right":46}[reward.kind]
	var important:bool=reward.kind!="coin"
	var center:Vector2=reward.pos+Vector2(0,-12+sin(scene_time*3)*5)
	paint_ellipse(reward.pos+Vector2(0,16),Vector2(30,10),Color(0.12,0.2,0.16,0.3))
	if important:
		draw_circle(center,43,Color(0.99,0.94,0.73,0.7))
		draw_arc(center,44,0,TAU,24,Color("42685c"),3,true)
		draw_arc(center,48,scene_time,scene_time+1.5,12,Color("ffdc7e"),4,true)
	draw_item(index,center,Vector2.ONE*(76 if important else 54))
	if important:
		var text:String={"water":"물대포","magnet":"자석","xp":"큰 경험치","freeze":"시간 정지","wipe":"바다의 심판","food15":"회복","food20":"회복","food30":"회복","relic_left":"왼고리","relic_right":"오른고리"}.get(reward.kind,"")
		draw_string_outline(hud.font,center+Vector2(-35,65),text,HORIZONTAL_ALIGNMENT_LEFT,-1,21,5,Color("faf0d8"))
		draw_string(hud.font,center+Vector2(-35,65),text,HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("334637"))

func draw_player() -> void:
	var direction := facing if move_dir.length_squared()>0.01 else aim
	var sector := posmod(roundi(direction.angle()/(TAU/8)),8)
	# The generated front diagonals face opposite to their requested sheet order.
	var index: int = [6,1,0,7,2,3,4,5][sector]
	var motion:="walk" if move_dir.length_squared()>0.01 else "idle"
	if presentation.player_hurt>0: motion="hurt"
	var tint:=Color(1,0.75,0.7) if invulnerable>0 and sin(scene_time*35)>0 else Color.WHITE
	var dead:bool=state=="lost"
	var death_age:float=minf(0.5,scene_time-float(get_meta("finish_clock",scene_time))) if dead else 0.0
	var recoil:Vector2=-combat_fx.recoil*sin(PI*combat_fx.recoil_time/0.12)
	presentation.rig(hero_atlas,index,player+Vector2(0,20)+recoil,Vector2(108,108),"hero",motion,presentation.walk_clock,tint,2,death_age*2)
	if state in ["running","paused","levelup","treasure","blessing"]:
		var bar_pos:=player+Vector2(-48,35)
		draw_style_box(hud.style(Color("3d5040"),5),Rect2(bar_pos-Vector2(2,2),Vector2(100,14)))
		draw_style_box(hud.style(Color("e59b7c"),4,Color("e59b7c")),Rect2(bar_pos,Vector2(96*clampf(hp/max_health(),0,1),10)))
		if water_time>0: draw_string(hud.font,player+Vector2(-65,77),"물대포 %.0f초"%ceilf(water_time),HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("315f6b"))
		elif freeze_time>0: draw_string(hud.font,player+Vector2(-65,77),"시간 정지 %.0f초"%ceilf(freeze_time),HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("315f6b"))

func draw_cell(atlas: Texture2D, index: int, rect: Rect2, tint: Color=Color.WHITE) -> void:
	if not atlas: return
	var cell := Vector2(atlas.get_width()/4.0,atlas.get_height()/2.0)
	var source := Rect2(Vector2(index%4,index/4)*cell,cell)
	draw_texture_rect_region(atlas,rect,source,tint)

func on_screen(pos: Vector2, margin: float=130.0) -> bool:
	return absf(pos.x-camera.position.x)<view_half().x+margin and absf(pos.y-camera.position.y)<view_half().y+margin

func draw_prop(o: Dictionary) -> void:
	if not on_screen(o.pos,270): return
	var size_value: Vector2 = o.size
	var visual:=Rect2(o.pos-Vector2(size_value.x/2,size_value.y-15),size_value)
	var tint:=Color(1,1,1,0.4) if o.pos.y>player.y and visual.has_point(player-Vector2(0,40)) else Color.WHITE
	draw_cell(shore.props,o.index,visual,tint)

func paint_ellipse(pos: Vector2, scale_value: Vector2, color: Color) -> void:
	draw_set_transform(pos, 0, scale_value)
	draw_circle(Vector2.ZERO, 1, color)
	draw_set_transform(Vector2.ZERO)

func roll_loot(table: Array) -> String:
	var adjusted: Array=[]
	for item in table:
		var weight:=float(item.weight)
		if str(item.id) in ["water","magnet","freeze","wipe"]: weight*=luck()
		adjusted.append({"id":item.id,"weight":weight})
	return weighted_id(adjusted)

func buy_harbor(id: String) -> void:
	if state!="title" or not harbor.has(id): return
	var rank:=int(harbor[id])
	var cost:=(rank+1)*100
	if rank>=3 or harbor_coins<cost: return
	harbor_coins-=cost
	harbor[id]=rank+1
	save_settings()
	hud.show_harbor()

func return_to_harbor() -> void:
	state="title"
	hud.show_start()

func draw_enemy(e: Dictionary) -> void:
	if not on_screen(e.pos): return
	var size_value:float=185 if e.boss else (float(encounters.miniboss.size) if e.elite else float(encounters.creatures[e.kind].get("draw_size",92)))
	presentation.enemy_visual(e)
	if e.elite or e.boss:
		draw_rect(Rect2(e.pos+Vector2(-46,-size_value+4),Vector2(92,6)),Color("3e342c"))
		draw_rect(Rect2(e.pos+Vector2(-46,-size_value+4),Vector2(92*maxf(0,e.hp/e.max_hp),6)),Color("df9d5c"))
		if e.boss:
			var pattern_name:String=["자리 밀치기","소음 확산","쓰레기 투척"][int(e.get("pattern",0))%3]
			draw_string(hud.font,e.pos+Vector2(-70,-size_value-8),pattern_name,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("755038"))

func draw_bowl(pos: Vector2, scale_value: float) -> void:
	paint_ellipse(pos+Vector2(0,14),Vector2(26,8)*scale_value,Color(0.1,0.2,0.13,0.15))
	atlas_draw(effects,1,pos+Vector2(0,-8),Vector2(70,70)*minf(1.5,scale_value),4,4)

func draw_tetrapod(pos: Vector2,scale_value: float,_color: Color) -> void:
	atlas_draw(effects,3,pos,Vector2(130,130)*scale_value,4,4)

func draw_wave(w: Dictionary) -> void:
	if not on_screen(w.pos,300): return
	var width: float=w.width*(1+w.age*0.2)
	atlas_draw(effects,2,w.pos,Vector2(110,width),4,4,w.dir.angle(),Color(1,1,1,minf(1,w.life*2)))

func evolution_candidates() -> Array:
	var result: Array=[]
	for id in encounters.evolutions:
		var recipe:Dictionary=encounters.evolutions[id]
		if evolved.has(id): continue
		var ready:=true
		if recipe.has("weapons"):
			for weapon in recipe.weapons:
				if upgrades.get(str(weapon),0)<8: ready=false
		else: ready=upgrades.get(id,0)>=8
		if recipe.has("passive") and upgrades.get(str(recipe.passive),0)<1: ready=false
		for passive in recipe.get("passives",{}):
			if upgrades.get(passive,0)<int(recipe.passives[passive]): ready=false
		if ready: result.append(id)
	return result

func perform_evolution(id: String) -> void:
	var recipe:Dictionary=encounters.evolutions[id]
	for weapon in recipe.get("weapons",[]):
		retired_weapons.append(str(weapon))
		upgrades.erase(str(weapon))
		upgrades.erase(str(weapon)+"_level")
		bullets=bullets.filter(func(b):return b.weapon!=weapon)
		arsenal.pending=arsenal.pending.filter(func(b):return b.weapon!=weapon)
		arsenal.zones=arsenal.zones.filter(func(z):return z.weapon!=weapon)
	if recipe.has("weapons"): upgrades[id]=1
	evolved[id]=true
	timers[id]=0.0

func item_name(id: String) -> String:
	if id=="water": return "물대포"
	if id=="pickup": return "바다의 심판"
	for u in catalog:
		if str(u.id)==id: return str(u.name)
	return id

func evolution_hint(u: Dictionary) -> String:
	var id:=str(u.get("weapon",u.id))
	if encounters.evolutions.has(id):
		var recipe:Dictionary=encounters.evolutions[id]
		if recipe.has("weapons"): return "합체 · "+" + ".join(recipe.weapons.map(func(w):return item_name(w)+" Lv8"))+(" + 구명튜브" if recipe.has("passive") else "")
		if recipe.has("passives"): return "진화 · 왼고리9 + 오른고리9"
		var passive:=str(recipe.passive)
		return "진화 · %s (%s)"%[item_name(passive),"보유" if upgrades.get(passive,0)>0 else "미보유"]
	for union in encounters.evolutions.values():
		if id in union.get("weapons",[]): return "합체 재료 · "+str(union.name)
	var linked:Array=[]
	for recipe_id in encounters.evolutions:
		var recipe:Dictionary=encounters.evolutions[recipe_id]
		if str(recipe.get("passive",""))==id or recipe.get("passives",{}).has(id): linked.append(str(recipe.name))
	return "진화 · "+" / ".join(linked) if not linked.is_empty() else "공용 보조 능력"

func roll_chest_count(roll: float = -1.0) -> int:
	var r:=rng.randf() if roll<0 else roll
	if r<minf(1,0.03*luck()): return 5
	var second:=rng.randf()
	if second<minf(1,0.10*luck()): return 3
	return 1

func stats_rows() -> Array:
	return [["최대 체력","%d"%max_health(),19],["초당 회복","%.1f"%recovery(),11],["방어력","+%d"%armor(),9],["이동속도","+%d%%"%roundi((move_speed()-1)*100),13],["공격력","+%d%%"%roundi((power()-1)*100),6],["공격 범위","+%d%%"%roundi((area()-1)*100),8],["투사체 속도","+%d%%"%roundi((projectile_speed()-1)*100),16],["지속시간","+%d%%"%roundi((duration()-1)*100),14],["추가 발사","+%d"%bonus_amount(),17],["쿨타임","-%d%%"%roundi((1-cooldown())*100),7],["행운","+%d%%"%roundi((luck()-1)*100),12],["경험치","+%d%%"%roundi((growth()-1)*100),15],["골드","+%d%%"%roundi((greed()-1)*100),18],["적 강화","+%d%%"%roundi((curse()-1)*100),26],["획득 반경","%d"%roundi(100*(1+upgrades.get("magnet",0)*0.35)),10],["치명타","%d%%"%roundi(crit_chance()*100),5],["남은 부활","%d"%maxi(0,upgrades.get("revive",0)-revivals_used),20]]

func upgrade_preview(u: Dictionary) -> String:
	var id:=str(u.id)
	if u.get("kind","")=="passive":
		var current:int=upgrades.get(id,0)
		var unit:="" if id in ["armor","amount","revive"] else (" HP/초" if id=="regen" else "%")
		return "%s  %+.1f%s → %+.1f%s"%[u.stat,current*float(u.step),unit,(current+1)*float(u.step),unit]
	var weapon:=str(u.get("weapon",id))
	if not encounters.weapon_profiles.has(weapon): return str(u.get("description",""))
	var level_before:int=upgrades.get(weapon,0)
	var a:Dictionary=arsenal.stats(weapon,maxi(1,level_before))
	var b:Dictionary=arsenal.stats(weapon,level_before+1)
	if weapon=="anchor": return "방어 충전 %d회 · 발사 수 영향 없음\n충전 주기 %.1f → %.1f초"%[1+int(b.level>=3)+int(b.level>=6),a.cooldown,b.cooldown]
	if weapon=="heat": return "주기 %.0f → %.0f초 · 보스 제외\n전리품 소멸 주의 · 행운으로 보존"%[a.cooldown,b.cooldown]
	return "피해 %d → %d · %s %d → %d\n주기 %.2f → %.2f초"%[0 if level_before==0 else a.damage,b.damage,"개수" if "개수" in b.affected else "범위",a.amount if "개수" in b.affected else a.radius,b.amount if "개수" in b.affected else b.radius,a.cooldown,b.cooldown]

func icon_region(index: int) -> Rect2:
	var cell:=Vector2(icons.get_width()/8.0,icons.get_height()/4.0)
	# Centers measured from the four painted alpha bands, not an assumed uniform grid.
	var row_centers: Array[float]=[153.5,360.0,560.0,753.0]
	var center_y: float=row_centers[index/8]*icons.get_height()/887.0
	return Rect2(Vector2((index%8)*cell.x,center_y-cell.y/2),cell)

func atlas_draw(texture: Texture2D,index: int,pos: Vector2,size: Vector2,columns: int,rows: int,angle: float=0,tint: Color=Color.WHITE) -> void:
	if not texture: return
	var cell:=Vector2(texture.get_width()/float(columns),texture.get_height()/float(rows))
	var source:=icon_region(index) if texture==icons else Rect2(Vector2(index%columns,index/columns)*cell,cell)
	draw_set_transform(pos,angle)
	draw_texture_rect_region(texture,Rect2(-size/2,size),source,tint)
	draw_set_transform(Vector2.ZERO)


func item_atlas(index: int) -> Texture2D:
	return arsenal_icons if index>=32 else icons

func item_region(index: int) -> Rect2:
	if index<32: return icon_region(index)
	# Generated art has irregular painted bands. Read each whole sprite, not a grid cut.
	var bounds:Array=[Rect2(30,66,280,216),Rect2(349,56,256,229),Rect2(683,71,213,222),Rect2(954,37,270,264),Rect2(52,376,235,191),Rect2(332,327,282,281),Rect2(634,340,296,239),Rect2(953,347,281,243),Rect2(24,701,283,144),Rect2(326,701,303,167),Rect2(658,624,254,291),Rect2(948,659,284,226),Rect2(29,910,305,310),Rect2(382,924,204,281),Rect2(689,924,206,278),Rect2(943,955,297,248)]
	var rect:Rect2=bounds[index-32].grow(7)
	var scale_value:=Vector2(arsenal_icons.get_width()/1254.0,arsenal_icons.get_height()/1254.0)
	return Rect2(rect.position*scale_value,rect.size*scale_value)

func draw_item(index: int, pos: Vector2, size: Vector2, angle: float=0, tint: Color=Color.WHITE) -> void:
	var source:=item_region(index)
	if is_equal_approx(size.x,size.y):
		var factor:=minf(size.x/source.size.x,size.y/source.size.y)
		size=source.size*factor
	draw_set_transform(pos,angle)
	draw_texture_rect_region(item_atlas(index),Rect2(-size/2,size),source,tint)
	draw_set_transform(Vector2.ZERO)
