extends CanvasLayer

const INK:=Color("334637")
const MUTED:=Color("758069")
const CREAM:=Color("faf0d8")
const GOLD:=Color("d9ae62")
var game: Node2D
var root: Control
var modal: Control
var xp_bar: ProgressBar
var level_label: Label
var clock_label: Label
var notice: Label
var stats: Label
var equipment: Control
var equipment_signature:=""
var font: Font=preload("res://assets/hand.ttf")
var sound_button: Button
var xp_frame: Panel
var compact:=false

func _ready() -> void:
	font.fallbacks=[preload("res://assets/korean.ttf")]
	root=Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var theme:=Theme.new()
	theme.default_font=font
	theme.default_font_size=23
	root.theme=theme
	add_child(root)
	xp_frame=panel(Rect2(18,14,1244,29),Color("3d5949"),root)
	xp_bar=bar(Rect2(25,20,1112,16),Color("83c5b5"),root)
	level_label=label("LV. 01",Rect2(1144,10,110,32),24,CREAM,root)
	level_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	clock_label=label("00:00",Rect2(525,45,230,48),38,INK,root)
	clock_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	clock_label.add_theme_color_override("font_shadow_color",Color("faf0d8"))
	clock_label.add_theme_constant_override("shadow_outline_size",5)
	stats=label("",Rect2(26,48,240,34),22,INK,root)
	equipment=Control.new()
	equipment.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(equipment)
	sound_button=button("♪",Rect2(1163,48,42,36),root,func():show_settings())
	button("Ⅱ",Rect2(1214,48,42,36),root,func():game.toggle_pause())
	notice=label("",Rect2(300,102,680,34),25,INK,root)
	notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	notice.add_theme_color_override("font_shadow_color",CREAM)
	notice.add_theme_constant_override("shadow_outline_size",6)
	get_viewport().size_changed.connect(resize_layout)
	resize_layout(false)
	var warning=load("res://scripts/boss_warning_v10.gd").new()
	warning.g=game
	warning.h=self
	root.add_child(warning)

func resize_layout(rebuild: bool=true) -> void:
	var view:=get_viewport().get_visible_rect().size
	compact=get_window().size.y<500
	root.scale=Vector2.ONE
	root.position=Vector2.ZERO
	xp_frame.size.x=view.x-36
	xp_bar.size.x=view.x-168
	level_label.position.x=view.x-136
	clock_label.position.x=view.x/2-115
	sound_button.position.x=view.x-117
	for child in root.get_children():
		if child is Button and child.text=="Ⅱ": child.position.x=view.x-66
	notice.position.x=view.x/2-340
	if not rebuild or not is_instance_valid(modal): return
	match game.state:
		"title": show_start()
		"levelup": show_choices(game.selected_options)
		"paused": show_pause()
		"treasure": show_treasure(game.last_boss_rewards)
		"blessing": show_blessings(game.selected_options)
		"won","lost": show_end(game.state=="won")

func style(color: Color,radius: int=9,border: Color=Color("6b7152")) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new()
	s.bg_color=color
	s.set_corner_radius_all(radius)
	s.set_border_width_all(2)
	s.border_color=border
	s.shadow_color=Color(0.14,0.2,0.13,0.2)
	s.shadow_offset=Vector2(0,3)
	s.shadow_size=3
	return s

func panel(rect: Rect2,color: Color,parent: Node) -> Panel:
	var p:=Panel.new()
	p.position=rect.position
	p.size=rect.size
	p.add_theme_stylebox_override("panel",style(color))
	p.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p

func label(text: String,rect: Rect2,size: int,color: Color,parent: Node) -> Label:
	var l:=Label.new()
	l.text=text
	l.position=rect.position
	l.size=rect.size
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",color)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func button(text: String,rect: Rect2,parent: Node,callback: Callable,primary: bool=false) -> Button:
	var b:=Button.new()
	b.action_mode=BaseButton.ACTION_MODE_BUTTON_PRESS
	b.text=text
	b.position=rect.position
	b.size=rect.size
	b.add_theme_font_size_override("font_size",24)
	b.add_theme_color_override("font_color",CREAM if primary else INK)
	b.add_theme_color_override("font_hover_color",INK)
	b.add_theme_stylebox_override("normal",style(INK if primary else CREAM))
	b.add_theme_stylebox_override("hover",style(Color("e8d29f"),9,GOLD))
	b.add_theme_stylebox_override("pressed",style(Color("d5bc84")))
	b.add_theme_stylebox_override("focus",style(Color(0,0,0,0),9,GOLD))
	b.pressed.connect(callback)
	b.pressed.connect(func():game.presentation.sound("ui"))
	parent.add_child(b)
	return b

