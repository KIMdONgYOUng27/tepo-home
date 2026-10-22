extends RefCounted

# The original painted pixels are the identity source. Cached UV meshes animate
# limbs independently; no frame generation, recolouring, or mirrored accessories.
var g: Node2D
var meshes: Dictionary={}
var ghosts: Array[Dictionary]=[]
var impacts: Array[Dictionary]=[]
var damage_totals: Dictionary={}
var equipped_seconds: Dictionary={}
var sound_clocks: Dictionary={}
var voices: Array[AudioStreamPlayer]=[]
var clips: Dictionary={}
var volume:=0.65
var ui_volume:=0.7
var reduced_motion:=false
var low_fx:=false
var walk_clock:=0.0
var player_hurt:=0.0
var frame_samples: Array[float]=[]
var frame_accumulator:=0.0
var boss_hazards: Array[Dictionary]=[]
var sample_clock:=0.0
var walk_sheet: Texture2D
var motion_sheets: Dictionary={}
var walk_rows: Dictionary={}
var bake_viewport: SubViewport
var input_started:=0
var input_samples: Array[float]=[]

func reset() -> void:
	for collection in [ghosts,impacts,boss_hazards,frame_samples,input_samples]: collection.clear()
	input_started=0
	damage_totals.clear()
	equipped_seconds.clear()
	walk_clock=0
	player_hurt=0
	frame_accumulator=0
	sample_clock=0
	sound_clocks.clear()
	for voice in voices: voice.stop()

func setup() -> void:
	if DisplayServer.get_name()!="headless": RenderingServer.frame_post_draw.connect(input_frame_finished)
	for i in 12:
		var voice:=AudioStreamPlayer.new()
		g.add_child(voice)
		voices.append(voice)
	for id in ["sand","pearl","bowl","kelp","chain","shell","snack","wave","rain","stone","tetra","heat","gull_white","gull_dark","gull_union","feather","gust","wing_union","anchor","water","hit","kill","pick","hurt","level","drop","chest","evolve","win","lose","ui","warning","impact_light","impact_heavy","wing_drop"]:
		clips[id]=load("res://assets/audio/%s.wav"%id)
	for id in ["food", "magnet", "freeze", "wipe", "xp", "coin", "relic", "revive", "boss_down", "chest_open", "reel_tick", "reel_stop", "treasure_1", "treasure_3", "treasure_5", "water_start", "water_end", "enemy_shot", "bug_die", "shell_die", "kelp_die", "quad_die", "jelly_die", "human_die"]:
		clips[id]=load("res://assets/audio/%s.wav"%id)
	# Prebuild meshes once, outside combat. Every instance shares the same mesh.
	for profile in ["hero","bug","shell","kelp","quad","jelly","human"]:
		for state in ["idle","walk","attack","hurt"]:
			for phase in 8: mesh(profile,state,phase)
	for index in 8:
		for state in ["idle","walk","attack","hurt"]:
			for phase in 8:
				uv_mesh("hero",state,phase,index,2)
				uv_mesh("human",state,phase,index,2)
	for kind in 9:
		var profile:String=["bug","shell","kelp","quad","quad","bug","shell","jelly","shell"][kind]
		for state in ["idle","walk","attack","hurt"]:
			for phase in 8: uv_mesh(profile,state,phase,kind-5 if kind>=5 else kind,1 if kind>=5 else 2)
	if DisplayServer.get_name()!="headless": call_deferred("bake_walks")

