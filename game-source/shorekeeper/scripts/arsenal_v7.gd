extends RefCounted

# All combat quantities are world units / seconds. Display metadata is generated
# from the same stat contract that is used here; Amount is never a generic multiplier.
var g: Node2D
var pending: Array[Dictionary]=[]
var zones: Array[Dictionary]=[]
var flights: Array[Dictionary]=[]
var strokes: Array[Dictionary]=[]
var orbits: Array[Dictionary]=[]
var aura_hits: Dictionary={}
var beam_hits: Dictionary={}
var bird_sets: Dictionary={}
var shield_charges:=0
var shield_timer:=0.0
var shield_started:=false
var serial:=0
var healed:=0.0
var last_hp:=100.0
var heat_visual:=0.0

func reset() -> void:
	for collection in [pending,zones,flights,strokes,orbits]: collection.clear()
	for collection in [aura_hits,beam_hits,bird_sets]: collection.clear()
	shield_charges=0
	shield_timer=0
	shield_started=false
	serial=0
	healed=0
	last_hp=g.hp
	heat_visual=0

func stats(id: String, level_override: int=-1) -> Dictionary:
	var p:Dictionary=g.encounters.weapon_profiles[id]
	var s:Dictionary=p.duplicate(true)
	var level:int=level_override if level_override>0 else maxi(1,g.upgrades.get(id,1))
	var n:=level-1
	s.level=level
	s.damage=float(p.damage)*(1+n*0.18)
	s.radius=float(p.radius)*(1+n*0.06)
	s.speed=float(p.speed)*(1+n*0.04)
	s.duration=float(p.duration)
	s.amount=int(p.amount)
	s.pierce=int(p.pierce)
	s.cooldown=float(p.cooldown)*(1-n*0.035)
	if id in ["sand","pearl","bowl","shell","snack","tetra"]: s.amount+=n/2
	if id in ["feather","gust"]: s.amount+=n/3; s.pierce+=n
	if id in ["gull_white","gull_dark"]: s.amount+=n
	if id=="gull_union": s.amount+=n
	if id in ["bowl","rain","stone"]: s.duration+=n*0.14
	if id=="heat": s.cooldown=maxf(60,90-n*5)
	if id=="anchor": s.cooldown=10-n*0.25
	if "피해" in p.affected: s.damage*=g.power()
	if "범위" in p.affected: s.radius*=g.area()
	if "탄속" in p.affected: s.speed*=g.projectile_speed()
	if "지속" in p.affected: s.duration*=g.duration()
	if "개수" in p.affected: s.amount+=g.bonus_amount()
	if id=="pearl" and g.blessings.has("stars"): s.amount+=1
	s.cooldown=maxf(0.12,float(s.cooldown)*g.cooldown())
	if g.evolved.has(id) and id not in ["heat","anchor","gull_union","wing_union"]: s.damage*=1.4
	if g.evolved.has(id):
		match id:
			"sand": s.cooldown*=0.45; s.pierce+=2
			"pearl": s.cooldown*=0.45; s.pierce+=2
			"shell": s.amount=maxi(8,s.amount); s.pierce=99
			"snack": s.damage*=1.6; s.radius*=1.3
			"wave": s.pierce=99; s.radius*=1.3
			"kelp": s.damage+=minf(30,healed/4)
			"heat": s.cooldown*=0.7
	return s

func targets(pos: Vector2, radius: float) -> Array:
	return g.nearby(pos,radius).filter(func(e):return e.hp>0 and e.pos.distance_to(pos)<=radius)

func nearest_direction(fallback: Vector2) -> Vector2:
	var list:=targets(g.player,850)
	if list.is_empty(): return fallback
	list.sort_custom(func(a,b):return a.pos.distance_squared_to(g.player)<b.pos.distance_squared_to(g.player))
	return (list[0].pos-g.player).normalized()

func deal(e: Dictionary, amount: float, knock: Vector2, id: String) -> void:
	var critical:=0.0
	if id in ["chain","snack"] and g.evolved.has(id): critical=0.1*g.luck()
	if id in ["sand","pearl","shell","chain","snack","feather","gust"]: critical=maxf(critical,g.crit_chance())
	if critical>0 and g.rng.randf()<critical: amount*=2
	g.damage(e,amount,knock,false,id)