func bar(rect: Rect2,color: Color,parent: Node) -> ProgressBar:
	var b:=ProgressBar.new()
	b.position=rect.position
	b.size=rect.size
	b.show_percentage=false
	b.mouse_filter=Control.MOUSE_FILTER_IGNORE
	b.add_theme_stylebox_override("background",style(Color("405b50"),4,Color("405b50")))
	b.add_theme_stylebox_override("fill",style(color,4,color))
	parent.add_child(b)
	return b

func icon(index: int,rect: Rect2,parent: Node) -> TextureRect:
	var r:=TextureRect.new()
	var a:=AtlasTexture.new()
	a.atlas=game.item_atlas(index)
	a.region=game.item_region(index)
	if index==31:
		a.atlas=game.hero_atlas
		a.region=Rect2(0,0,game.hero_atlas.get_width()/4.0,game.hero_atlas.get_height()/2.0)
	r.texture=a
	r.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.position=rect.position
	r.size=rect.size
	r.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r

func clear_modal() -> void:
	if is_instance_valid(modal):
		modal.queue_free()
		modal=null

func modal_base() -> Panel:
	clear_modal()
	modal=Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)
	var shade:=ColorRect.new()
	shade.color=Color(0.07,0.17,0.13,0.8)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	var view:=get_viewport().get_visible_rect().size
	return panel(Rect2((view-Vector2(1220,690))/2,Vector2(1220,690)),CREAM,modal)

func equipment_row(parent: Node,origin: Vector2,kind: String,cell_size: float=42) -> void:
	var items: Array=game.owned_items(kind)
	for i in items.size():
		var u: Dictionary=items[i]
		var pos:=origin+Vector2(i*cell_size,0)
		panel(Rect2(pos,Vector2.ONE*(cell_size-3)),Color("e7ddbd"),parent)
		icon(int(u.icon),Rect2(pos+Vector2(3,1),Vector2.ONE*(cell_size-9)),parent)
		var amount:int=game.upgrades.get(str(u.id),0)
		var text:="★" if game.evolved.has(str(u.id)) and str(u.id)!="gull_union" else str(amount)
		var l:=label(text,Rect2(pos+Vector2(22,21),Vector2(17,20)),17,CREAM,parent)
		l.add_theme_color_override("font_outline_color",INK)
		l.add_theme_constant_override("outline_size",5)

func stats_sidebar(p: Node) -> void:
	var side:=panel(Rect2(20,95,290,570),Color("e9e5cd"),p)
	label("테포의 가방",Rect2(14,5,250,28),25,INK,side)
	equipment_row(side,Vector2(15,36),"weapon",42)
	equipment_row(side,Vector2(15,81),"passive",42)
	label("무기 %d/6 · 패시브 %d/6"%[game.owned_items("weapon").size(),game.owned_items("passive").size()],Rect2(15,126,260,30),21,MUTED,side)
	var rows: Array=game.stats_rows()
	for i in rows.size():
		var row: Array=rows[i]
		var y:=166+i*23
		icon(int(row[2]),Rect2(13,y,23,23),side)
		label(str(row[0]),Rect2(43,y,155,24),21,INK,side)
		var value:=label(str(row[1]),Rect2(191,y,83,24),21,INK,side)
		value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT

func show_start() -> void:
	var p:=modal_base()
	label("부산 바다의 작은 수호자",Rect2(55,40,700,38),28,MUTED,p)
	label("테포, 파도를 지켜라",Rect2(50,115,850,82),62,INK,p)
	label("광안리의 모래와 파도, 그리고 뚝배기 하나.",Rect2(55,230,780,45),31,INK,p)
	label("밀려오는 해양 크리처와 선을 넘는 진상들.\n무기를 모으고 진화시키며 30분 동안 바다를 지켜주세요.",Rect2(55,297,770,90),27,MUTED,p)
	button("출항하기  →",Rect2(55,452,400,67),p,func():game.start_game();game.offer_blessing(),true)
	button("출항 준비  ·  %d 코인"%game.harbor_coins,Rect2(480,452,335,67),p,func():show_harbor())
	label("WASD / 방향키 이동 · 자동 공격 · M 마우스 조준 · ESC 가방",Rect2(55,575,1040,38),23,MUTED,p)
	icon(31,Rect2(825,220,325,325),p)
	button("소리 · 화면 설정",Rect2(875,452,285,67),p,func():show_settings())

