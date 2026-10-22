extends RefCounted

# Visual envelopes never multiply damage or collision radii. Warm coloured,
# painted sprites remain the source; no per-hit lights, shaders or particle nodes.
var g: Node2D
var events: Array[Dictionary]=[]
var clocks: Dictionary={}
var last_shake:=-1.0
var recoil:=Vector2.ZERO
var recoil_time:=0.0

func reset() -> void:
	events.clear()
	clocks.clear()
	recoil=Vector2.ZERO
	recoil_time=0
	last_shake=-1

func update(dt: float) -> void:
	recoil_time=maxf(0,recoil_time-dt)
	for i in range(events.size()-1,-1,-1):
		events[i].age+=dt
		if events[i].age>=events[i].life: events.remove_at(i)

func event(id: String,pos: Vector2,dir: Vector2=Vector2.RIGHT,kind: String="launch",size: float=70) -> void:
	var key:=id+"/"+kind
	if g.elapsed<float(clocks.get(key,-1)): return
	clocks[key]=g.elapsed+(0.15 if kind=="hit" else 0.09)
	if events.size()>=(8 if g.presentation.low_fx else 20): return
	events.append({"id":id,"pos":pos,"dir":dir,"kind":kind,"size":size,"age":0.0,"life":0.28 if kind=="launch" else 0.36})

func launch(id: String,pos: Vector2,dir: Vector2) -> void:
	if id in ["sand","pearl","wave","shell","snack","stone","feather","gust"]: pos+=Vector2(0,-20)
	event(id,pos,dir,"launch",92 if id=="wave" else 62)
	if id in ["sand","wave","chain"]:
		recoil=dir*4
		recoil_time=0.12

func hit(e: Dictionary,id: String,knock: Vector2) -> void:
	var heavy:bool=id in ["tetra","chain","wave","shell","gull_union","heat","anchor"]
	var dir:Vector2=knock.normalized() if knock.length_squared()>0 else (e.pos-g.player).normalized()
	e.fx_jolt=dir*(8 if heavy else 4)
	if heavy and g.elapsed-last_shake>=0.18:
		last_shake=g.elapsed
		if not g.presentation.reduced_motion: g.shake=maxf(g.shake,2.2)
		g.presentation.sound("impact_heavy")
	elif not heavy: g.presentation.sound("impact_light")

func colour(id: String) -> Color:
	if id in ["sand","shell","snack","heat"]: return Color("deb470")
	if id in ["chain","stone","tetra","anchor","bowl"]: return Color("8aa6a4")
	if id=="kelp": return Color("84b583")
	if id in ["feather","gust","gull_white","gull_dark","gull_union","wing_union"]: return Color("c1d6c9")
	return Color("8bcfc8")

func painted_effect(id: String) -> int:
	if id in ["sand","heat"]: return 11
	if id=="kelp": return 6
	if id in ["wave","rain","water","gull_white","gull_dark","gull_union"]: return 4
	return 10

func draw_impact(pos: Vector2,id: String,progress: float,evolved: bool=false,radius: float=0) -> void:
	paint_impact(g,pos,id,progress,evolved,radius)

func stamp(target: Node2D,index: int,pos: Vector2,size: Vector2,angle: float,tint: Color) -> void:
	var texture:Texture2D=g.effects
	var cell:=Vector2(texture.get_width()/4.0,texture.get_height()/4.0)
	target.draw_set_transform(pos,angle)
	target.draw_texture_rect_region(texture,Rect2(-size/2,size),Rect2(Vector2(index%4,index/4)*cell,cell),tint)
	target.draw_set_transform(Vector2.ZERO)

func paint_impact(target: Node2D,pos: Vector2,id: String,progress: float,evolved: bool=false,radius: float=0) -> void:
	var heavy:bool=id in ["tetra","wave","shell","chain","gull_union","heat","anchor"]
	var size:float=maxf(radius*1.5,112 if heavy else 66)
	var c:=colour(id)
	c.a=(1-progress)*0.85
	# Quick bright contact, broad painted burst, then a readable fading ripple.
	stamp(target,painted_effect(id),pos,Vector2(size*(0.65+progress*0.85),size*(0.45+progress*0.6)),progress*0.45,c)
	if progress<0.32:
		stamp(target,10,pos,Vector2(size*0.68,size*0.22),PI/4,Color(1,0.96,0.79,(1-progress/0.32)*0.95))
	if heavy or evolved:
		c.a=(1-progress)*0.65
		target.draw_arc(pos,size*(0.2+progress*0.4),0,TAU,20,c,3 if heavy else 2,true)

