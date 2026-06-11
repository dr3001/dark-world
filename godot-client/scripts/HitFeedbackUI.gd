extends Node
# FASE 8 — Hit Feedback UI: floating text, hit markers, criticals

func show_floating_text(pos: Vector3, text: String, color: Color = Color.WHITE):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.font_size = 24
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.modulate = color
	lbl.position = pos + Vector3(0, 2.5, 0)
	get_parent().add_child(lbl)
	var elapsed = 0.0
	while elapsed < 1.5 and is_instance_valid(lbl):
		elapsed += 0.05
		lbl.position = pos + Vector3(0, 2.5 + elapsed, 0)
		lbl.modulate.a = 1.0 - (elapsed / 1.5)
		await get_tree().create_timer(0.05).timeout
	if is_instance_valid(lbl): lbl.queue_free()

func show_hit_marker(pos: Vector3):
	show_floating_text(pos, "X", Color.RED)

func show_critical(pos: Vector3, dmg: float):
	show_floating_text(pos, str(int(dmg)) + "!", Color(1, 0.3, 0.1, 1))

func show_blocked(pos: Vector3):
	show_floating_text(pos, "BLOCK", Color(0.3, 0.5, 1))

func show_dodge(pos: Vector3):
	show_floating_text(pos, "DODGE", Color(0.5, 0.5, 0.5))

func show_immune(pos: Vector3):
	show_floating_text(pos, "IMMUNE", Color(0.7, 0.7, 0.3))

func show_bleeding(pos: Vector3):
	show_floating_text(pos, "BLEED", Color(0.8, 0.1, 0.1))

func show_poisoned(pos: Vector3):
	show_floating_text(pos, "POISON", Color(0.2, 0.8, 0.2))
