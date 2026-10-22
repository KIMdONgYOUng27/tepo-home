extends SceneTree
func _initialize() -> void:
	var img:=Image.load_from_file("res://assets/inventory-v4b.png")
	var rows: Array=[]
	var first:=-1
	var last:=-1
	for y in img.get_height():
		var count:=0
		for x in img.get_width():
			if img.get_pixel(x,y).a>0.12: count+=1
		if count>8:
			if first<0: first=y
			last=y
		elif first>=0 and y-last>16:
			rows.append([first,last])
			first=-1
	if first>=0: rows.append([first,last])
	print("ICON BANDS ",rows," SIZE ",img.get_size())
	quit()
