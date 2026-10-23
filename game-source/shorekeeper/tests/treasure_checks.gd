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
	for id in g.presentation.clips:
		check(g.presentation.clips[id] is AudioStreamWAV,"real exported WAV for "+id)
	check(g.presentation.clips.size()==59,"59 original sound assets")
	g.upgrades={"sand":1}
	for i in 500:
		var delay:float=g.next_supply_interval()
		check(delay>=45 and delay<=65,"base supply interval is 45–65s")
	g.upgrades.luck=5
	for i in 100: check(g.next_supply_interval()>=30,"luck cannot exceed supply frequency cap")
	g.upgrades={"sand":1}
	for count in [1,3,5]:
		g.grant_boss_chest(count,false)
		check(g.last_reward_icons.size()==count and g.last_boss_rewards.size()==count,"icons match granted reward count")
		var coins:int=g.round_coins
		var snapshot:Dictionary=g.upgrades.duplicate()
		g.close_treasure()
		check(g.state=="treasure","cannot dismiss before reveal finishes")
		var show=g.hud.modal.find_children("*","Node2D",true,false)[0]
		for i in 50:
			g.treasure_clock=i*0.1
			show._process(0.1)
		check(g.round_coins==coins and g.upgrades==snapshot,"slot animation never grants or rerolls rewards")
		check(not show.confirm.disabled,"continue unlocks after final reveal")
		check(show.stopped.all(func(v):return v),"every orb lands")
		g.close_treasure()
		check(g.state=="running","continues after reveal")
	g.grant_boss_chest(1,false)
	var previous=g.hud.modal.find_children("*","Node2D",true,false)[0]
	g.grant_boss_chest(5,false)
	check(previous.reward_texts.size()==1 and previous.reward_icons.size()==1,"retiring reveal owns an immutable reward snapshot")
	check(not g.hud.modal.is_ancestor_of(previous),"old reveal retires before a replacement draws")
	g.start_game()
	g.elapsed=300
	g.check_stage_events()
	check(g.boss_warning>3,"scheduled boss triggers warning")
	var boss:Dictionary=g.enemies.filter(func(e):return e.boss)[0]
	g.damage(boss,boss.hp+1,Vector2.ZERO)
	check(g.chests.any(func(c):return c.get("boss",false)),"boss drops guaranteed equipment chest")
	g.start_game()
	check(g.boss_warning==0 and g.treasure_clock==0,"restart clears warning and reveal")
	print("TREASURE: %d errors. Supply cadence, 59 WAV assets, 1/3/5 immutable reveals, finish gate, boss warning and chest drop."%errors)
	g.queue_free()
	await process_frame
	quit(1 if errors else 0)