func show_choices(options: Array) -> void:
	var p:=modal_base()
	if compact:
		show_compact_choices(p,options)
		return
	label("성장의 물결  ·  LV. %02d"%game.level,Rect2(25,14,1000,52),40,INK,p)
	label("하나를 고르면 바다가 다시 움직입니다",Rect2(680,25,510,32),24,MUTED,p)
	stats_sidebar(p)
	for i in options.size():
		var u: Dictionary=options[i]
		var pos:=Vector2(335+(i%2)*430,106+(i/2)*238)
		var b:=button("",Rect2(pos,Vector2(412,221)),p,game.choose_upgrade.bind(str(u.id)))
		icon(int(u.get("icon",22)),Rect2(15,14,73,73),b)
		var weapon_id:=str(u.get("weapon",u.id))
		var category:=str(game.encounters.weapon_profiles[weapon_id].role) if game.encounters.weapon_profiles.has(weapon_id) else str(u.get("category","보너스"))
		label(category,Rect2(100,13,285,25),20,MUTED,b)
		label(str(u.name),Rect2(100,40,300,42),29,INK,b)
		var old:int=game.upgrades.get(str(u.get("weapon",u.id)),0)
		label("새로 획득" if old==0 else "레벨 %d → %d"%[old,old+1],Rect2(18,87,370,28),22,Color("a17c38"),b)
		var desc:=label(game.upgrade_preview(u),Rect2(18,120,378,54),21,INK,b)
		desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var recipe:=label(game.evolution_hint(u),Rect2(18,176,295,42),17,MUTED,b)
		recipe.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		if u.get("kind","") not in ["bonus"]:
			var banish:=button("제외",Rect2(323,184,72,29),b,game.banish_choice.bind(str(u.id)))
			banish.add_theme_font_size_override("font_size",19)
			banish.disabled=game.banishes<=0
	button("다시 뽑기  %d"%game.rerolls,Rect2(336,604,250,51),p,func():game.reroll_choices()).disabled=game.rerolls<=0
	button("건너뛰기  %d"%game.skips,Rect2(601,604,250,51),p,func():game.skip_choices()).disabled=game.skips<=0
	label("남은 제외 %d"%game.banishes,Rect2(887,613,290,35),23,MUTED,p)

func show_compact_choices(p: Panel,options: Array) -> void:
	label("성장의 물결 · LV.%02d"%game.level,Rect2(25,10,950,50),38,INK,p)
	for i in options.size():
		var u:Dictionary=options[i]
		var card:=button("",Rect2(25+(i%2)*600,80+(i/2)*250,575,235),p,game.choose_upgrade.bind(str(u.id)))
		icon(int(u.get("icon",22)),Rect2(15,15,70,70),card)
		label(str(u.name),Rect2(105,15,450,46),34,INK,card)
		var preview:=label(game.upgrade_preview(u),Rect2(20,88,535,80),27,INK,card)
		preview.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		var hint:=label(game.evolution_hint(u),Rect2(20,175,430,50),21,MUTED,card)
		hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		if u.get("kind","")!="bonus": button("제외",Rect2(470,179,88,40),card,game.banish_choice.bind(str(u.id))).disabled=game.banishes<=0
	button("다시 뽑기 %d"%game.rerolls,Rect2(25,602,360,60),p,func():game.reroll_choices()).disabled=game.rerolls<=0
	button("건너뛰기 %d"%game.skips,Rect2(425,602,360,60),p,func():game.skip_choices()).disabled=game.skips<=0
	button("누적 능력치",Rect2(825,602,360,60),p,func():show_choice_stats())

func show_choice_stats() -> void:
	var p:=modal_base()
	label("테포의 누적 능력치",Rect2(25,15,1100,55),38,INK,p)
	var rows:Array=game.stats_rows()
	for i in rows.size():
		var row:Array=rows[i]
		var pos:=Vector2(35+(i/9)*590,100+(i%9)*49)
		icon(int(row[2]),Rect2(pos,Vector2(35,35)),p)
		label("%s   %s"%[row[0],row[1]],Rect2(pos+Vector2(50,0),Vector2(500,45)),28,INK,p)
	button("선택지로 돌아가기",Rect2(25,600,1160,65),p,func():show_choices(game.selected_options),true)

