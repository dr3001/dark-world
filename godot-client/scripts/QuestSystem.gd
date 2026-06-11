extends Node

signal quest_updated(quest_name, progress, target)

var active_quest: Dictionary = {
	"name": "Derrote Vorak, o Antigo",
	"target": "Vorak, o Antigo",
	"target_type": "dragon",
	"target_id": "b0000000-0000-0000-0000-000000000050",
	"progress": 0,
	"max_progress": 1,
	"completed": false
}

func _ready():
	print("[QUEST] System initialized")

func check_kill(entity_name: String, entity_id: String):
	if active_quest.completed: return
	if entity_name == active_quest.target or entity_id == active_quest.target_id:
		active_quest.progress = active_quest.max_progress
		active_quest.completed = true
		quest_updated.emit(active_quest.name, active_quest.progress, active_quest.max_progress)
		print("[QUEST] Mission complete: ", active_quest.name)
		return true
	return false

func get_quest_text() -> String:
	if active_quest.completed:
		return "MISSAO CONCLUIDA!"
	return active_quest.name + " (" + str(active_quest.progress) + "/" + str(active_quest.max_progress) + ")"
