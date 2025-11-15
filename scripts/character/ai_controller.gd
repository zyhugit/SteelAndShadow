# res://scripts/character/ai_controller.gd
class_name AIController
extends Node

# Simple AI that makes combat decisions for enemies
# For demo: Uses basic heuristics, not perfect play

## Decide what action to take
func decide_action(
	ai_character: CharacterData,
	opponent: CharacterData,
	is_attacking: bool
) -> Dictionary:
	
	var available_cp = ai_character.combat_pool.get_remaining()
	
	if is_attacking:
		return decide_attack(ai_character, opponent, available_cp)
	else:
		return decide_defense(ai_character, opponent, available_cp)

## Decide attack action
func decide_attack(
	ai_character: CharacterData,
	opponent: CharacterData,
	available_cp: int
) -> Dictionary:
	
	var attack = AttackManeuver.new()
	
	# Choose attack type (70% swing, 30% thrust)
	if randf() < 0.7:
		attack.type = AttackManeuver.Type.SWING
	else:
		attack.type = AttackManeuver.Type.THRUST
	
	# Choose target zone
	attack.target_zone = choose_target_zone(opponent)
	
	# Allocate 60% of available CP to attack
	var dice_to_use = max(3, int(available_cp * 0.6))
	dice_to_use = min(dice_to_use, available_cp)
	attack.dice_allocated = dice_to_use
	
	return {"attack": attack}

## Decide defense action
func decide_defense(
	ai_character: CharacterData,
	opponent: CharacterData,
	available_cp: int
) -> Dictionary:
	
	var defense = DefenseManeuver.new()
	
	# Choose defense type based on equipment
	if ai_character.equipment.has_shield() and available_cp >= 3:
		defense.type = DefenseManeuver.Type.BLOCK
	else:
		# 70% parry, 20% dodge stand, 10% counter
		var roll = randf()
		if roll < 0.7:
			defense.type = DefenseManeuver.Type.PARRY
		elif roll < 0.9:
			defense.type = DefenseManeuver.Type.DODGE_STAND
		else:
			if available_cp >= 3:  # Counter needs at least 3 dice
				defense.type = DefenseManeuver.Type.COUNTER
			else:
				defense.type = DefenseManeuver.Type.PARRY
	
	# Allocate remaining CP (or most of it)
	var dice_to_use = available_cp
	if defense.type == DefenseManeuver.Type.COUNTER:
		dice_to_use = max(1, available_cp - 2)  # Save 2 for upfront cost
	
	defense.dice_allocated = dice_to_use
	
	return {"defense": defense}

## Choose which zone to target
func choose_target_zone(opponent: CharacterData) -> TargetZone.SimpleZone:
	# Check opponent's wounds - target already wounded areas
	if opponent.injury_manager and not opponent.injury_manager.wounds.is_empty():
		for wound in opponent.injury_manager.wounds:
			if wound.level >= 2 and wound.location == TargetZone.SimpleZone.HEAD:
				# Finish them! Go for head if it's already wounded
				return TargetZone.SimpleZone.HEAD
	
	# Otherwise: 60% torso, 30% head, 10% limbs
	var roll = randf()
	if roll < 0.6:
		return TargetZone.SimpleZone.TORSO
	elif roll < 0.9:
		return TargetZone.SimpleZone.HEAD
	else:
		return TargetZone.SimpleZone.LIMBS
