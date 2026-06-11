extends Node
# FASE 11 — Shield Impact Visual System

var impact_fx = null
var audio_fx = null
var camera_fx = null

func setup(impact, audio_node, camera_node):
	impact_fx = impact; audio_fx = audio_node; camera_fx = camera_node

func block_light(pos: Vector3, dir: Vector3 = Vector3.RIGHT):
	if impact_fx: impact_fx.spawn_impact("shield", pos, dir)
	if audio_fx: audio_fx.play_block()
	if camera_fx: camera_fx.block_flash()

func block_heavy(pos: Vector3, dir: Vector3 = Vector3.RIGHT):
	if impact_fx:
		impact_fx.spawn_impact("shield", pos, dir)
		impact_fx.spawn_impact("metal", pos + Vector3(0.2,0,0), -dir)
	if audio_fx: audio_fx.play_block()
	if camera_fx: camera_fx.shake_light()

func magic_shield_impact(pos: Vector3):
	if impact_fx: impact_fx.spawn_impact("magic", pos)
	if camera_fx: camera_fx.block_flash()

func wooden_shield_hit(pos: Vector3):
	if impact_fx: impact_fx.spawn_impact("wood", pos)
	if audio_fx: audio_fx.play_block()

func metal_shield_hit(pos: Vector3):
	if impact_fx: impact_fx.spawn_impact("shield", pos)
	if audio_fx: audio_fx.play_block()
