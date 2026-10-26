extends RefCounted

# Bold coastal effects. Geometry and decoration never change damage or hitboxes.
# All lifetimes/counts are bounded; no per-projectile nodes, lights or shaders.
var g: Node2D
var events: Array[Dictionary]=[]
var clocks: Dictionary={}
var last_shake:=-1.0
var recoil:=Vector2.ZERO
var recoil_time:=0.0
const FOAM:=Color("fff4d8")

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

func event(id: String,pos: Vector2,dir: Vector2=Vector2.RIGHT,kind: String="launch",size: float=100) -> void:
	var key:=id+"/"+kind
	if g.elapsed<float(clocks.get(key,-1)): return
	clocks[key]=g.elapsed+(0.13 if kind=="hit" else 0.085)
	if events.size()>=(10 if g.presentation.light_effects() else 24): return
	events.append({"id":id,"pos":pos,"dir":dir,"kind":kind,"size":size,"age":0.0,"life":0.32 if kind=="launch" else 0.44})

func launch(id: String,pos: Vector2,dir: Vector2) -> void:
	event(id,pos+dir*35+Vector2(0,-16),dir,"launch",145 if id=="wave" else 100)
	if id in ["sand","wave","chain","tetra"]:
		recoil=dir*7
		recoil_time=0.12

func hit(e: Dictionary,id: String,knock: Vector2) -> void:
	var heavy:bool=id in ["tetra","chain","wave","shell","gull_union","heat","anchor"]
	var dir:Vector2=knock.normalized() if knock.length_squared()>0 else (e.pos-g.player).normalized()
	e.fx_jolt=dir*(12 if heavy else 6)
	if heavy and g.elapsed-last_shake>=0.20:
		last_shake=g.elapsed
		if not g.presentation.reduced_motion: g.shake=maxf(g.shake,3.8)
		g.presentation.sound("impact_heavy")
	elif not heavy: g.presentation.sound("impact_light")

func colour(id: String) -> Color:
	if id in ["sand","shell","snack","heat"]: return Color("f4ba50")
	if id in ["chain","stone","tetra","anchor","bowl"]: return Color("69c6bd")
	if id=="kelp": return Color("8bd867")
	if id in ["gull_dark","gust"]: return Color("ae9ee8")
	if id in ["feather","gull_white","gull_union","wing_union"]: return Color("ffdc88")
	return Color("55d6e9")

func fade(c: Color,alpha: float) -> Color:
	return Color(c.r,c.g,c.b,clampf(alpha,0,1))

func spark(target: Node2D,pos: Vector2,size: float,c: Color,angle: float=0) -> void:
	if size<1.0 or c.a<=0.01: return
	var points:=PackedVector2Array()
	for i in 8:
		points.append(pos+Vector2.from_angle(angle+i*PI/4)*size*(1.0 if i%2==0 else 0.22))
	target.draw_colored_polygon(points,c)

func ribbon(target: Node2D,start: Vector2,finish: Vector2,width: float,c: Color) -> void:
	var side:Vector2=(finish-start).normalized().orthogonal()*width*0.5
	target.draw_colored_polygon(PackedVector2Array([start,finish+side,finish-side]),c)

func stream(target: Node2D,start: Vector2,dir: Vector2,length_value: float,width: float,c: Color,phase: float) -> void:
	var points:=PackedVector2Array()
	var side:=dir.orthogonal()
	for sign_value in [1,-1]:
		for n in (range(9) if sign_value==1 else range(7,0,-1)):
			var u:float=n/8.0
			var envelope:=pow(maxf(0,sin(u*PI)),0.45)
			var center:Vector2=start+dir*length_value*u+side*sin(u*TAU*2-phase)*width*0.10*envelope
			points.append(center+side*envelope*width*0.5*sign_value)
	target.draw_colored_polygon(points,c)