func bake_walks() -> void:
	var entries:Array=[]
	for atlas in [g.hero_atlas,g.villain_atlas,g.creature_atlas,g.extra_creature_atlas]:
		var count:=4 if atlas==g.extra_creature_atlas else (5 if atlas==g.creature_atlas else 8)
		for index in count:
			var kind:int=index+5 if atlas==g.extra_creature_atlas else index
			var profile:String="hero" if atlas==g.hero_atlas else ("human" if atlas==g.villain_atlas else ["bug","shell","kelp","quad","quad","bug","shell","jelly","shell"][kind])
			walk_rows["%s/%d"%[atlas.resource_path,index]]=entries.size()
			entries.append({"atlas":atlas,"index":index,"rows":1 if atlas==g.extra_creature_atlas else 2,"profile":profile})
	for motion in ["walk","attack","hurt"]:
		bake_viewport=SubViewport.new()
		bake_viewport.size=Vector2i(1024,entries.size()*128)
		bake_viewport.transparent_bg=true
		bake_viewport.disable_3d=true
		bake_viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
		var painter=load("res://scripts/motion_bake_v8.gd").new()
		painter.presentation=self
		painter.entries=entries
		painter.motion=motion
		bake_viewport.add_child(painter)
		g.add_child(bake_viewport)
		await RenderingServer.frame_post_draw
		await g.get_tree().process_frame
		if not is_instance_valid(bake_viewport): return
		motion_sheets[motion]=ImageTexture.create_from_image(bake_viewport.get_texture().get_image())
		if motion=="walk": walk_sheet=motion_sheets[motion]
		bake_viewport.queue_free()
		bake_viewport=null

func sound(id: String, important: bool=false) -> void:
	if not g.sound_enabled or not clips.has(id): return
	var now:=Time.get_ticks_msec()/1000.0
	var gap:=0.5 if id=="water" else (0.12 if id in ["pick","hit","kill","reel_tick"] else 0.2)
	if now<float(sound_clocks.get(id,-1)): return
	sound_clocks[id]=now+gap
	var interface:bool=id in ["ui","level","chest","evolve","win","lose","chest_open","reel_tick","reel_stop","treasure_1","treasure_3","treasure_5","coin","food","magnet","freeze","wipe","xp","relic","revive"]
	var gain:float=ui_volume if interface else volume
	if gain<=0: return
	# Reserve the last two channels for rewards and damage feedback.
	var first:=10 if interface or important or id=="hurt" else 0
	var last:=12 if first==10 else 10
	for i in range(first,last):
		if voices[i].playing and not (important and i==last-1): continue
		voices[i].stream=clips[id]
		voices[i].volume_db=linear_to_db(gain)-12
		voices[i].pitch_scale=1.0 if interface else 0.96+float(i%3)*0.035
		voices[i].play()
		return

func mesh(profile: String,state: String,phase: int) -> ArrayMesh:
	var key:="%s/%s/%d"%[profile,state,phase]
	if meshes.has(key): return meshes[key]
	var vertices:=PackedVector3Array()
	var uv:=PackedVector2Array()
	var indices:=PackedInt32Array()
	var clock:=TAU*phase/8.0
	for y in 15:
		for x in 13:
			var p:=Vector2(float(x)/12,float(y)/14)
			var q:=p
			var side:= -1.0 if p.x<0.5 else 1.0
			var legs:=smoothstep(0.57,0.91,p.y)
			var edge:=pow(absf(p.x-0.5)*2,2)
			var s:=sin(clock)
			if state=="walk":
				match profile:
					"hero":
						var feet:=smoothstep(0.68,0.91,p.y)
						q.x+=s*side*feet*0.024
						q.y-=maxf(0,s*side)*feet*0.045
						# Head and pot remain rigid; only outer arms swing.
						q.y+=s*side*smoothstep(0.32,0.48,absf(p.x-0.5))*0.013*smoothstep(0.38,0.65,p.y)
					"bug": q.x+=sin(clock*2+p.x*12)*legs*0.035; q.y-=absf(s)*0.012
					"quad": q.x+=s*side*legs*0.045; q.y-=maxf(0,s*side)*legs*0.055
					"shell": q.x+=s*legs*0.018; q.y-=maxf(0,s*side)*legs*0.025
					"kelp": q.x+=sin(clock+p.y*5)*0.022*smoothstep(0.2,0.85,p.y)
					"jelly": q.x+=(p.x-0.5)*s*0.07; q.y+=sin(clock+p.y*4)*0.035
					"human": q.x+=s*side*legs*0.02; q.y-=maxf(0,s*side)*legs*0.025
			elif state=="idle":
				q.y-=sin(clock)*0.006*smoothstep(0.4,0.85,p.y)
			elif state=="attack":
				q.x+=(p.y-0.95)*sin(clock/2)*0.035
				q.y+=(1-p.y)*sin(clock/2)*0.025
			elif state=="hurt": q.x+=(1-p.y)*s*0.025
			vertices.append(Vector3(q.x-0.5,q.y-1,0))
			uv.append(p)
	for y in 14:
		for x in 12:
			var a:=y*13+x
			indices.append_array(PackedInt32Array([a,a+1,a+13,a+1,a+14,a+13]))
	var arrays:=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_TEX_UV]=uv
	arrays[Mesh.ARRAY_INDEX]=indices
	var result:=ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	meshes[key]=result
	return result