func add_zone(pos: Vector2, radius: float, damage: float, life: float, kind: String, id: String, delay: float=0) -> void:
	var flight:=0.32 if kind=="bird" else (0.22 if kind=="rain" else (0.4 if kind=="impact" else 0.0))
	var wait:float=delay+flight if kind in ["bird","rain"] else delay
	var queue:Array=flights if flight>0 and wait>0 else zones
	if queue.size()>=48: return
	queue.append({"pos":pos,"radius":radius,"damage":damage,"life":life,"total":life,"kind":kind,"weapon":id,"delay":wait,"flight":flight,"origin":pos+Vector2(0,-380),"age":0.0,"hits":{},"next":{},"hit":false,"landed":false})

func queue_missile(id: String, s: Dictionary, dir: Vector2, delay: float=0, offset: Vector2=Vector2.ZERO) -> void:
	if pending.size()+g.bullets.size()>=180: return
	var velocity:Vector2=dir*float(s.speed)
	var radius:float=s.radius
	if id=="shell" and not g.evolved.has(id): velocity=Vector2(dir.x*170,-400)*float(s.speed)
	pending.append({"delay":delay,"weapon":id,"pos":g.player+offset+Vector2(0,-12),"offset":offset,"dir":dir,"velocity":velocity,"life":float(s.duration),"damage":float(s.damage),"pierce":int(s.pierce),"radius":radius,"hits":{},"age":0.0,"icon":int(s.icon)})

func cast(id: String, s: Dictionary) -> void:
	g.presentation.sound(id)
	if id in ["chain","bowl","rain","tetra","heat"]: g.combat_fx.launch(id,g.player+Vector2(0,-20),g.aim)
	var count:int=s.amount
	var list:=targets(g.player,900)
	match id:
		"sand":
			for i in count: queue_missile(id,s,g.aim,i*0.065)
		"pearl":
			if list.is_empty(): return
			list.sort_custom(func(a,b):return a.pos.distance_squared_to(g.player)<b.pos.distance_squared_to(g.player))
			for i in count: queue_missile(id,s,(list[i%list.size()].pos-g.player).normalized(),i*0.07)
		"wave":
			for i in count:
				var dir:Vector2=g.aim if list.is_empty() else (list[g.rng.randi_range(0,list.size()-1)].pos-g.player).normalized()
				queue_missile(id,s,dir,i*0.09)
		"shell":
			for i in count:
				var dir:=Vector2.from_angle(TAU*i/count) if g.evolved.has(id) else Vector2(1 if i%2==0 else -1,0)
				queue_missile(id,s,dir,i*0.10)
		"snack":
			var dir:=nearest_direction(g.aim)
			for i in count: queue_missile(id,s,dir.rotated((i-(count-1)*0.5)*0.12),i*0.08)
		"stone":
			for i in count: queue_missile(id,s,Vector2.from_angle(g.rng.randf()*TAU),i*0.08)
		"feather","gust":
			for stream in 4:
				var dir:=Vector2.from_angle(TAU*stream/4+(PI/4 if id=="feather" else 0))
				for i in count: queue_missile(id,s,dir,i*0.09)
		"chain":
			var side:=1.0 if g.aim.x>=0 else -1.0
			for i in count:
				if strokes.size()>=24: break
				strokes.append({"delay":i*0.1,"life":0.28,"age":0.0,"dir":Vector2(side*(1 if i%2==0 else -1),0),"offset":Vector2(0,-12-(i/2)*20),"damage":s.damage,"reach":s.radius,"hit":false})
		"bowl":
			if orbits.size()>=8: return
			serial+=1
			orbits.append({"serial":serial,"count":mini(count,12),"age":0.0,"life":s.duration,"damage":s.damage,"radius":s.radius,"speed":s.speed,"hits":{},"phase":serial*0.3})
		"rain":
			for i in count:
				var pos:Vector2=g.player+Vector2.from_angle(TAU*i/count+g.elapsed*0.2)*g.rng.randf_range(80,240)
				if i==0 and not list.is_empty(): pos=list[0].pos
				add_zone(pos,s.radius,s.damage,s.duration,"rain",id,i*0.12)
		"tetra":
			if list.is_empty(): return
			for i in count:
				var e:Dictionary=list[g.rng.randi_range(0,list.size()-1)]
				add_zone(e.pos,s.radius,s.damage,0.5,"impact",id,0.4+i*0.07)
				if g.evolved.has(id): add_zone(e.pos,s.radius*1.1,s.damage,0.5,"impact",id,0.9+i*0.07)
		"heat": heat_pulse(-1)

