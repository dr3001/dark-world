extends Node
# FASE 15 — Ground Impact System: terrain-specific effects

var impact_fx = null
var decal_fx = null

func setup(impact, decal):
	impact_fx = impact; decal_fx = decal

func ground_impact(pos: Vector3, terrain_type: String, dir: Vector3 = Vector3.UP):
	match terrain_type:
		"earth": _earth(pos, dir)
		"stone": _stone(pos, dir)
		"wood": _wood(pos, dir)
		"grass": _grass(pos, dir)
		"mud": _mud(pos, dir)
		"water": _water(pos, dir)
		"snow": _snow(pos, dir)
		_: _earth(pos, dir)

func _earth(pos, dir):
	if impact_fx: impact_fx.spawn_impact("earth", pos, dir)
	if decal_fx: decal_fx.spawn_decal("dust", pos)

func _stone(pos, dir):
	if impact_fx:
		impact_fx.spawn_impact("stone", pos, dir)
		for i in range(3): impact_fx.spawn_impact("stone", pos + Vector3(randf()*0.3,0,randf()*0.3), dir)

func _wood(pos, dir):
	if impact_fx: impact_fx.spawn_impact("wood", pos, dir)

func _grass(pos, dir):
	if impact_fx: impact_fx.spawn_impact("earth", pos, dir)

func _mud(pos, dir):
	if impact_fx:
		impact_fx.spawn_impact("earth", pos, dir)
		impact_fx.spawn_impact("earth", pos + Vector3(0.2,0,0), dir)

func _water(pos, dir):
	if impact_fx: impact_fx.spawn_impact("wind", pos, dir)

func _snow(pos, dir):
	if impact_fx: impact_fx.spawn_impact("ice", pos, dir)