var textures: Dictionary={}
func frame_texture(atlas: Texture2D,index: int,cols: int=4,rows: int=2) -> AtlasTexture:
	var key:="%s/%d"%[atlas.resource_path,index]
	if textures.has(key): return textures[key]
	var texture:=AtlasTexture.new()
	texture.atlas=atlas
	var cell:=Vector2(atlas.get_width()/float(cols),atlas.get_height()/float(rows))
	texture.region=Rect2(Vector2(index%cols,index/cols)*cell,cell)
	textures[key]=texture
	return texture

func rig(atlas: Texture2D,index: int,pos: Vector2,size: Vector2,profile: String,state: String,clock: float,tint: Color=Color.WHITE,rows: int=2,angle: float=0) -> void:
	var phase:=posmod(int(clock*8),8)
	if motion_sheets.has(state):
		var row:int=walk_rows["%s/%d"%[atlas.resource_path,index]]
		g.draw_set_transform(pos,angle)
		g.draw_texture_rect_region(motion_sheets[state],Rect2(Vector2(-size.x/2,-size.y),size),Rect2(phase*128,row*128,128,128),tint)
		g.draw_set_transform(Vector2.ZERO)
		return
	var transform:=Transform2D(angle,Vector2.ZERO).scaled(size)
	transform.origin=pos
	g.draw_mesh(uv_mesh(profile,state,phase,index,rows),atlas,transform,tint)

func uv_mesh(profile: String,state: String,phase: int,index: int,rows: int) -> ArrayMesh:
	var key:="uv/%s/%s/%d/%d/%d"%[profile,state,phase,index,rows]
	if not meshes.has(key):
		var arrays:Array=mesh(profile,state,phase).surface_get_arrays(0)
		var uv:PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
		for i in uv.size(): uv[i]=(uv[i]+Vector2(index%4,index/4))/Vector2(4,rows)
		arrays[Mesh.ARRAY_TEX_UV]=uv
		var result:=ArrayMesh.new()
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		meshes[key]=result
	return meshes[key]