func show_pause() -> void:
	var p:=modal_base()
	label("테포의 바다 수첩",Rect2(25,15,1050,55),40,INK,p)
	stats_sidebar(p)
	label("무기와 진화 수첩",Rect2(366,98,800,50),36,INK,p)
	label("%s / 30:00 · 처치 %d · 코인 %d"%[format_time(game.elapsed),game.kills,game.round_coins],Rect2(370,148,780,30),22,MUTED,p)
	var scroll:=ScrollContainer.new()
	scroll.position=Vector2(352,188)
	scroll.size=Vector2(835,350)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(scroll)
	var contents:=Control.new()
	contents.custom_minimum_size=Vector2(805,game.encounters.weapon_profiles.size()*78)
	scroll.add_child(contents)
	var row:=0
	for weapon in game.encounters.weapon_profiles:
		var profile:Dictionary=game.encounters.weapon_profiles[weapon]
		icon(int(profile.icon),Rect2(5,row*78+2,49,49),contents)
		label(game.item_name(weapon)+" · "+str(profile.role),Rect2(65,row*78,720,27),23,INK,contents)
		label("적용: "+"·".join(profile.affected),Rect2(65,row*78+27,720,22),18,MUTED,contents)
		var item:Dictionary={"id":weapon}
		label(game.evolution_hint(item),Rect2(65,row*78+49,720,23),17,MUTED,contents)
		row+=1
	button("계속 지키기  →",Rect2(370,552,470,46),p,func():game.toggle_pause(),true)
	button("다시 출항하기",Rect2(370,611,470,46),p,func():game.start_game();game.offer_blessing())
	button("설정",Rect2(870,552,305,46),p,func():show_settings())
	label(game.presentation.performance_text(),Rect2(860,608,330,55),16,MUTED,p)

func show_treasure(_rewards: Array[String]) -> void:
	var p:=modal_base()
	p.clip_contents=true
	var show=load("res://scripts/treasure_v10.gd").new()
	show.g=game
	show.h=self
	p.add_child(show)

func show_blessings(options: Array) -> void:
	var p:=modal_base()
	label("바다의 약속",Rect2(35,24,1100,58),44,INK,p)
	label("이번 항해를 함께할 힘을 하나 고르세요",Rect2(35,82,1100,35),27,MUTED,p)
	for i in options.size():
		var u: Dictionary=options[i]
		var pos:=Vector2(35+(i%2)*575,150+(i/2)*246)
		var b:=button("",Rect2(pos,Vector2(555,220)),p,game.choose_blessing.bind(str(u.id)))
		icon(int(u.icon),Rect2(17,25,130,130),b)
		label(str(u.name),Rect2(163,34,370,48),33,INK,b)
		var desc:=label(str(u.description),Rect2(166,97,355,82),27,MUTED,b)
		desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

func show_end(won: bool) -> void:
	var p:=modal_base()
	var width:=1120
	label("오늘도 바다는 무사해!" if won else "잠깐, 뚝배기 내려놓자",Rect2(25,20,width,68),48,INK,p)
	label("%s · 처치 %d · LV.%d · 코인 %d"%[format_time(game.elapsed),game.kills,game.level,game.round_coins],Rect2(25,100,width,50),30,MUTED,p)
	var rankings:Array=game.presentation.ranking()
	label("가장 활약한 공격 · "+(result_weapon_name(str(rankings[0].id)) if not rankings.is_empty() else "전투 기록 없음"),Rect2(25,164,width,48),28,INK,p)
	var scroll:=ScrollContainer.new()
	scroll.position=Vector2(25,227)
	scroll.size=Vector2(width,300)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(scroll)
	var list:=VBoxContainer.new()
	list.custom_minimum_size.x=width-25
	scroll.add_child(list)
	for row in rankings:
		var line:=Label.new()
		line.text="%s%s   피해 %s · DPS %.1f"%["★ " if game.evolved.has(str(row.id)) else "",result_weapon_name(str(row.id)),str(roundi(row.damage)),row.dps]
		line.add_theme_font_size_override("font_size",29)
		line.add_theme_color_override("font_color",INK)
		line.custom_minimum_size.y=48
		list.add_child(line)
	label("DPS: 보유 시간당 실제 피해 · 초과 피해 제외",Rect2(25,538,width,35),21,MUTED,p)
	button("다시 바다로 →",Rect2(25,600,480,64),p,func():game.start_game();game.offer_blessing(),true)
	button("항구로",Rect2(540,600,330,64),p,func():game.return_to_harbor())

func result_weapon_name(id: String) -> String:
	if game.evolved.has(id) and game.encounters.evolutions.has(id): return str(game.encounters.evolutions[id].name)
	return game.item_name(id)

