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
	var p=g.presentation
	check(p.clips.size()==59,"weapon, interface and new collision effect clips")
	check(p.voices.size()==12,"voice count bounded including reserved UI channels")
	var a:Array=p.mesh("hero","walk",0).surface_get_arrays(0)
	var b:Array=p.mesh("hero","walk",2).surface_get_arrays(0)
	for i in 13*5:
		check(a[Mesh.ARRAY_VERTEX][i]==b[Mesh.ARRAY_VERTEX][i],"pot/head region must remain rigid across phases")
	check(a[Mesh.ARRAY_VERTEX][-1]!=b[Mesh.ARRAY_VERTEX][-1],"legs must articulate instead of whole-image bobbing")
	for y in 10:
		for x in range(3,10):
			check(a[Mesh.ARRAY_VERTEX][y*13+x]==b[Mesh.ARRAY_VERTEX][y*13+x],"central face and body identity region remains unchanged")
	for direction in 8:
		var uv:Array=p.uv_mesh("hero","walk",0,direction,2).surface_get_arrays(0)
		for coord in uv[Mesh.ARRAY_TEX_UV]:
			check(coord.x>=float(direction%4)/4-0.001 and coord.x<=float(direction%4+1)/4+0.001,"direction UV horizontal bounds")
			check(coord.y>=float(direction/4)/2-0.001 and coord.y<=float(direction/4+1)/2+0.001,"direction UV vertical bounds")
	g.enemies.clear()
	g.spawn_enemy(false,false,0)
	var e:Dictionary=g.enemies[0]
	e.hp=10
	g.damage(e,100,Vector2.ZERO,false,"chain")
	check(p.damage_totals.chain==10,"damage statistics exclude overkill")
	check(p.ghosts.size()==1,"death spawns one bounded visual, not a new enemy")
	g.damage(e,100,Vector2.ZERO,false,"chain")
	check(p.damage_totals.chain==10 and p.ghosts.size()==1,"dead enemy cannot add duplicate damage/death")
	p.tick(1)
	check(p.ghosts.is_empty(),"death visuals expire")
	for i in 100: p.add_impact(g.player,"sand",true)
	check(p.impacts.size()<=32,"impact cap")
	g.spawn_enemy(true)
	var boss:Dictionary=g.enemies[-1]
	boss.pattern=0
	boss.special_cd=1.1
	var pos:Vector2=g.player
	var velocity:Vector2=p.boss_motion(boss,0.2,Vector2.RIGHT)
	check(boss.locked and velocity==Vector2.ZERO and boss.target_pos==pos,"charge has stationary one-second locked warning")
	p.boss_motion(boss,1,Vector2.DOWN)
	check(boss.charging>0 and boss.locked_dir==Vector2.RIGHT,"charge must not retarget after warning")
	boss.pattern=2
	boss.charging=0
	boss.special_cd=0
	p.boss_motion(boss,0.1,Vector2.RIGHT)
	check(p.boss_hazards.size()==3,"throw pattern creates exactly three delayed hazard circles")
	g.freeze_time=1
	var lifetime:float=p.boss_hazards[0].life
	p.tick(0.5)
	check(p.boss_hazards[0].life==lifetime,"time-stop also freezes boss hazards")
	g.start_game()
	check(p.damage_totals.is_empty() and p.boss_hazards.is_empty(),"restart clears presentation and statistics")
	g.hud.show_settings()
	check(g.hud.modal.find_children("*","HSlider",true,false).size()==3,"independent music, effect and interface volume controls")
	var rewards:Array[String]=["진화 · 모래폭풍","추가 강화","추가 강화","추가 강화","추가 강화"]
	g.last_boss_rewards=rewards
	g.last_reward_icons.assign([0,1,2,3,4])
	g.hud.show_treasure(rewards)
	check(g.hud.modal.find_children("*","Button",true,false).size()==1,"five rewards share one continue control")
	print("PRESENTATION: %d errors. Rigid identity, eight directions, articulated limbs, audio channels, actual damage, death, warning locks, freeze, resets and settings."%errors)
	g.queue_free()
	await process_frame
	quit(1 if errors else 0)