func enemy_visual(e: Dictionary,alpha: float=1,death_age: float=0) -> void:
	var kind:int=e.kind
	var human:bool=e.boss or e.elite
	var atlas:Texture2D=g.villain_atlas if human else (g.extra_creature_atlas if kind>=5 else g.creature_atlas)
	var index:int=int(e.get("portrait",6)) if e.boss else (5 if e.elite else (kind-5 if kind>=5 else kind))
	var width:float=185 if e.boss else (float(g.encounters.miniboss.size) if e.elite else float(g.encounters.creatures[kind].get("draw_size",92)))
	var height:float=width if human or kind<5 else width*atlas.get_height()*4.0/atlas.get_width()
	var profile:String="human" if human else ["bug","shell","kelp","quad","quad","bug","shell","jelly","shell"][kind]
	var preparing:bool=e.get("warning",0)>0 or e.get("locked",false) or e.pos.distance_to(g.player)<float(e.radius)+45
	var motion:String="attack" if preparing else ("walk" if e.get("moving",true) else "idle")
	if e.hit>0: motion="hurt"
	var tint:=Color(1,1,1,alpha)
	if e.hit>0: tint=Color(1.3,1.15,1.0,alpha)
	var frozen:bool=g.freeze_time>0 or e.get("frozen",0)>0
	if frozen: tint=Color(0.6,0.85,1,alpha)
	var time:float=float(e.get("anim_clock",0))
	if death_age>0: motion="hurt"
	var jolt:Vector2=e.get("fx_jolt",Vector2.ZERO)*clampf(e.hit/0.1,0,1)
	rig(atlas,index,e.pos+Vector2(0,17+death_age*14)+jolt,Vector2(width,height),profile,motion,time,tint,2 if human or kind<5 else 1,death_age*0.6)

func add_impact(pos: Vector2,id: String,evolved: bool=false) -> void:
	if impacts.size()>=(12 if low_fx else 32): return
	impacts.append({"pos":pos,"id":id,"life":0.3,"evolved":evolved})

func record_hit(e: Dictionary,amount: float,id: String,knock: Vector2=Vector2.ZERO) -> void:
	var actual:=minf(maxf(0,e.hp),maxf(0,amount))
	damage_totals[id]=float(damage_totals.get(id,0))+actual
	if e.hit<=0:
		g.combat_fx.hit(e,id,knock)
		# Area attacks already own one large impact at their landing point.
		# Each victim still recoils/flashes, without duplicating that explosion.
		if id not in ["rain","tetra","gull_white","gull_dark","gull_union","heat","wing_union"]:
			add_impact(e.pos+Vector2(0,-15),id,g.evolved.has(id))
		sound(id if id in ["kelp","bowl","gull_white","gull_dark","gull_union","wing_union"] else "hit")
	if amount>=e.hp and ghosts.size()<(12 if low_fx else 28):
		var copy:Dictionary=e.duplicate()
		copy.death_life=0.45
		ghosts.append(copy)
		sound(["bug_die","shell_die","kelp_die","quad_die","quad_die","bug_die","shell_die","jelly_die","shell_die"][int(e.kind)] if not e.boss and not e.elite else "human_die")

func tick(dt: float) -> void:
	walk_clock+=dt*(1.8 if g.move_dir.length_squared()>0.01 else 0.4)
	player_hurt=maxf(0,player_hurt-dt)
	for id in g.upgrades:
		if g.encounters.weapon_profiles.has(id): equipped_seconds[id]=float(equipped_seconds.get(id,0))+dt
	if g.water_time>0: sound("water")
	for i in range(ghosts.size()-1,-1,-1):
		ghosts[i].death_life-=dt
		if ghosts[i].death_life<=0: ghosts.remove_at(i)
	for i in range(impacts.size()-1,-1,-1):
		impacts[i].life-=dt
		if impacts[i].life<=0: impacts.remove_at(i)
	for i in range(boss_hazards.size()-1,-1,-1):
		var h:Dictionary=boss_hazards[i]
		h.life-=dt
		if g.freeze_time>0: h.life+=dt; continue
		if h.life<=0:
			if g.player.distance_to(h.pos)<h.radius+18 and g.invulnerable<=0:
				g.hp-=g.arsenal.block_damage(maxf(1,18-g.armor()))
				g.invulnerable=0.8
				player_hurt=0.25
				sound("hurt",true)
			add_impact(h.pos,"tetra",true)
			boss_hazards.remove_at(i)

