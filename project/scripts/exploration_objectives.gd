extends Node

signal objective_changed(title: String, description: String, completed: bool)

var player: Node
var stage := 0
var completed := false
var title := "The Grove's Forgotten Oath"
var description := "Find the hidden relic cache in the western grove."

func configure(fighter: Node) -> void:
	player = fighter
	if is_instance_valid(player) and player.has_signal("exploration_event"):
		player.exploration_event.connect(_on_exploration_event)

func _on_exploration_event(event_name: String) -> void:
	if completed:
		return
	if stage == 0 and event_name == "cache_collected":
		stage = 1
		description = "Carry the relic to the Grove Rest Shrine."
		objective_changed.emit(title, description, false)
	elif stage == 1 and event_name == "rest:GroveRestShrine":
		stage = 2
		completed = true
		description = "Oath fulfilled — the grove's blessing is yours."
		if is_instance_valid(player):
			player.prosthetic_upgrade_points += 2
			player.prosthetic_energy = minf(player.max_prosthetic_energy, player.prosthetic_energy + 35.0)
		objective_changed.emit(title, description, true)

func get_status_text() -> String:
	return "OATH COMPLETE: " + description if completed else "OBJECTIVE: " + description
