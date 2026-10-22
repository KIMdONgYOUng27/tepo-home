extends SceneTree
var errors:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok: errors+=1; push_error(message)
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g.set_process(false)
	g.persist_results=false
	var m=g.music
	check(m.streams.size()==4 and m.voices.size()==2,"four music streams, bounded two-voice crossfade")
	for id in m.streams:
		check(m.streams[id].loop,"track loops: "+id)
		check(m.streams[id].get_length()>80,"full-length song imported: "+id)
	g.state="title"
	m.update(0.1)
	check(m.current=="title","title context")
	g.start_game()
	m.update(0.1)
	check(m.current=="combat","early combat context")
	for i in 15: m.update(0.1)
	check(m.weights[m.active]==1.0 and m.weights[1-m.active]==0.0,"crossfade completes with no orphan voice")
	g.elapsed=600
	m.update(0.1)
	check(m.current=="late","late combat starts at ten minutes")
	g.spawn_enemy(true)
	m.update(0.1)
	check(m.current=="boss","live major boss takes priority")
	g.state="treasure"
	g.enemies[-1].hp=0
	for i in 10: m.update(0.1)
	check(m.current=="boss" and m.duck<=0.321,"reveal retains context and ducks for reward audio")
	g.state="running"
	m.update(0.1)
	check(m.current=="late","dead boss returns to current combat phase")
	g.sound_enabled=false
	m.update(0.1)
	check(m.voices.all(func(v):return v.stream_paused and v.volume_db<=-79),"master mute pauses music too")
	g.sound_enabled=true
	m.foreground=false
	m.update(0.1)
	check(m.voices.all(func(v):return v.stream_paused),"blur silences and pauses decoding")
	m.foreground=true
	m.volume=0.55
	m.update(0.1)
	check(not m.voices[m.active].stream_paused,"music resumes on return")
	m.volume=0
	m.update(0.1)
	check(m.voices[m.active].volume_db<=-79,"independent music volume zero")
	g.state="won"
	m.update(0.1)
	check(m.current=="title","results context")
	g.start_game()
	m.update(0.1)
	check(m.current=="combat","restart restores early combat")
	print("MUSIC: %d errors. Four full looping songs, context priority, bounded crossfade, ducking, mute, focus and restart."%errors)
	g.queue_free()
	await process_frame
	# Let the audio mixer release stopped Ogg playback references before shutdown.
	await create_timer(0.25).timeout
	quit(1 if errors else 0)
