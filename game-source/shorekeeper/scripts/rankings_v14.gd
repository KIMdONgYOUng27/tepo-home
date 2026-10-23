extends RefCounted
const MODE:="shore20-v14"
var g: Node2D
var rows:Array=[]
var online_rows:Array=[]
var nickname:="테포 친구"
var endpoint:=""
var status:="이 기기의 오늘 기록 · 온라인 서버 연결 전"
var http:HTTPRequest
var posting:=false
var fetching:=false
var online:=false
var submitted:=false

func setup() -> void:
	if FileAccess.file_exists("user://rankings-v14.json"):
		var data=JSON.parse_string(FileAccess.get_file_as_string("user://rankings-v14.json"))
		if data is Array: rows=data
	if OS.has_feature("web"):
		var config=JavaScriptBridge.get_interface("TepoRankingConfig")
		if config!=null: endpoint=str(config.endpoint)
	http=HTTPRequest.new()
	http.timeout=8
	g.add_child(http)
	http.request_completed.connect(completed)

func today() -> String:
	var d:=Time.get_datetime_dict_from_unix_time(int(Time.get_unix_time_from_system())+32400)
	return "%04d-%02d-%02d"%[d.year,d.month,d.day]

func ordered() -> Array:
	var list:Array=online_rows.duplicate() if online else rows.filter(func(row):return row.get("date","")==today())
	list.sort_custom(func(a,b):return a.seconds>b.seconds if a.seconds!=b.seconds else (a.kills>b.kills if a.kills!=b.kills else a.get("id","")<b.get("id","")))
	return list.slice(0,20)

func record(won: bool) -> void:
	if submitted: return
	submitted=true
	var row:Dictionary={"id":"%d-%d"%[Time.get_unix_time_from_system(),randi()],"mode":MODE,"date":today(),"name":nickname.strip_edges().left(16),"seconds":minf(1200,snappedf(g.elapsed,0.001)),"kills":g.kills,"level":g.level,"won":won}
	if row.name.is_empty(): row.name="테포 친구"
	rows.append(row)
	if rows.size()>200: rows=rows.slice(rows.size()-200)
	if g.persist_results: FileAccess.open("user://rankings-v14.json",FileAccess.WRITE).store_string(JSON.stringify(rows))
	if not endpoint.is_empty() and g.persist_results:
		posting=true
		if http.request(endpoint,["Content-Type: application/json"],HTTPClient.METHOD_POST,JSON.stringify(row))!=OK:
			posting=false
			status="서버 연결 실패 · 이 기기 기록을 표시해요"

func refresh() -> void:
	if endpoint.is_empty() or posting or fetching: return
	status="오늘의 온라인 기록을 불러오는 중…"
	fetching=true
	if http.request(endpoint+"?mode="+MODE)!=OK:
		fetching=false
		online=false
		status="서버 연결 실패 · 이 기기 기록을 표시해요"

func completed(result: int,code: int,_headers: PackedStringArray,body: PackedByteArray) -> void:
	var was_posting:=posting
	posting=false
	fetching=false
	var data=JSON.parse_string(body.get_string_from_utf8())
	if result==HTTPRequest.RESULT_SUCCESS and code==200 and data is Dictionary:
		if was_posting: refresh(); return
		if data.get("rows") is Array:
			online_rows=data.rows
			online=true
			status="오늘의 온라인 랭킹 · 한국 시간 기준"
	else:
		online=false
		status="서버 연결 실패 · 이 기기 기록을 표시해요"
	if g.hud.ranking_open: g.hud.show_rankings(false)