func burst(target: Node2D,pos: Vector2,c: Color,t: float,size: float,detailed: bool=true) -> void:
	var alpha:=pow(maxf(0,1-t),1.3)
	var r:=size*(0.20+sqrt(maxf(0,t))*0.60)
	target.draw_circle(pos,r*0.74,fade(c,alpha*0.18))
	target.draw_arc(pos,r,0,TAU,24,fade(c,alpha*0.85),maxf(2,size*0.09*(1-t)),true)
	target.draw_arc(pos,r*0.80,0.3,TAU-0.4,20,fade(FOAM,alpha*0.95),maxf(2,size*0.035*(1-t)),true)
	if t<0.4: spark(target,pos,size*(0.55-t),fade(FOAM,1-t/0.4),PI/4)
	if detailed:
		for n in 5:
			var dir:=Vector2.from_angle(n*TAU/5+0.3)
			ribbon(target,pos+dir*r*0.75,pos+dir*r*(1.45-t*0.15),size*0.11*(1-t),fade(c,alpha))

func draw_impact(pos: Vector2,id: String,progress: float,evolved: bool=false,radius: float=0) -> void:
	paint_impact(g,pos,id,progress,evolved,radius)

func paint_impact(target: Node2D,pos: Vector2,id: String,progress: float,evolved: bool=false,radius: float=0) -> void:
	var heavy:bool=id in ["tetra","wave","shell","chain","gull_union","heat","anchor"]
	var size:=maxf(radius*1.9,155 if heavy else 94)*(1.16 if evolved else 1.0)
	burst(target,pos,colour(id),clampf(progress,0,1),size,not g.presentation.light_effects())

func quick_impact(pos: Vector2,id: String,t: float,radius: float) -> void:
	var size:=maxf(50,radius)*(0.35+sqrt(maxf(0,t))*0.9)
	g.draw_arc(pos,size,0,TAU,16,fade(colour(id),1-t),maxf(3,14*(1-t)),true)
	if t<0.5: spark(g,pos,size*0.8,fade(FOAM,1-t*2),PI/4)

func draw_events() -> void:
	for v in events:
		if not g.on_screen(v.pos,220): continue
		var t:float=v.age/v.life
		if v.kind=="hit": draw_impact(v.pos,v.id,t,g.evolved.has(str(v.id)),v.size); continue
		var c:=colour(v.id)
		var dir:Vector2=v.dir
		var pos:Vector2=v.pos+dir*(15+t*30)
		g.draw_arc(pos,v.size*(0.18+t*0.3),dir.angle()-1.2,dir.angle()+1.2,16,fade(c,1-t),12*(1-t)+2,true)
		spark(g,pos,v.size*(0.38*(1-t)),fade(FOAM,1-t),dir.angle())

func bird_origin(id: String,direction: int=1) -> Vector2:
	var s:Dictionary=g.arsenal.stats(id)
	var sign_value:float=-1 if id=="gull_dark" else direction
	return g.player+Vector2.from_angle(g.elapsed*float(s.speed)*sign_value)*185+Vector2(0,-105)

func draw_flight(z: Dictionary,decorated: bool=true) -> void:
	var flight:float=z.get("flight",0.0)
	if flight<=0 or z.delay>flight: return
	var t:=clampf(1-z.delay/flight,0,1)
	var start:Vector2=z.get("origin",z.pos+Vector2(0,-380))
	var pos:Vector2=start.lerp(z.pos,t*t if z.kind=="impact" else t)
	if z.kind=="bird": pos.y-=sin(t*PI)*70
	var c:=colour(str(z.weapon))
	g.draw_arc(z.pos,z.radius*(0.55+t*0.4),0,TAU,20,fade(c,0.35+t*0.35),5,true)
	if decorated:
		var dir:Vector2=(z.pos-start).normalized()
		ribbon(g,pos-dir*115,pos,32,fade(c,0.65))
		g.draw_line(pos-dir*50,pos,FOAM,7,true)
	if z.kind=="impact":
		g.draw_tetrapod(pos,1.8,Color.WHITE)
	else:
		g.draw_circle(pos,23,fade(c,0.48))
		spark(g,pos,33,FOAM,g.elapsed*3)
		g.draw_item(35 if z.kind=="rain" else 8,pos,Vector2(44,44),t*3)