func draw_events() -> void:
	for v in events:
		if not g.on_screen(v.pos,200): continue
		var t:float=v.age/v.life
		if v.kind=="hit": draw_impact(v.pos,v.id,t,g.evolved.has(str(v.id)),v.size); continue
		var c:=colour(v.id)
		c.a=(1-t)*0.9
		var dir:Vector2=v.dir
		g.atlas_draw(g.effects,painted_effect(v.id),v.pos+dir*(12+t*22),Vector2(v.size*(1-t*0.45),v.size*(0.5-t*0.3)),4,4,dir.angle(),c)

func bird_origin(id: String,direction: int=1) -> Vector2:
	var s:Dictionary=g.arsenal.stats(id)
	var sign_value:float=-1 if id=="gull_dark" else direction
	return g.player+Vector2.from_angle(g.elapsed*float(s.speed)*sign_value)*185+Vector2(0,-105)

func draw_flight(z: Dictionary,decorated: bool=true) -> void:
	var flight:float=z.get("flight",0.0)
	if flight<=0 or z.delay>flight: return
	var t:float=clampf(1-z.delay/flight,0,1)
	var start:Vector2=z.get("origin",z.pos+Vector2(0,-360))
	var pos:Vector2=start.lerp(z.pos,t*t if z.kind=="impact" else t)
	if z.kind=="bird": pos.y-=sin(t*PI)*55
	var shadow:float=0.2+t*0.5
	if decorated: g.paint_ellipse(z.pos,Vector2(z.radius*(0.45+t*0.3),9),Color(0.22,0.32,0.3,shadow*0.3))
	if z.kind=="impact":
		g.draw_arc(z.pos,z.radius,0,TAU,24,Color(0.65,0.4,0.25,0.4),2,true)
		g.draw_tetrapod(pos,1.1,Color.WHITE)
	elif z.kind=="bird":
		# The visible bomb leaves the actual orbiting gull and hits its marker.
		g.atlas_draw(g.effects,7,pos,Vector2(36,52)*(0.75+t*0.35),4,4,t*2,Color("f6e5b9"))
		if decorated: g.atlas_draw(g.effects,10,pos-Vector2(0,24),Vector2(20,50),4,4,0,Color(0.75,0.9,0.85,0.45))
	else:
		g.atlas_draw(g.effects,7,pos,Vector2(26,44),4,4,0,Color("94d8d1"))

