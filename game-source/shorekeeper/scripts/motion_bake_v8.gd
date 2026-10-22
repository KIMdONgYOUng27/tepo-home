extends Node2D
var presentation: RefCounted
var entries: Array=[]
var motion:="walk"
func _draw() -> void:
	for row in entries.size():
		var entry:Dictionary=entries[row]
		for phase in 8:
			var transform:=Transform2D.IDENTITY.scaled(Vector2.ONE*128)
			transform.origin=Vector2(phase*128+64,(row+1)*128)
			draw_mesh(presentation.uv_mesh(entry.profile,motion,phase,entry.index,entry.rows),entry.atlas,transform)