func missile(b: Dictionary,decorate: bool) -> void:
	var pos:Vector2=b.pos+Vector2(0,-20)
	var dir:Vector2=b.velocity.normalized()
	var id:String=b.weapon
	var evolved:bool=g.evolved.has(id)
	var size:float=maxf(44,b.radius*3.5)*(1.13 if evolved else 1)
	var c:=colour(id)
	if decorate:
		ribbon(g,pos-dir*size*2.7,pos,size*0.84,fade(c,0.50))
		g.draw_line(pos-dir*size*1.4,pos,fade(FOAM,0.85),size*0.19,true)
	if id=="wave":
		var angle:=dir.angle()
		var crest:=size*0.92
		g.draw_arc(pos-dir*size*0.24,crest,angle-1.22,angle+1.22,20,Color("216c91"),size*0.74,true)
		g.draw_arc(pos-dir*size*0.24,crest,angle-1.22,angle+1.22,20,c,size*0.48,true)
		g.draw_arc(pos-dir*size*0.24,crest,angle-1.22,angle+1.22,20,FOAM,size*0.15,true)
	elif id in ["feather","gust"]:
		ribbon(g,pos-dir*size,pos+dir*size*0.65,size*0.85,c)
		ribbon(g,pos-dir*size*0.7,pos+dir*size*0.65,size*0.30,FOAM)
		g.draw_item(b.icon,pos,Vector2(size*0.8,size*0.6),dir.angle())
	else:
		g.draw_circle(pos,size*0.48,fade(c,0.35))
		if id in ["shell","snack","stone"]:
			g.draw_arc(pos,size*0.55,b.age*12,b.age*12+PI*1.5,16,c,7,true)
		var angle:float=b.age*11 if id in ["shell","snack","stone"] else dir.angle()
		g.draw_item(b.icon,pos,Vector2.ONE*size,angle)
		if id=="pearl": spark(g,pos,size*0.40,fade(FOAM,0.9),b.age*5)

func draw_chain(a: RefCounted) -> void:
	for stroke in a.strokes:
		if stroke.delay>0: continue
		var t:=clampf(stroke.age/0.28,0,1)
		var side:Vector2=stroke.dir
		var origin:Vector2=g.player+stroke.offset
		var angle:float=(-0.95*(1-t/0.36) if t<0.36 else 0.55*(t-0.36)/0.64)*(1 if side.x>=0 else -1)
		var aim_angle:float=side.angle()+angle
		var reach:float=stroke.reach
		var c:=Color("ffd280") if g.evolved.has("chain") else colour("chain")
		g.draw_arc(origin,reach*0.78,aim_angle-0.65,aim_angle+0.18,20,fade(c,0.65*(1-t)),reach*0.30,true)
		g.draw_arc(origin,reach*0.94,aim_angle-0.65,aim_angle+0.18,20,fade(FOAM,1-t),8,true)
		var points:=PackedVector2Array()
		for n in 10:
			var u:=n/9.0
			points.append(origin+side.rotated(angle)*reach*u+Vector2(0,sin(u*PI)*sin(t*PI)*reach*0.20))
		g.draw_polyline(points,Color("314d56"),18,true)
		g.draw_polyline(points,c,10,true)
		g.draw_polyline(points,FOAM,3,true)
		for n in range(1,10,2): g.draw_arc(points[n],8,0,TAU,8,Color("334637"),3,true)
		spark(g,points[-1],40*(1-t)+8,FOAM,aim_angle)

