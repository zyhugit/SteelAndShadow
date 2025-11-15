# res://scripts/combat/encounter_data.gd
class_name EncounterData
extends Resource

# Defines a complete combat encounter
# Can be saved as .tres files for easy encounter creation

@export var encounter_name: String = "Practice Duel"
@export_multiline var description: String = "A training bout"

## Combatants
@export var player_character: CharacterData
@export var enemy_character: CharacterData

## Settings
@export var max_rounds: int = 10  # Combat auto-ends after this many rounds
@export var is_tutorial: bool = false
@export var tutorial_instructions: Array[String] = []

## Rewards (for future use)
@export var victory_text: String = "Victory!"
@export var defeat_text: String = "Defeat!"
@export var experience_reward: int = 0
@export var gold_reward: int = 0

## Get a summary
func get_summary() -> String:
	return "%s\n%s\nPlayer: %s vs Enemy: %s" % [
		encounter_name,
		description,
		player_character.character_name if player_character else "None",
		enemy_character.character_name if enemy_character else "None"
	]
