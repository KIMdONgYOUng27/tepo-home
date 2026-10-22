extends Node2D
var g: Node2D
var h: CanvasLayer
func _process(_dt: float) -> void: queue_redraw()
func _draw() -> void:
	if g.boss_warning<=0 or g.state!="running": return
	var view:Vector2=get_viewport_rect().size
	# Slow edge pulse, no full-screen strobe. Reduced motion keeps a steady banner.
	var alpha:float=0.17 if g.presentation.reduced_motion else 0.12+0.13*(0.5+0.5*sin((3.6-g.boss_warning)*TAU*1.25))
	var ink:=Color(0.65,0.23,0.15,alpha)
	draw_rect(Rect2(0,0,view.x,18),ink)
	draw_rect(Rect2(0,view.y-18,view.x,18),ink)
	draw_rect(Rect2(0,18,18,view.y-36),ink)
	draw_rect(Rect2(view.x-18,18,18,view.y-36),ink)
	var box:=Rect2(view.x/2-295,145,590,100)
	draw_style_box(h.style(Color("3d5040"),9,Color("d9ae62")),box)
	draw_string(h.font,box.position+Vector2(183,39),"!  보스 접근  !",HORIZONTAL_ALIGNMENT_LEFT,-1,33,Color("ffdd8b"))
	var text:String=g.banner
	var width:float=h.font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,26).x
	draw_string(h.font,Vector2(view.x/2-width/2,box.position.y+77),text,HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color("faf0d8"))