func draw_arsenal() -> void:
	var a:RefCounted=g.arsenal
	var light:bool=g.presentation.light_effects()
	var trails:=0
	if a.heat_visual>0:
		var t:float=1-a.heat_visual/0.7
		burst(g,g.player,Color("ffb34d"),t,950,false)
		g.draw_item(37,g.player+Vector2(0,-140-t*70),Vector2.ONE*(240+t*90),0,fade(FOAM,1-t))
	for b in g.bullets:
		if not g.on_screen(b.pos,180): continue
		missile(b,trails<(12 if light else 30))
		trails+=1
	draw_chain(a)
	var orbit_trails:=0
	for orbit in a.orbits:
		for n in int(orbit.count):
			var angle:float=orbit.age*orbit.speed+TAU*n/orbit.count+orbit.phase
			var radius:float=g.orbit_radius()
			var pos:Vector2=g.player+Vector2.from_angle(angle)*radius
			if orbit_trails<(6 if light else 18):
				g.draw_arc(g.player,radius,angle-0.65,angle,12,fade(colour("bowl"),0.6),17,true)
				g.draw_arc(g.player,radius,angle-0.35,angle,10,FOAM,5,true)
				orbit_trails+=1
			g.draw_bowl(pos,orbit.radius/22*1.65)
	if g.upgrades.get("kelp",0)>0:
		var radius:float=a.stats("kelp").radius
		var pulse:=0.5+0.5*sin(g.elapsed*5)
		g.draw_circle(g.player,radius*0.88,Color(0.22,0.65,0.32,0.10))
		g.draw_arc(g.player,radius*0.88,0,TAU,36,fade(colour("kelp"),0.5+pulse*0.2),11,true)
		for n in 6:
			var angle:float=TAU*n/6+g.elapsed*0.15
			var pos:Vector2=g.player+Vector2.from_angle(angle)*radius*0.78
			ribbon(g,pos-Vector2(0,65+pulse*30),pos,28,fade(colour("kelp"),0.85))
			g.draw_item(int(a.stats("kelp").icon),pos,Vector2(65,80+pulse*20),sin(g.elapsed*4+n)*0.15)
	var decorated:=0
	for z in a.flights:
		if not g.on_screen(z.pos,450): continue
		draw_flight(z,decorated<(4 if light else 12))
		decorated+=1
	var detailed_zones:=0
	for z in a.zones:
		if not g.on_screen(z.pos,450): continue
		if z.delay>0: draw_flight(z,not light); continue
		var t:=clampf(z.age/maxf(0.01,z.total),0,1)
		if z.kind!="rain" and detailed_zones>=(6 if light else 18):
			quick_impact(z.pos,str(z.weapon),t,z.radius)
			continue
		detailed_zones+=1
		if z.kind=="rain":
			g.draw_circle(z.pos,z.radius,Color(0.15,0.50,0.7,0.16))
			g.draw_arc(z.pos,z.radius*(0.75+sin(z.age*7)*0.05),0,TAU,24,Color("71d1e7"),9,true)
			g.draw_item(35,z.pos+Vector2(0,-135),Vector2(130,95),sin(z.age*4)*0.06)
			for n in (3 if light else 6):
				var phase:float=fmod(z.age*2.5+n*0.17,1)
				var pos:Vector2=z.pos+Vector2(sin(n*2.4)*z.radius*0.8,-150+phase*150)
				g.draw_line(pos,pos+Vector2(-12,42),Color("b9eff0"),7,true)
		elif z.kind=="impact":
			g.draw_tetrapod(z.pos,1.7-t*0.22,Color.WHITE)
			draw_impact(z.pos,"tetra",t,g.evolved.has("tetra"),z.radius)
		else: draw_impact(z.pos,str(z.weapon),t,g.evolved.has(str(z.weapon)),z.radius)
	for id in ["gull_white","gull_dark","gull_union"]:
		if g.upgrades.get(id,0)<=0: continue
		for direction in ([-1,1] if id=="gull_union" else [1]):
			var pos:=bird_origin(id,direction)
			g.draw_arc(pos,48,g.elapsed*4,g.elapsed*4+PI,12,fade(colour(id),0.65),8,true)
			g.draw_item(int(a.stats(id).icon),pos,Vector2(112,84+sin(g.elapsed*13)*15),sin(g.elapsed*13)*0.15)
	if g.upgrades.get("wing_union",0)>0:
		var s:Dictionary=a.stats("wing_union")
		if fmod(g.elapsed,s.cooldown+1.0)<=1.0:
			var count:int=s.amount+mini(10,maxi(0,g.upgrades.get("revive",0)-g.revivals_used))
			for n in count:
				var dir:=Vector2.from_angle(g.elapsed*s.speed+TAU*n/count)
				var start:Vector2=g.player+Vector2(0,-20)+dir*65
				stream(g,start,dir,835,s.radius*5,Color(0.25,0.80,0.85,0.20),g.elapsed*16)
				stream(g,start,dir,835,s.radius*2.7,Color("5ed6dc"),g.elapsed*16)
				stream(g,start,dir,835,s.radius*0.72,FOAM,g.elapsed*16)
				var surge:Vector2=start+dir*(100+fmod(g.elapsed*850+n*80,680))
				g.draw_arc(surge,s.radius*1.6,dir.angle()-1.1,dir.angle()+1.1,12,FOAM,6,true)
				spark(g,g.player+dir*(180+fmod(g.elapsed*650,650)),35,FOAM,dir.angle())
	if a.shield_charges>0:
		var pos:Vector2=g.player+Vector2(0,-24)
		g.draw_circle(pos,72,Color(0.25,0.70,0.7,0.12))
		for n in 3:
			var angle:float=g.elapsed*0.6+n*TAU/3
			g.draw_arc(pos,72,angle,angle+1.7,16,Color("80ddd2"),10,true)
			g.draw_arc(pos,78,angle,angle+1.2,12,FOAM,3,true)
		g.draw_item(42,g.player+Vector2(0,-112),Vector2(54,54),sin(g.elapsed*2)*0.08)
		g.draw_string(g.hud.font,g.player+Vector2(27,-100),str(a.shield_charges),HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("334637"))
	draw_events()