func show_settings() -> void:
	if game.state=="running": game.toggle_pause()
	var p:=modal_base()
	var width:=1100
	label("바다의 소리와 화면",Rect2(25,20,width,60),38,INK,p)
	var settings:RefCounted=game.presentation
	var controls:=[{"name":"배경음","property":"volume","owner":game.music},{"name":"전투 효과음","property":"volume","owner":settings},{"name":"선택 · 보상 효과음","property":"ui_volume","owner":settings}]
	for i in controls.size():
		var spec:Dictionary=controls[i]
		var y:=90+i*98
		var owner:RefCounted=spec.owner
		var value:=label("%s  %d%%"%[spec.name,roundi(float(owner.get(spec.property))*100)],Rect2(30,y,width,40),29,INK,p)
		var slider:=HSlider.new()
		slider.position=Vector2(30,y+40)
		slider.size=Vector2(width,45)
		slider.min_value=0
		slider.max_value=100
		slider.value=float(owner.get(spec.property))*100
		slider.value_changed.connect(func(amount):owner.set(spec.property,amount/100.0);value.text="%s  %d%%"%[spec.name,int(amount)];game.save_settings())
		slider.drag_ended.connect(func(_changed):settings.sound("wave" if i==1 else "ui"))
		p.add_child(slider)
	var toggles:=[{"name":"전체 소리","property":"sound_enabled","owner":game},{"name":"화면 흔들림 줄이기","property":"reduced_motion","owner":settings},{"name":"가벼운 효과 모드","property":"low_fx","owner":settings}]
	for i in toggles.size():
		var spec:Dictionary=toggles[i]
		var check:=CheckButton.new()
		check.text=spec.name
		check.position=Vector2(30,400+i*65)
		check.size=Vector2(width,55)
		check.add_theme_font_size_override("font_size",29)
		check.add_theme_color_override("font_color",INK)
		check.add_theme_color_override("font_hover_color",INK)
		check.add_theme_color_override("font_pressed_color",INK)
		check.button_pressed=spec.owner.get(spec.property)
		check.toggled.connect(func(enabled):
			spec.owner.set(spec.property,enabled)
			if spec.property=="sound_enabled" and not enabled:
				for voice in settings.voices: voice.stop()
			game.save_settings())
		p.add_child(check)
	button("돌아가기",Rect2(30,610,width,60),p,func():show_start() if game.state=="title" else show_pause(),true)

func format_time(t: float) -> String:
	return "%02d:%02d"%[int(t)/60,int(t)%60]

func show_harbor() -> void:
	var p:=modal_base()
	label("출항 전, 든든하게",Rect2(40,25,1100,65),45,INK,p)
	label("모은 해변 코인  %d  ·  준비한 힘은 다음 항해에도 이어집니다"%game.harbor_coins,Rect2(45,98,1120,42),27,MUTED,p)
	var ids:=["power","vitality","luck"]
	var names:=["든든한 한 그릇","튼튼한 조개 심장","행운의 바다유리"]
	var descriptions:=["공격력 +5% / 단계","최대 체력 +10 / 단계","행운 +10% / 단계"]
	for i in 3:
		var id:String=ids[i]
		var rank:int=game.harbor.get(id,0)
		var card:=panel(Rect2(40+i*385,180,365,300),Color("eee4c9"),p)
		icon([6,19,12][i],Rect2(120,15,125,125),card)
		label(names[i],Rect2(20,145,330,43),31,INK,card)
		label(descriptions[i],Rect2(20,195,330,35),25,MUTED,card)
		label("%d / 3 단계"%rank,Rect2(20,245,330,30),23,MUTED,card)
		var b:=button("완성" if rank>=3 else "%d 코인으로 준비"%((rank+1)*100),Rect2(40+i*385,500,365,62),p,game.buy_harbor.bind(id),true)
		b.disabled=rank>=3 or game.harbor_coins<(rank+1)*100
	button("항구로",Rect2(40,597,365,55),p,func():show_start())

func refresh() -> void:
	xp_bar.value=100*game.xp/game.xp_needed()
	level_label.text="LV. %02d"%game.level
	clock_label.text=format_time(game.elapsed)
	stats.text="%d  처치"%game.kills
	notice.text=game.banner if game.banner_time>0 else ""
	sound_button.text="♪" if game.sound_enabled else "×"
	var signature:=str(game.upgrades)+str(game.evolved)
	if signature!=equipment_signature:
		equipment_signature=signature
		for child in equipment.get_children(): child.queue_free()
		equipment_row(equipment,Vector2(24,90),"weapon",42)
		equipment_row(equipment,Vector2(24,137),"passive",42)
		equipment_row(equipment,Vector2(24,184),"relic",36)