func boss_motion(e: Dictionary,dt: float,dir: Vector2) -> Vector2:
	if not e.boss: return dir*float(e.speed)
	var mode:int=e.get("pattern",0)
	var timer:float=e.get("special_cd",5.0)-dt
	e.special_cd=timer
	if e.get("charging",0)>0:
		e.charging=maxf(0,float(e.charging)-dt)
		return e.get("locked_dir",dir)*240
	if timer<=1 and timer>0:
		if not e.get("locked",false):
			e.locked=true
			e.locked_dir=dir
			e.target_pos=g.player
			sound("warning")
		return Vector2.ZERO
	if timer<=0:
		e.special_cd=7.5 if mode<5 else 5.5
		e.locked=false
		match mode%3:
			0:
				e.charging=0.9
				sound("gust")
			1:
				for n in (8 if mode<5 else 12):
					if g.enemy_shots.size()>=28: break
					g.enemy_shots.append({"pos":e.pos,"dir":Vector2.from_angle(TAU*n/(8 if mode<5 else 12)),"life":4.5,"human":true})
				sound("chain")
			2:
				for n in 3:
					if boss_hazards.size()>=9: break
					boss_hazards.append({"pos":e.get("target_pos",g.player)+Vector2((n-1)*120,0),"radius":65.0,"life":1.2})
				sound("drop")
	return dir*float(e.speed)

func draw() -> void:
	for corpse in ghosts:
		if g.on_screen(corpse.pos): enemy_visual(corpse,float(corpse.death_life)/0.45,0.45-float(corpse.death_life))
	for h in boss_hazards:
		g.paint_ellipse(h.pos,Vector2(h.radius,h.radius*0.55),Color(0.75,0.3,0.18,0.15))
		g.draw_arc(h.pos,h.radius,0,TAU,28,Color("c97850"),3,true)
		g.draw_arc(h.pos,h.radius*clampf(1-h.life/1.2,0,1),0,TAU,24,Color("e5bc74"),2,true)
	for e in g.enemies:
		if not e.boss or not e.get("locked",false) or g.freeze_time>0: continue
		if int(e.get("pattern",0))%3==0:
			var dir:Vector2=e.get("locked_dir",Vector2.RIGHT)
			g.draw_line(e.pos,e.pos+dir*220,Color(0.8,0.35,0.2,0.6),10,true)
	for hit in impacts:
		var age:float=1-hit.life/0.3
		g.combat_fx.draw_impact(hit.pos,hit.id,age,hit.evolved)

func ranking() -> Array:
	var result:=[]
	for id in damage_totals:
		result.append({"id":id,"damage":float(damage_totals[id]),"dps":float(damage_totals[id])/maxf(1,float(equipped_seconds.get(id,g.elapsed)))})
	result.sort_custom(func(a,b):return a.damage>b.damage)
	return result

func performance_sample(delta: float) -> void:
	if g.state!="running": return
	# Aggregated real render intervals, not accelerated simulation tick timings.
	frame_accumulator+=delta
	sample_clock+=1
	if frame_accumulator>=1:
		frame_samples.append(1000.0*frame_accumulator/maxf(1,sample_clock))
		if frame_samples.size()>1800: frame_samples.pop_front()
		frame_accumulator=0
		sample_clock=0

func performance_text() -> String:
	if frame_samples.is_empty(): return "성능 측정 중"
	var ordered:=frame_samples.duplicate()
	ordered.sort()
	var total:=0.0
	for sample in ordered: total+=sample
	var text:="평균 %.0f FPS · 느린 구간 %.1fms"%[1000.0/(total/ordered.size()),ordered[mini(ordered.size()-1,int(ordered.size()*0.95))]]
	if not input_samples.is_empty():
		var total_input:=0.0
		for ms in input_samples: total_input+=ms
		text+="\n입력 → 렌더 %.1fms"%(total_input/input_samples.size())
	return text

func note_input() -> void:
	if g.state=="running" and input_started==0: input_started=Time.get_ticks_usec()

func input_frame_finished() -> void:
	if input_started<=0: return
	input_samples.append((Time.get_ticks_usec()-input_started)/1000.0)
	if input_samples.size()>120: input_samples.pop_front()
	input_started=0
