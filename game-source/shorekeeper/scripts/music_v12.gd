extends RefCounted

var g: Node2D
var volume:=0.55
var streams: Dictionary={}
var voices: Array[AudioStreamPlayer]=[]
var weights: Array[float]=[0.0,0.0]
var targets: Array[float]=[0.0,0.0]
var current:=""
var active:=-1
var foreground:=true
var duck:=1.0
const FADE_SECONDS:=1.2

func shutdown() -> void:
	for voice in voices:
		if is_instance_valid(voice):
			voice.stream_paused=false
			voice.stop()
			voice.stream=null
	voices.clear()
	streams.clear()

func setup() -> void:
	for id in ["title","combat","late","boss"]:
		var stream:AudioStreamOggVorbis=load("res://assets/music/%s.ogg"%id)
		stream.loop=true
		streams[id]=stream
	for i in 2:
		var voice:=AudioStreamPlayer.new()
		voice.volume_db=-80
		g.add_child(voice)
		voices.append(voice)

func desired_track() -> String:
	if g.state in ["title","won","lost"]: return "title"
	# Selection and chest screens retain the combat context until play resumes.
	if g.state!="running" and current!="": return current
	for e in g.enemies:
		if e.boss and e.hp>0: return "boss"
	return "late" if g.elapsed>=600 else "combat"

func update(dt: float) -> void:
	var wanted:=desired_track()
	if wanted!=current: transition(wanted)
	var desired_duck:=1.0
	if g.state in ["paused","levelup","blessing"]: desired_duck=0.5
	if g.state=="treasure": desired_duck=0.32
	if g.state in ["won","lost"]: desired_duck=0.25
	duck=move_toward(duck,desired_duck,dt*2.5)
	for i in voices.size():
		weights[i]=move_toward(weights[i],targets[i],dt/FADE_SECONDS)
		var gain:float=volume*weights[i]*duck if g.sound_enabled and foreground else 0.0
		voices[i].volume_db=linear_to_db(gain)-8 if gain>0.0001 else -80
		# Mute and blur pause decoding, preserving the current musical position.
		voices[i].stream_paused=not g.sound_enabled or not foreground or volume<=0
		if targets[i]==0 and weights[i]<=0.0001 and voices[i].playing: voices[i].stop()

func transition(id: String) -> void:
	if not streams.has(id): return
	current=id
	active=0 if active!=0 else 1
	for i in 2: targets[i]=1.0 if i==active else 0.0
	voices[active].stop()
	voices[active].stream=streams[id]
	voices[active].volume_db=-80
	voices[active].play()
	weights[active]=0.0
