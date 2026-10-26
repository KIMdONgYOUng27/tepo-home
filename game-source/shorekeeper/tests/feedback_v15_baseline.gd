extends "res://scripts/combat_fx_v9.gd"
# Preview adapter only: preserve old VFX for a comparison under the same scene.
func draw_dash() -> void: pass
func draw_water() -> void:
	var origin:Vector2=g.player+Vector2(0,-24)
	var length_value:=maxf(30,g.water_reach)
	var width:=80+length_value*0.4
	g.atlas_draw(g.effects,5,origin+g.aim*(length_value*0.5),Vector2(length_value,width),4,4,g.aim.angle(),Color(1,1,1,0.8))