func heat_pulse(force_keep: int=-1) -> void:
	var level:int=g.upgrades.get("heat",1)
	var thresholds:=[0.1,0.1,0.25,0.25,0.45,0.45,0.65,0.65]
	var upgraded:bool=g.evolved.has("heat")
	var keep:bool=upgraded or g.rng.randf()<minf(1,float(thresholds[mini(7,level-1)])*g.luck())
	if force_keep>=0: keep=force_keep==1
	for e in g.enemies.duplicate():
		if e.hp<=0 or e.boss or not g.on_screen(e.pos,0): continue
		g.damage(e,e.hp+1,Vector2.ZERO,false,"heat")
		if upgraded: g.add_gem(e.pos,3)
	if not keep:
		g.gems=g.gems.filter(func(gem):return not g.on_screen(gem.pos,0))
		g.pickups=g.pickups.filter(func(p):return str(p.kind).begins_with("relic_") or not g.on_screen(p.pos,0))
	if upgraded: g.apply_pickup("magnet")
	g.flash_time=0.25
	heat_visual=0.7
	g.banner="초열경보 · 경험치 회수" if upgraded else ("폭염주의보 · 전리품 보존" if keep else "폭염주의보 · 주변 전리품 소멸")
	g.banner_time=2.5

func update(dt: float) -> void:
	g.combat_fx.update(dt)
	heat_visual=maxf(0,heat_visual-dt)
	healed+=maxf(0,g.hp-last_hp)
	for id in g.encounters.weapon_profiles:
		if g.upgrades.get(id,0)<=0: continue
		var s:=stats(id)
		if id in ["kelp","anchor","gull_white","gull_dark","gull_union","wing_union"]: continue
		g.timers[id]=float(g.timers.get(id,0))-dt
		if g.timers[id]<=0:
			cast(id,s)
			g.timers[id]=float(s.cooldown)+(float(s.duration)/g.duration() if id=="bowl" and not g.evolved.has(id) else 0)
	update_shield(dt)
	update_aura()
	update_birds()
	update_beams()
	update_pending(dt)
	update_missiles(dt)
	update_strokes(dt)
	update_orbits(dt)
	update_zones(dt)
	last_hp=g.hp

func update_pending(dt: float) -> void:
	for i in range(pending.size()-1,-1,-1):
		pending[i].delay-=dt
		if pending[i].delay>0: continue
		if g.bullets.size()<160:
			pending[i].pos=g.player+pending[i].get("offset",Vector2.ZERO)+Vector2(0,-12)
			g.combat_fx.launch(str(pending[i].weapon),pending[i].pos,pending[i].dir)
			g.bullets.append(pending[i])
		pending.remove_at(i)

