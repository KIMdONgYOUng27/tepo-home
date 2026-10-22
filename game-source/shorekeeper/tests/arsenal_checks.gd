extends RefCounted
var errors:=0

func check(ok: bool, message: String) -> void:
	if not ok:
		errors+=1
		push_error("ARSENAL FAIL: "+message)

func reset(g: Node2D) -> void:
	g.start_game()
	g.enemies.clear()
	g.pickups.clear()
	g.chests.clear()
	g.upgrades.clear()
	g.arsenal.reset()
	g.build_grid()

func dummy(g: Node2D, pos: Vector2, health: float=1000000) -> Dictionary:
	g.spawn_enemy(false,false,0)
	var e:Dictionary=g.enemies[-1]
	e.pos=pos
	e.hp=health
	e.max_hp=health
	e.speed=0
	return e

func run(g: Node2D) -> int:
	# Every stat toggle is compared against the same weapon at the same level.
	for weapon in g.encounters.weapon_profiles:
		reset(g)
		g.upgrades[weapon]=1
		var base:Dictionary=g.arsenal.stats(weapon)
		var toggles:Dictionary={"power":["damage","피해"],"area":["radius","범위"],"projectilespeed":["speed","탄속"],"amount":["amount","개수"],"duration":["duration","지속"],"haste":["cooldown","쿨타임"]}
		for passive in toggles:
			g.upgrades[passive]=1
			var changed:Dictionary=g.arsenal.stats(weapon)
			var field:String=toggles[passive][0]
			var applies:bool=toggles[passive][1] in base.affected
			if applies and float(base[field])!=0:
				check(not is_equal_approx(float(base[field]),float(changed[field])),weapon+" applies "+passive)
			elif not applies:
				check(is_equal_approx(float(base[field]),float(changed[field])),weapon+" ignores "+passive)
			g.upgrades.erase(passive)
	# Every weapon creates actual damage (or actual protection), not merely an icon.
	for weapon in g.encounters.weapon_profiles:
		reset(g)
		g.upgrades[weapon]=1
		g.aim=Vector2.RIGHT
		for x in range(-4,5):
			for y in range(-4,5): dummy(g,g.player+Vector2(x*75,y*75))
		g.build_grid()
		for frame in 210:
			g.elapsed+=0.05
			g.arsenal.update(0.05)
		if weapon=="anchor":
			check(g.arsenal.shield_charges>0,"anchor gains actual shields")
			check(g.arsenal.block_damage(50)==0,"anchor actually blocks HP damage")
		else: check(g.enemies.any(func(e):return e.hp<e.max_hp),weapon+" has a working attack")
		check(g.bullets.size()<=160 and g.arsenal.zones.size()<=48,"arsenal entity bounds")
	# All fifteen recipes: incomplete requirements reject; completed requirements evolve.
	for recipe_id in g.encounters.evolutions:
		reset(g)
		var r:Dictionary=g.encounters.evolutions[recipe_id]
		if r.has("weapons"):
			for weapon in r.weapons: g.upgrades[weapon]=8
			g.upgrades[r.weapons[0]]=7
		else: g.upgrades[recipe_id]=7
		if r.has("passive"): g.upgrades[r.passive]=1
		for passive in r.get("passives",{}): g.upgrades[passive]=int(r.passives[passive])
		check(not g.evolution_candidates().has(recipe_id),recipe_id+" rejects nonmax weapon")
		if r.has("weapons"): g.upgrades[r.weapons[0]]=8
		else: g.upgrades[recipe_id]=8
		if r.has("passive"):
			g.upgrades.erase(r.passive)
			check(not g.evolution_candidates().has(recipe_id),recipe_id+" rejects missing passive")
			g.upgrades[r.passive]=1
		for passive in r.get("passives",{}):
			g.upgrades[passive]=int(r.passives[passive])-1
			check(not g.evolution_candidates().has(recipe_id),recipe_id+" requires max relic")
			g.upgrades[passive]=int(r.passives[passive])
		check(g.evolution_candidates().has(recipe_id),recipe_id+" is eligible")
		g.grant_boss_chest(1,true)
		check(g.evolved.has(recipe_id),recipe_id+" evolves through actual chest")
		check(not g.evolution_candidates().has(recipe_id),recipe_id+" cannot duplicate")
		g.treasure_clock=g.treasure_duration()
		g.close_treasure()
	# A union frees exactly one slot and consumed inputs never reappear.
	reset(g)
	g.upgrades={"gull_white":8,"gull_dark":8,"sand":1,"chain":1,"rain":1,"stone":1}
	check(g.owned_items("weapon").size()==6,"six real occupied weapon slots")
	g.perform_evolution("gull_union")
	check(g.owned_items("weapon").size()==5,"union frees one weapon slot")
	for item in g.catalog:
		if item.id in ["gull_white","gull_white_level","gull_dark","gull_dark_level"]: check(not g.upgrade_available(item),"consumed input cannot return")
	var union_level:Dictionary=g.catalog.filter(func(u):return u.id=="gull_union_level")[0]
	check(g.upgrade_available(union_level),"bird union continues leveling")
	g.apply_upgrade(union_level)
	check(g.upgrades.gull_union==2,"bird union level increments")
	# +Amount must still create every pearl against a single boss/target.
	reset(g)
	g.upgrades={"pearl":1,"amount":2}
	dummy(g,g.player+Vector2(200,0))
	g.build_grid()
	g.arsenal.cast("pearl",g.arsenal.stats("pearl"))
	check(g.arsenal.pending.size()==3,"single target does not suppress extra pearl shots")
	# Fixed-direction guns apply Amount to each of the four streams.
	for weapon in ["feather","gust"]:
		reset(g)
		g.upgrades={weapon:1,"amount":2}
		g.arsenal.cast(weapon,g.arsenal.stats(weapon))
		check(g.arsenal.pending.size()==12,"four streams times three shots: "+weapon)
	# Chain Amount adds alternate swings, not range or damage multipliers.
	reset(g)
	g.upgrades={"chain":1,"amount":2}
	g.arsenal.cast("chain",g.arsenal.stats("chain"))
	check(g.arsenal.strokes.size()==3,"chain gets three swings")
	check(g.arsenal.strokes[0].dir==-g.arsenal.strokes[1].dir,"chain alternates sides")
	# Independent orbit hit timers let two different pots hit the same target.
	reset(g)
	g.upgrades={"bowl":1}
	var orb:Dictionary=dummy(g,g.player+Vector2(g.orbit_radius(),0))
	g.build_grid()
	var os:Dictionary=g.arsenal.stats("bowl")
	g.arsenal.cast("bowl",os)
	g.arsenal.orbits[0].phase=0
	g.arsenal.update_orbits(0)
	var first_hp:float=orb.hp
	g.arsenal.cast("bowl",os)
	g.arsenal.orbits[1].phase=0
	g.arsenal.update_orbits(0)
	check(orb.hp<first_hp,"different orbit batches have independent hit immunity")
	# Base heat can erase loose loot, never equipment chests/relic progression.
	reset(g)
	g.upgrades={"heat":1}
	dummy(g,g.player+Vector2(100,0),100)
	g.build_grid()
	g.gems.append({"pos":g.player,"value":10,"pulled":false})
	g.spawn_pickup(g.player,"food20")
	g.spawn_pickup(g.player,"relic_left")
	g.chests.append({"pos":g.player,"boss":true,"opened":false,"can_evolve":true})
	g.arsenal.heat_pulse(0)
	check(g.gems.is_empty(),"heat can erase visible XP including fresh kill drops")
	check(g.pickups.any(func(p):return p.kind=="relic_left") and g.chests.size()==1,"heat preserves progression objects")
	g.evolved.heat=true
	dummy(g,g.player+Vector2(100,0),100)
	g.build_grid()
	g.arsenal.heat_pulse()
	check(g.xp>0 and g.gems.is_empty(),"evolved heat generates and absorbs XP")
	# Relics are outside common six-slot pool and cannot be rolled before collection.
	reset(g)
	var relic:Dictionary=g.catalog.filter(func(u):return u.id=="relic_left")[0]
	check(not g.upgrade_available(relic),"uncollected relic never appears at levelup")
	g.apply_pickup("relic_left")
	check(g.upgrade_available(relic) and g.owned_items("passive").is_empty(),"collected relic upgrades without consuming passive slot")
	g.pickups.clear()
	g.spawn_pickup(g.player,"relic_left")
	g.spawn_pickup(g.player,"relic_right")
	for i in 100: g.spawn_pickup(g.player,"water")
	check(g.pickups.size()==64 and g.pickups.filter(func(p):return str(p.kind).begins_with("relic_")).size()==2,"pickup cap never evicts evolution relics")
	g.upgrades={"anchor":8}
	g.evolved.anchor=true
	g.arsenal.shield_charges=0
	check(g.arsenal.block_damage(100)==10,"evolved anchor limits an unblocked hit")
	# Integration: hostile contact must use the shield, not only the helper API.
	reset(g)
	g.upgrades={"anchor":1}
	g.arsenal.update_shield(0.01)
	dummy(g,g.player+Vector2(15,0))
	var protected_hp:float=g.hp
	g.update_enemies(0.01)
	check(g.hp==protected_hp and g.arsenal.shield_charges==0,"hostile contact is intercepted by anchor")
	# Ricochet bounces; return weapons reverse toward the player.
	for weapon in ["stone","snack"]:
		reset(g)
		g.upgrades[weapon]=1
		g.arsenal.queue_missile(weapon,g.arsenal.stats(weapon),Vector2.RIGHT)
		g.arsenal.update_pending(0.01)
		var missile:Dictionary=g.bullets[0]
		if weapon=="stone": missile.pos=g.camera.position+Vector2(g.view_half().x-20,0)
		else: missile.pos=g.player+Vector2(200,0); missile.age=0.6
		g.arsenal.update_missiles(0.05)
		check(missile.velocity.x<0,weapon+" actually reverses travel")
	# Evolved orbit overlapping lifetimes preserve Duration's benefit.
	reset(g)
	g.upgrades={"bowl":8,"duration":5}
	g.evolved.bowl=true
	var evolved_orbit:Dictionary=g.arsenal.stats("bowl")
	check(evolved_orbit.duration>evolved_orbit.cooldown,"evolved orbit lifetime exceeds its recast period")
	# Duration cannot increase heavy wave lifetime; it does increase rain/stone/bird life.
	reset(g)
	g.upgrades={"wave":1,"duration":5}
	check(g.arsenal.stats("wave").duration==3,"heavy wave ignores Duration")
	g.upgrades={"pearl":1}
	g.blessings.append("stars")
	check(g.arsenal.stats("pearl").amount==2,"star blessing preserves its extra pearl shot")
	# Left HUD, no overflow in the scrollable codex.
	g.hud.refresh()
	var icons:Array=g.hud.equipment.get_children()
	check(not icons.is_empty() and icons[0].position.x<300,"equipment is anchored at upper left")
	g.hud.show_pause()
	check(g.hud.modal.find_children("*","ScrollContainer",true,false).size()==1,"codex scrolls all weapon rows")
	print("ARSENAL: %d errors. 19 combat forms, 114 stat toggles, 15 recipes, unions, shields, relics and HUD."%errors)
	return errors
