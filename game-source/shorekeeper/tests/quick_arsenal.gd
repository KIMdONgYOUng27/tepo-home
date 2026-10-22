extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.persist_results=false
	g.harbor={"power":0,"vitality":0,"luck":0}
	g.sound_enabled=false
	g.rng.seed=417
	var audit=load("res://tests/arsenal_checks.gd").new()
	var errors:int=audit.run(g)
	g.queue_free()
	await process_frame
	quit(1 if errors else 0)