func update_missiles(dt: float) -> void:
	for i in range(g.bullets.size()-1,-1,-1):
		var b:Dictionary=g.bullets[i]
		var id:String=b.weapon
		var previous:Vector2=b.pos
		b.age+=dt
		b.life-=dt
		if id=="shell" and not g.evolved.has(id): b.velocity.y+=400*dt
		if id=="snack" and b.age>0.55:
			b.velocity=(g.player-b.pos).normalized()*b.velocity.length()
			if b.pos.distance_to(g.player)<22: b.life=0
		b.pos+=b.velocity*dt
		if id=="stone":
			var view:=Rect2(g.camera.position-g.view_half(),g.view_half()*2).grow(-18)
			var bounced:=false
			if b.pos.x<view.position.x or b.pos.x>view.end.x: b.velocity.x=-b.velocity.x; bounced=true
			if b.pos.y<view.position.y or b.pos.y>view.end.y: b.velocity.y=-b.velocity.y; bounced=true
			b.pos=b.pos.clamp(view.position,view.end)
			if g.shore.blocked(b.pos,3): b.pos=previous; b.velocity=-b.velocity; bounced=true
			if bounced and g.evolved.has(id): add_zone(b.pos,b.radius*2,b.damage,0.3,"shatter",id)
		elif id in ["sand","pearl","wave","feather","gust"] and g.shore.blocked(b.pos,2): b.life=0
		var middle:Vector2=(previous+b.pos)*0.5
		for e in g.nearby(middle,previous.distance_to(b.pos)*0.5+float(b.radius)+70):
			if e.hp<=0: continue
			var repeat:bool=id in ["stone","snack"]
			if b.hits.has(e.id) and (not repeat or g.elapsed<float(b.hits[e.id])): continue
			if Geometry2D.get_closest_point_to_segment(e.pos,previous,b.pos).distance_to(e.pos)>float(e.radius)+float(b.radius): continue
			b.hits[e.id]=g.elapsed+0.35
			deal(e,b.damage,b.velocity.normalized()*65,id)
			if not repeat:
				b.pierce-=1
				if b.pierce<=0: break
		if b.life<=0 or b.pierce<=0: g.bullets.remove_at(i)

func update_strokes(dt: float) -> void:
	for i in range(strokes.size()-1,-1,-1):
		var a:Dictionary=strokes[i]
		a.delay-=dt
		if a.delay>0: continue
		a.life-=dt
		a.age+=dt
		if not a.hit and a.age>=0.1:
			a.hit=true
			var start:Vector2=g.player+a.offset
			var finish:Vector2=start+a.dir*float(a.reach)
			for e in g.nearby(start,float(a.reach)+70):
				if e.hp>0 and Geometry2D.get_closest_point_to_segment(e.pos,start,finish).distance_to(e.pos)<float(e.radius)+24*g.area():
					deal(e,a.damage,a.dir*260,"chain")
					if g.evolved.has("chain"): g.hp=minf(g.max_health(),g.hp+0.3)
		if a.life<=0: strokes.remove_at(i)

func update_orbits(dt: float) -> void:
	for i in range(orbits.size()-1,-1,-1):
		var o:Dictionary=orbits[i]
		o.age+=dt
		o.life-=dt
		for n in int(o.count):
			var pos:Vector2=g.player+Vector2.from_angle(o.age*float(o.speed)+TAU*n/o.count+o.phase)*g.orbit_radius()
			for e in g.nearby(pos,float(o.radius)+70):
				if e.hp<=0 or pos.distance_to(e.pos)>float(e.radius)+float(o.radius): continue
				var key:="%d:%d"%[n,int(e.id)]
				if g.elapsed<float(o.hits.get(key,-1)): continue
				o.hits[key]=g.elapsed+0.65
				deal(e,o.damage,(e.pos-g.player).normalized()*170,"bowl")
		if o.life<=0: orbits.remove_at(i)

func update_aura() -> void:
	if g.upgrades.get("kelp",0)<=0: return
	var s:=stats("kelp")
	for e in targets(g.player,float(s.radius)+40):
		if e.pos.distance_to(g.player)>s.radius+float(e.radius) or g.elapsed<float(aura_hits.get(e.id,-1)): continue
		aura_hits[e.id]=g.elapsed+float(s.cooldown)
		deal(e,s.damage,(e.pos-g.player).normalized()*30,"kelp")
		e.exposed=1.5
		if g.evolved.has("kelp") and g.rng.randf()<0.1*g.luck(): g.hp=minf(g.max_health(),g.hp+0.2)
	if aura_hits.size()>300: aura_hits.clear()

func update_birds() -> void:
	for id in ["gull_white","gull_dark","gull_union"]:
		if g.upgrades.get(id,0)<=0: continue
		var s:=stats(id)
		var cycle:float=s.duration+float(s.cooldown)
		if fmod(g.elapsed,cycle)>=s.duration: continue
		if g.elapsed<float(bird_sets.get(id,-1)): continue
		bird_sets[id]=g.elapsed+maxf(0.25,0.9*g.cooldown())
		var directions:Array=[-1] if id=="gull_dark" else [1]
		if id=="gull_union": directions=[1,-1]
		for direction in directions:
			var center:Vector2=g.player+Vector2.from_angle(g.elapsed*float(s.speed)*direction)*230
			for n in int(s.amount):
				var pos:Vector2=center+Vector2.from_angle(TAU*n/s.amount)*40
				var before:=flights.size()
				add_zone(pos,s.radius,s.damage,0.35,"bird",id,n*0.025)
				if flights.size()>before: flights[-1].origin=g.combat_fx.bird_origin(id,direction)