func draw_water() -> void:
	var origin:Vector2=g.player+Vector2(0,-24)
	var dir:Vector2=g.aim
	var length_value:=maxf(30,g.water_reach)
	var width:=30+length_value*0.35
	var finish:=origin+dir*length_value
	ribbon(g,origin,finish,width*1.55,Color(0.15,0.57,0.78,0.45))
	ribbon(g,origin,finish,width,Color("55cddd"))
	ribbon(g,origin,finish,width*0.38,FOAM)
	for n in (3 if g.presentation.light_effects() else 5):
		var t:float=fmod(g.elapsed*3+n*0.2,1)
		g.draw_arc(origin+dir*length_value*t,maxf(10,width*t*0.42),dir.angle()-1.1,dir.angle()+1.1,12,fade(FOAM,1-t*0.65),7,true)
	spark(g,origin+dir*20,28+sin(g.elapsed*30)*5,FOAM,dir.angle())

func draw_dash() -> void:
	for ghost in g.dash_ghosts:
		var t:float=ghost.life/0.22
		g.atlas_draw(g.hero_atlas,int(ghost.index),ghost.pos+Vector2(0,-34),Vector2(108,108),4,2,0,Color(0.3,0.9,1,t*0.48))
	if g.dash_time>0:
		var pos:Vector2=g.player+Vector2(0,-20)
		ribbon(g,pos-g.dash_dir*140,pos,70,Color(0.2,0.8,0.9,0.45))
		g.draw_arc(pos,45,g.dash_dir.angle()-1.4,g.dash_dir.angle()+1.4,18,FOAM,9,true)
	if g.magnet_visual>0:
		var t:float=1-g.magnet_visual/0.75
		g.draw_arc(g.player,50+(1-t)*240,0,TAU,36,Color(0.5,0.88,0.82,(1-t)*0.8),10,true)
