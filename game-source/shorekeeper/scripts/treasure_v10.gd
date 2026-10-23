extends Node2D

# The reward transaction is already committed by game.gd. This is presentation only.
var g: Node2D
var h: CanvasLayer
var confirm: Button
var rows: Array[Label]=[]
var steps: Array[int]=[]
var stopped: Array[bool]=[]
var final_sound:=false
var reward_texts:Array[String]=[]
var reward_icons:Array[int]=[]

func _ready() -> void:
	reward_texts.assign(g.last_boss_rewards)
	reward_icons.assign(g.last_reward_icons)
	var count:int=reward_texts.size()
	confirm=h.button("빛이 모이고 있어요…",Rect2(320,598,580,62),self,func():g.close_treasure(),true)
	confirm.add_theme_font_override("font",h.font)
	confirm.disabled=true
	for i in count:
		steps.append(-1)
		stopped.append(false)
		var spacing:float=200 if count==5 else 290
		var x:float=610+(i-(count-1)*0.5)*spacing
		var row:Label=h.label(reward_texts[i],Rect2(x-spacing/2+8,378,spacing-16,95),25,h.INK,self)
		row.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		row.add_theme_font_override("font",h.font)
		row.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		row.visible=false
		rows.append(row)

func _process(_dt: float) -> void:
	if not is_instance_valid(h.modal) or not h.modal.is_ancestor_of(self): return
	var t:float=g.treasure_clock
	for i in rows.size():
		var stop:float=2.4+i*0.28
		var u:float=clampf((t-0.5)/(stop-0.5),0,1)
		var step:int=int(25*(1-pow(1-u,2.7)))
		if step!=steps[i] and t>=0.5 and t<stop:
			steps[i]=step
			g.presentation.sound("reel_tick")
		if t>=stop and not stopped[i]:
			stopped[i]=true
			rows[i].visible=true
			g.presentation.sound("reel_stop",true)
	if t>=2.6+reward_texts.size()*0.28:
		confirm.disabled=false
		confirm.text="보물 챙기고 계속하기 →"
		if not final_sound:
			final_sound=true
			g.presentation.sound("evolve" if reward_texts.any(func(s):return s.begins_with("진화")) else "treasure_%d"%rows.size(),true)
	queue_redraw()

func text_center(text: String,y: float,size: int,color: Color) -> void:
	var width:float=h.font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	draw_string(h.font,Vector2(610-width/2,y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func item(index: int,rect: Rect2) -> void:
	draw_texture_rect_region(g.item_atlas(index),rect,g.item_region(index))

func _draw() -> void:
	if not is_instance_valid(h.modal) or not h.modal.is_ancestor_of(self): return
	var t:float=g.treasure_clock
	var count:int=reward_texts.size()
	var evolved:bool=reward_texts.any(func(s):return s.begins_with("진화"))
	var gold:=Color("ebbe60")
	text_center("새로운 파도로 진화!" if evolved else "파도가 가져온 보물 · %d개"%count,65,42,h.INK)
	text_center("상자가 품고 있던 빛이 깨어납니다" if t<2.6+count*0.28 else "이번 항해에 더해진 힘",104,25,h.MUTED)
	var chest:=Vector2(610,514)
	var rays:int=10+count*3
	for j in rays:
		var angle:float=TAU*j/rays+t*0.12
		var length:float=(125+count*22)*minf(1,t*2)
		draw_line(chest+Vector2.from_angle(angle)*45,chest+Vector2.from_angle(angle)*length,Color(0.95,0.77,0.36,0.15),8,true)
	# Analytic decorative coins: fixed budget; never added to gameplay currency.
	var budget:int=18 if g.presentation.low_fx else 28+count*8
	for j in budget:
		var age:float=fposmod(t+j*0.087,1.7)
		var vx:float=sin(j*12.98)*(160+count*20)
		var pos:Vector2=chest+Vector2(vx*age,-(160+j%5*24)*age+180*age*age)
		if age>t: continue
		draw_circle(pos,6,Color("627153"))
		draw_circle(pos,4.5,gold)
		draw_line(pos+Vector2(0,-3),pos+Vector2(0,3),Color("fff1a5"),2)
	var cell:Vector2=Vector2(g.effects.get_width()/4.0,g.effects.get_height()/4.0)
	var frame:int=12 if t<0.35 else 13
	draw_texture_rect_region(g.effects,Rect2(chest-Vector2(62,55),Vector2(124,110)),Rect2(Vector2(frame%4,frame/4)*cell,cell))
	for i in count:
		var spacing:float=200 if count==5 else 290
		var goal:=Vector2(610+(i-(count-1)*0.5)*spacing,281)
		var progress:float=clampf((t-i*0.09)/0.65,0,1)
		var pos:Vector2=chest.lerp(goal,1-pow(1-progress,3))
		var radius:float=68+count*2
		for ring in range(3,0,-1):
			draw_circle(pos,radius+ring*9,Color(1,0.81,0.35,0.055*progress))
		draw_circle(pos,radius,Color(1,0.93,0.68,0.93*progress))
		draw_arc(pos,radius,0,TAU,36,gold,3,true)
		if count>=3:
			for star in 5:
				var sp:Vector2=pos+Vector2.from_angle(t*0.5+TAU*star/5)*(radius+12)
				draw_line(sp-Vector2(5,0),sp+Vector2(5,0),gold,2)
				draw_line(sp-Vector2(0,5),sp+Vector2(0,5),gold,2)
		var box:=Rect2(pos-Vector2(44,44),Vector2(88,88))
		draw_style_box(h.style(Color("faf0d8"),8,gold if stopped[i] else h.MUTED),box)
		var index:int=reward_icons[i] if i<reward_icons.size() else 27
		if not stopped[i]:
			var candidates:Array=g.catalog
			index=int(candidates[(maxi(0,steps[i])*7+i*11)%candidates.size()].icon)
		item(index,box.grow(-9))
		if stopped[i]:
			var pulse:float=maxf(0,1-(t-(2.4+i*0.28))*2)
			draw_arc(pos,radius+18*pulse,0,TAU,36,Color(1,0.85,0.4,pulse),4,true)
