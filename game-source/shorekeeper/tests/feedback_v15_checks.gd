extends SceneTree
var errors:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok: errors+=1; push_error("FEEDBACK15: "+message)
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.persist_results=false
	g.sound_enabled=false
	g.start_game()
	g.enemies.clear()
	g.gems.clear()
	# Magnet must preserve every XP value until the visible travelling gem arrives.
	g.add_gem(g.player+Vector2(4500,0),7)
	g.add_gem(g.player+Vector2(-600,300),11)
	var initial:float=g.xp
	g.apply_pickup("magnet")
	check(g.gems.size()==2 and g.xp==initial,"magnet never grants XP before arrival")
	var far_start:Vector2=g.gems[0].pos
	g.update_gems(0.05)
	check(g.gems[0].pos.distance_to(g.player)>far_start.distance_to(g.player),"magnet first lifts gems outward")
	for n in 160: g.update_gems(0.05)
	check(g.gems.is_empty() and is_equal_approx(g.xp,initial+18*g.growth()*1.7),"all map XP arrives once, with current growth applied")
	g.update_gems(0.1)
	check(is_equal_approx(g.xp,initial+18*g.growth()*1.7),"no duplicate magnet reward")
	g.gems.clear()
	for n in 250: g.add_gem(g.player+Vector2(500+n*5,0),1)
	check(g.gems.size()==180,"existing XP cap/merge retained")
	g.apply_pickup("magnet")
	for n in 140: g.update_gems(0.05)
	check(g.gems.is_empty() and is_equal_approx(g.xp,initial+268*g.growth()*1.7),"merged magnet gems retain all XP")
	# Dash is fixed-duration, collision-swept, with state/cooldown guards.
	var clear:=Vector2(6000,4000)
	for y in range(3000,5000,80):
		for x in range(5000,7000,80):
			if not g.shore.blocked(Vector2(x,y),240): clear=Vector2(x,y); break
	g.player=clear
	check(g.try_dash(Vector2.RIGHT),"ready dash starts")
	check(not g.try_dash(Vector2.LEFT),"dash cannot stack or restart")
	check(g.invulnerable>=0.22,"brief contact protection covers the dash")
	for n in 4: g.update_player_motion(0.045)
	check(g.player.distance_to(clear)>120 and g.player.distance_to(clear)<=190,"dash travels a short bounded distance")
	check(g.dash_time<=0.001 and g.dash_cooldown>3.7,"duration and cooldown use separate clocks")
	g.state="paused"
	check(not g.try_dash(Vector2.RIGHT),"paused input cannot dash")
	var cooldown:float=g.dash_cooldown
	await process_frame
	check(g.dash_cooldown==cooldown,"paused game does not consume cooldown")
	g.state="running"
	g.dash_cooldown=0
	# Find an actual obstacle boundary; repeated small sweeps must not tunnel.
	var boundary:=Vector2.ZERO
	for object in g.shore.objects:
		if object.rect.size.x>65:
			boundary=object.rect.get_center()
			break
	check(boundary!=Vector2.ZERO,"collision fixture exists")
	if boundary!=Vector2.ZERO:
		g.player=boundary+Vector2(-160,0)
		if not g.shore.blocked(g.player,18):
			g.try_dash(Vector2.RIGHT)
			for n in 4: g.update_player_motion(0.05)
			check(not g.shore.blocked(g.player,18),"dash cannot penetrate a map obstacle")
	g.hud.refresh()
	check("대시" in g.hud.dash_button.text and g.hud.dash_bar.visible,"cooldown HUD is visible in combat")
	check(g.presentation.voices.size()==14,"XP has two dedicated voices within a fixed total budget")
	check(g.presentation.clips.has("xp_collect") and g.presentation.clips.has("dash"),"new sound cues are loaded")
	g.start_game()
	check(g.dash_cooldown==0 and g.dash_time==0 and g.dash_ghosts.is_empty() and g.xp_flashes.is_empty(),"restart clears motion/collection state")
	print("FEEDBACK15: %d errors. Magnet conservation/travel, dash state/collision, cooldown HUD and audio routing."%errors)
	g.queue_free()
	await process_frame
	quit(1 if errors else 0)
