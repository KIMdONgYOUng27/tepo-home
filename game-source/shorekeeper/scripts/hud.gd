extends CanvasLayer

const INK := Color("303c2e")
const MUTED := Color("6c7154")
const CREAM := Color("f6ebd1")
const GOLD := Color("e5b96d")
var game: Node2D
var root: Control
var stats: Label
var clock_label: Label
var hp_bar: ProgressBar
var xp_bar: ProgressBar
var hp_label: Label
var level_label: Label
var slots: Label
var notice: Label
var modal: Control
var pause_button: Button
var sound_button: Button
var font: Font = preload("res://assets/korean.ttf")
var effect_label: Label

func _ready() -> void:
	var weighted_font := FontVariation.new()
	weighted_font.base_font = font
	weighted_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"):550.0}
	font = weighted_font
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ui_theme := Theme.new()
	ui_theme.default_font = font
	ui_theme.default_font_size = 16
	root.theme = ui_theme
	add_child(root)
	var top := panel(Rect2(20, 18, 1240, 91), Color("fbf5e7"), root)
	label("T / TEPO", Rect2(20, 12, 190, 24), 21, INK, top)
	label("GWANGALLI · SHOREKEEPER", Rect2(20, 43, 205, 22), 10, MUTED, top)
	hp_bar = bar(Rect2(245, 29, 245, 10), Color("e5907e"), top)
	hp_label = label("", Rect2(245, 45, 250, 23), 12, MUTED, top)
	clock_label = label("00:00", Rect2(530, 11, 180, 42), 32, INK, top)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label("03:00 생존", Rect2(530, 54, 180, 20), 11, MUTED, top).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats = label("", Rect2(765, 20, 230, 25), 17, INK, top)
	level_label = label("", Rect2(765, 48, 230, 23), 12, MUTED, top)
	sound_button = button("소리 ON", Rect2(1035, 24, 86, 42), top, func(): game.toggle_sound())
	pause_button = button("Ⅱ", Rect2(1134, 24, 66, 42), top, func(): game.toggle_pause())
	xp_bar = bar(Rect2(22, 116, 1236, 5), GOLD, root)
	var bottom := panel(Rect2(350, 718, 580, 61), Color(0.07, 0.18, 0.2, 0.93), root)
	slots = label("", Rect2(20, 12, 540, 39), 13, CREAM, bottom)
	slots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label("WASD 이동 · M 조준 전환 · ESC 일시정지", Rect2(21, 762, 330, 23), 11, CREAM, root)
	var status_panel := panel(Rect2(16,710,300,44),Color(0.12,0.2,0.15,0.9),root)
	effect_label = label("",Rect2(10,3,280,40),13,CREAM,status_panel)
	label("GWANGALLI  /  0.3", Rect2(1040, 762, 220, 23), 10, CREAM, root).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	notice = label("", Rect2(280, 146, 720, 44), 20, INK, root)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func style(color: Color, radius: int = 12, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.border_color = border
	s.set_border_width_all(1)
	return s

func panel(rect: Rect2, color: Color, parent: Node) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel", style(color))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p

func label(text: String, rect: Rect2, font_size: int, color: Color, parent: Node) -> Label:
	var l := Label.new()
	l.text = text
	l.position = rect.position
	l.size = rect.size
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func button(text: String, rect: Rect2, parent: Node, callback: Callable, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", CREAM if primary else INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_stylebox_override("normal", style(INK if primary else Color("e9e8db")))
	b.add_theme_stylebox_override("hover", style(GOLD))
	b.add_theme_stylebox_override("pressed", style(Color("cfaa68")))
	b.add_theme_stylebox_override("focus", style(Color(0, 0, 0, 0), 12, GOLD))
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func bar(rect: Rect2, color: Color, parent: Node) -> ProgressBar:
	var p := ProgressBar.new()
	p.position = rect.position
	p.size = rect.size
	p.show_percentage = false
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("background", style(Color("d8ddd1"), 6))
	p.add_theme_stylebox_override("fill", style(color, 6))
	parent.add_child(p)
	return p

func clear_modal() -> void:
	if is_instance_valid(modal):
		modal.queue_free()
		modal = null

func modal_base() -> Panel:
	clear_modal()
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)
	var shade := ColorRect.new()
	shade.color = Color(0.035, 0.12, 0.15, 0.74)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	return panel(Rect2(150, 155, 980, 490), CREAM, modal)

func show_start() -> void:
	var p := modal_base()
	label("A LITTLE HERO. A BIG BLUE SEA.", Rect2(43, 32, 620, 22), 11, MUTED, p)
	label("테포,\n파도를 지켜라", Rect2(40, 77, 600, 136), 49, INK, p)
	label("뚝배기 하나 쓰고, 부산 바다 앞으로.", Rect2(43, 227, 620, 32), 21, INK, p)
	label("갯강구·따개비·해조 더미·수달·네발 상어가 몰려와요.\n진상 중간보스를 물리치고, 라운드 보스의 장비 상자를 노리세요.", Rect2(43, 277, 620, 65), 15, MUTED, p)
	button("바다 지키러 가기    →", Rect2(43, 368, 330, 58), p, func(): game.start_game(), true)
	label("WASD 이동 · 16방향 자동 조준 · M 마우스 조준", Rect2(43, 439, 620, 24), 12, MUTED, p)
	var art := TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var preview := AtlasTexture.new()
	preview.atlas = load("res://assets/tepo-eight-v2.png")
	preview.region = Rect2(0,0,preview.atlas.get_width()/4.0,preview.atlas.get_height()/2.0)
	art.texture = preview
	art.position = Vector2(655, 80)
	art.size = Vector2(290, 290)
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(art)
	label("TEPO / 테포", Rect2(685, 365, 220, 35), 16, INK, p).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label("부산 바다의 작은 수호자", Rect2(670, 404, 250, 25), 12, MUTED, p).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func show_choices(options: Array) -> void:
	var p := modal_base()
	label("LEVEL UP  /  LV. %02d" % game.level, Rect2(35, 24, 900, 24), 12, MUTED, p)
	label("테포의 바다를 더 강하게", Rect2(35, 58, 900, 50), 31, INK, p)
	label("하나를 선택하세요. 선택하는 동안 시간은 멈춥니다.", Rect2(35, 112, 900, 25), 14, MUTED, p)
	for i in options.size():
		var data: Dictionary = options[i]
		var x := 35.0 + i * 307.0
		var b := button("", Rect2(x, 162, 295, 279), p, game.choose_upgrade.bind(str(data.id)))
		b.add_theme_stylebox_override("normal", style(Color("efebde"), 14, Color("d9d6c7")))
		b.add_theme_stylebox_override("hover", style(Color("f5e5bd"), 14, GOLD))
		var c := Color(str(data.color))
		panel(Rect2(18, 19, 43, 5), c, b)
		label(str(data.category), Rect2(18, 37, 265, 23), 10, MUTED, b)
		label(str(data.name), Rect2(18, 70, 262, 35), 21, INK, b)
		var old_level: int = game.upgrades.get(str(data.id), 0)
		label("새로 획득" if old_level == 0 else "LV. %d  →  %d" % [old_level, old_level + 1], Rect2(18, 111, 262, 28), 13, Color("9c7842"), b)
		var desc := label("", Rect2(18, 151, 257, 94), 14, MUTED, b)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.text = str(data.description)
		label("선택하기    ↗", Rect2(18, 247, 257, 23), 12, INK, b)

func show_pause() -> void:
	var p := modal_base()
	label("TAKE A BREATH", Rect2(40, 42, 900, 25), 12, MUTED, p)
	label("잠깐, 바다 바람 한 모금", Rect2(40, 100, 900, 55), 37, INK, p)
	label("게임은 멈춰 있습니다. 준비되면 이어서 출발하세요.", Rect2(40, 180, 900, 36), 18, MUTED, p)
	button("계속하기    →", Rect2(40, 278, 340, 60), p, func(): game.toggle_pause(), true)
	button("처음부터 다시", Rect2(40, 355, 340, 53), p, func(): game.start_game())

func show_treasure(rewards: Array[String]) -> void:
	var p := modal_base()
	label("ROUND BOSS / TREASURE",Rect2(40,28,900,25),12,MUTED,p)
	label("황금 장비 상자 · %d개 보상" % rewards.size(),Rect2(40,65,900,50),32,INK,p)
	label("보유 장비가 자동 강화됩니다. 같은 장비가 여러 번 나올 수 있어요.",Rect2(40,122,900,25),14,MUTED,p)
	for i in rewards.size():
		label("%02d   %s" % [i+1,rewards[i]],Rect2(45,165+i*37,880,33),20,INK,p)
	button("보상 받고 계속하기    →",Rect2(40,391,450,58),p,func():game.close_treasure(),true)

func show_end(won: bool) -> void:
	var p := modal_base()
	label("SHOREKEEPER REPORT", Rect2(40, 34, 900, 25), 12, MUTED, p)
	label("오늘도 바다는 무사해!" if won else "뚝배기 잠깐 내려놓자", Rect2(40, 93, 900, 58), 39, INK, p)
	label("3분 생존 성공. 테포가 부산 바다를 지켰습니다." if won else "모래를 털고 다시 도전해 보세요.", Rect2(40, 171, 900, 35), 19, MUTED, p)
	label("생존 %s   /   처치 %d   /   레벨 %d   /   코인 %d" % [format_time(game.elapsed), game.kills, game.level,game.round_coins], Rect2(40, 242, 900, 40), 20, INK, p)
	button("한 번 더 지키러 가기    →", Rect2(40, 339, 370, 60), p, func(): game.start_game(), true)
	label("최고 기록  %s" % format_time(game.best_time), Rect2(40, 422, 900, 25), 13, MUTED, p)

func format_time(t: float) -> String:
	var seconds := int(t)
	return "%02d:%02d" % [seconds / 60, seconds % 60]

func refresh() -> void:
	hp_bar.value = game.hp
	hp_label.text = "HP  %d / 100" % ceili(game.hp)
	xp_bar.value = 100.0 * game.xp / game.xp_needed()
	clock_label.text = format_time(game.elapsed)
	stats.text = "물리친 적   %03d" % game.kills
	level_label.text = "LV. %02d    ·    광안리 해변" % game.level
	effect_label.text = ("마우스 조준 · 16방향" if game.manual_aim else "자동 조준 보정 · 16방향") + ("\n시간 정지 %.1f초" % game.freeze_time if game.freeze_time>0 else "")
	if game.water_time > 0: effect_label.text = "물대포 %.1f초 · 연속 분사" % game.water_time + ("\n시간 정지 %.1f초" % game.freeze_time if game.freeze_time>0 else "")
	var names := {"sand":"모래탄환", "bowl":"뚝배기", "wave":"파도", "tetra":"테트라포드"}
	var texts: Array[String] = []
	for id in ["sand", "bowl", "wave", "tetra"]:
		if game.upgrades.get(id, 0) > 0:
			texts.append("%s %d" % [names[id], game.upgrades[id]])
	slots.text = "    /    ".join(texts)
	sound_button.text = "소리 ON" if game.sound_enabled else "소리 OFF"
	notice.text = game.banner if game.banner_time > 0 else ""