func update_zones(dt: float) -> void:
	# Flight time never consumes a damaging ground-zone slot. Both queues are
	# bounded independently so visible anticipation cannot crowd out active hits.
	for i in range(flights.size()-1,-1,-1):
		flights[i].delay-=dt
		if flights[i].delay>0: continue
		if zones.size()<48: zones.append(flights[i])
		flights.remove_at(i)
	for i in range(zones.size()-1,-1,-1):
		var z:Dictionary=zones[i]
		z.delay-=dt
		if z.delay>0: continue
		if not z.landed:
			z.landed=true
			if z.kind in ["bird","impact"]:
				g.presentation.sound("wing_drop" if z.kind=="bird" else "impact_heavy")
		z.life-=dt
		z.age+=dt
		# Explosions strike at impact; the remaining lifetime is the visual
		# follow-through, not a second lingering damage field. Rain stays active.
		if z.kind!="rain" and z.hit:
			if z.life<=0: zones.remove_at(i)
			continue
		if z.kind=="rain" and g.evolved.has("rain"):
			z.pos=z.pos.move_toward(g.player,dt*35)
			z.radius+=dt*5
		for e in g.nearby(z.pos,float(z.radius)+70):
			if e.hp<=0 or z.pos.distance_to(e.pos)>float(z.radius)+float(e.radius): continue
			if z.kind!="rain" and z.hits.has(e.id): continue
			if z.kind=="rain" and g.elapsed<float(z.next.get(e.id,-1)): continue
			z.hits[e.id]=true
			z.next[e.id]=g.elapsed+0.5
			deal(e,z.damage,Vector2.ZERO,str(z.weapon))
		if z.kind!="rain": z.hit=true
		if z.life<=0: zones.remove_at(i)

func update_beams() -> void:
	if g.upgrades.get("wing_union",0)<=0: return
	var s:=stats("wing_union")
	if fmod(g.elapsed,float(s.cooldown)+1.0)>1.0: return
	var revivals:int=mini(10,maxi(0,g.upgrades.get("revive",0)-g.revivals_used))
	var count:int=s.amount+revivals
	for e in targets(g.player,900):
		if g.elapsed<float(beam_hits.get(e.id,-1)): continue
		for n in count:
			var end:Vector2=g.player+Vector2.from_angle(g.elapsed*float(s.speed)+TAU*n/count)*900
			if Geometry2D.get_closest_point_to_segment(e.pos,g.player,end).distance_to(e.pos)<float(e.radius)+float(s.radius):
				beam_hits[e.id]=g.elapsed+0.2
				deal(e,s.damage+revivals,Vector2.ZERO,"wing_union")
				break
	if beam_hits.size()>300: beam_hits.clear()

func update_shield(dt: float) -> void:
	if g.upgrades.get("anchor",0)<=0:
		shield_charges=0
		shield_started=false
		return
	var s:=stats("anchor")
	var capacity:=1+int(s.level>=3)+int(s.level>=6)
	if not shield_started:
		shield_charges=capacity
		shield_started=true
	shield_timer=maxf(0,shield_timer-dt)
	if shield_charges<capacity and shield_timer<=0:
		shield_charges+=1
		shield_timer=s.cooldown

func block_damage(amount: float) -> float:
	if g.upgrades.get("anchor",0)<=0: return amount
	if shield_charges>0:
		shield_charges-=1
		g.presentation.sound("anchor",true)
		g.presentation.add_impact(g.player,"anchor",g.evolved.has("anchor"))
		shield_timer=stats("anchor").cooldown
		if g.evolved.has("anchor"):
			for e in targets(g.player,160): deal(e,minf(100,amount*3),Vector2.ZERO,"anchor")
		return 0
	return minf(10,amount) if g.evolved.has("anchor") else amount

func draw() -> void:
	g.combat_fx.draw_arsenal()