func draw_arsenal() -> void:
	var a:RefCounted=g.arsenal
	var trails:=0
	var trail_budget:=10 if g.presentation.low_fx else 26
	if a.heat_visual>0:
		var t:float=1-a.heat_visual/0.7
		g.draw_item(37,g.player+Vector2(0,-100-t*50),Vector2.ONE*(220+t*110),0,Color(1,1,1,1-t))
		g.draw_arc(g.player,100+t*700,0,TAU,48,Color(0.95,0.72,0.38,(1-t)*0.6),12*(1-t)+2,true)
	for b in g.bullets:
		if not g.on_screen(b.pos): continue
		var visual_pos:Vector2=b.pos+Vector2(0,-20)
		var dir:Vector2=b.velocity.normalized()
		var size:float=maxf(36,b.radius*3.0)
		var evolved:bool=g.evolved.has(str(b.weapon))
		var c:=colour(str(b.weapon))
		if trails<trail_budget:
			trails+=1
			c.a=0.5
			g.atlas_draw(g.effects,10,visual_pos-dir*size*0.55,Vector2(size*(2.4 if evolved else 1.8),size*0.42),4,4,dir.angle(),c)
		var scale_value:float=1+0.15*exp(-b.age*14)
		if b.weapon=="wave":
			g.atlas_draw(g.effects,2,visual_pos,Vector2(size*1.7,size*1.2)*scale_value,4,4,dir.angle())
		elif b.weapon=="gust":
			g.draw_item(b.icon,visual_pos,Vector2(size*1.8,size),dir.angle()+sin(b.age*15)*0.15)
		else:
			var spin:float=b.age*10 if b.weapon in ["shell","snack","stone"] else (PI if b.weapon=="sand" else 0.0)
			g.draw_item(b.icon,visual_pos,Vector2.ONE*size*scale_value,dir.angle()+spin)
	for stroke in a.strokes:
		if stroke.delay>0: continue
		var t:float=clampf(stroke.age/0.28,0,1)
		var side:Vector2=stroke.dir
		var angle:float=(-0.95*(1-t/0.36) if t<0.36 else 0.55*(t-0.36)/0.64)*(1 if side.x>=0 else -1)
		var points:=PackedVector2Array()
		for n in 13:
			var u:=n/12.0
			points.append(g.player+stroke.offset+side.rotated(angle)*stroke.reach*u+Vector2(0,sin(u*PI)*sin(t*PI)*stroke.reach*0.22))
		g.draw_polyline(points,Color("405455"),10 if g.evolved.has("chain") else 8,true)
		g.draw_polyline(points,Color("e2d7b8"),4,true)
		for n in range(1,13,2): g.draw_arc(points[n],6,0,TAU,8,Color("82958b"),2,true)
		if t>0.12 and t<0.8: g.atlas_draw(g.effects,10,points[-1],Vector2(85,35),4,4,side.angle()+angle,Color(0.95,0.88,0.66,0.8*(1-t)))
	for orbit in a.orbits:
		for n in int(orbit.count):
			var angle:float=orbit.age*orbit.speed+TAU*n/orbit.count+orbit.phase
			var pos:Vector2=g.player+Vector2.from_angle(angle)*g.orbit_radius()
			g.draw_bowl(pos,orbit.radius/22*1.3)
			if not g.presentation.low_fx:
				g.atlas_draw(g.effects,10,pos-Vector2.from_angle(angle+PI/2)*25,Vector2(50,25),4,4,angle+PI/2,Color(0.9,0.8,0.6,0.5))
	if g.upgrades.get("kelp",0)>0:
		var radius:float=a.stats("kelp").radius
		var pulse:float=0.5+0.5*sin(g.elapsed*5)
		g.draw_arc(g.player,radius*0.9,0,TAU,32,Color(0.4,0.65,0.4,0.18+pulse*0.12),3,true)
		for n in 6:
			var angle:float=TAU*n/6+sin(g.elapsed*2)*0.08
			g.atlas_draw(g.effects,6,g.player+Vector2.from_angle(angle)*radius*0.78,Vector2(55,75+pulse*18),4,4,angle+sin(g.elapsed*4+n)*0.15,Color(1,1,1,0.8))
	var decorated_flights:=0
	for z in a.flights:
		if not g.on_screen(z.pos,450): continue
		draw_flight(z,decorated_flights<(4 if g.presentation.low_fx else 12))
		decorated_flights+=1
	for z in a.zones:
		if not g.on_screen(z.pos,450): continue
		if z.delay>0: draw_flight(z); continue
		var t:float=clampf(z.age/maxf(0.01,z.total),0,1)
		if z.kind=="rain":
			g.atlas_draw(g.effects,4,z.pos,Vector2.ONE*z.radius*2.3,4,4,z.age*0.12,Color(0.65,0.9,1,0.55))
			g.draw_item(35,z.pos+Vector2(0,-110),Vector2(95,78),sin(z.age*4)*0.04)
			if not g.presentation.low_fx:
				for n in 6:
					var drop:Vector2=z.pos+Vector2(sin(n*2.4)*z.radius,fmod(z.age*300+n*23,120)-125)
					g.draw_line(drop,drop+Vector2(-6,23),Color(0.7,0.9,0.9,0.75),3,true)
		elif z.kind=="impact":
			g.draw_tetrapod(z.pos,1.1-t*0.12,Color.WHITE)
			draw_impact(z.pos,"tetra",t,g.evolved.has("tetra"),z.radius)
		elif z.kind=="bird": draw_impact(z.pos,str(z.weapon),t,str(z.weapon)=="gull_union",z.radius)
		else: draw_impact(z.pos,str(z.weapon),t,g.evolved.has(str(z.weapon)),z.radius)
	for id in ["gull_white","gull_dark","gull_union"]:
		if g.upgrades.get(id,0)<=0: continue
		for direction in ([-1,1] if id=="gull_union" else [1]):
			var pos:=bird_origin(id,direction)
			var flap:=sin(g.elapsed*13)*0.15
			g.draw_item(int(a.stats(id).icon),pos,Vector2(96,76+sin(g.elapsed*13)*12),flap)
	if g.upgrades.get("wing_union",0)>0:
		var s:Dictionary=a.stats("wing_union")
		if fmod(g.elapsed,s.cooldown+1.0)<=1.0:
			var count:int=s.amount+mini(10,maxi(0,g.upgrades.get("revive",0)-g.revivals_used))
			for n in count:
				var dir:=Vector2.from_angle(g.elapsed*s.speed+TAU*n/count)
				g.atlas_draw(g.effects,5,g.player+dir*450,Vector2(900,s.radius*4.5),4,4,dir.angle(),Color(0.55,0.85,0.85,0.65))
				g.atlas_draw(g.effects,5,g.player+dir*450,Vector2(900,s.radius*1.2),4,4,dir.angle(),Color(1,0.98,0.8,0.9))
	if a.shield_charges>0:
		var pulse:float=1+sin(g.elapsed*3)*0.025
		g.atlas_draw(g.effects,15,g.player+Vector2(0,-24),Vector2(148,148)*pulse,4,4,g.elapsed*0.08,Color(0.9,1,0.9,0.65))
		g.draw_item(42,g.player+Vector2(0,-105),Vector2(43,43),sin(g.elapsed*2)*0.08)
		g.draw_string(g.hud.font,g.player+Vector2(23,-95),str(a.shield_charges),HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("334637"))
	draw_events()
