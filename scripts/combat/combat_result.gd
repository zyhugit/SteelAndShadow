# res://scripts/combat/combat_result.gd
class_name CombatResult
extends Resource

# Stores the outcome of an attack/defense exchange
# Used to communicate results from CombatResolver to CombatManager

## Basic outcome
var hit: bool = false  # Did the attack succeed?

## Dice rolls
var attack_dice_used: int = 0
var defense_dice_used: int = 0
var attack_successes: int = 0
var defense_successes: int = 0
var margin: int = 0  # attack_successes - defense_successes

## Damage (if hit)
var damage_wound: Resource = null  # Will be WoundData later

## Special effects
var initiative_stolen: bool = false  # Did defender steal initiative?
var attacker_dice_lost: int = 0     # Duck&Weave or fumble penalty
var defender_bonus_dice: int = 0    # Counter bonus dice
var combat_disengaged: bool = false # Dodge&Break result

## Fumbles
var attacker_fumbled: bool = false
var defender_fumbled: bool = false

## Get a summary string for logging
func get_summary() -> String:
	if not hit:
		return "Attack missed (%d vs %d successes)" % [attack_successes, defense_successes]
	
	var summary = "Hit! (%d vs %d successes, margin %d)" % [
		attack_successes, defense_successes, margin
	]
	
	if initiative_stolen:
		summary += " [Initiative stolen]"
	if attacker_dice_lost > 0:
		summary += " [Attacker loses %d dice]" % attacker_dice_lost
	if defender_bonus_dice > 0:
		summary += " [Defender gains %d bonus dice]" % defender_bonus_dice
	
	return summary
