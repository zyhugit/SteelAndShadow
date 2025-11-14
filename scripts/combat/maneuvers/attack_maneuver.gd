# res://scripts/combat/maneuvers/attack_maneuver.gd
class_name AttackManeuver
extends Resource

# Represents a single attack action in combat
# Player chooses: attack type, target zone, and how many dice to use

## Attack Types
enum Type {
	THRUST,  # Fast stab: +1 die, -1 damage (can spend +1 die to negate penalty)
	SWING,   # Standard attack (can spend +1 die for +1 damage)
	FEINT    # Deceptive attack: costs extra dice, changes target after defense declared
}

## Core properties
@export var type: Type = Type.SWING
@export var target_zone: TargetZone.SimpleZone = TargetZone.SimpleZone.TORSO
@export var dice_allocated: int = 0

## Optional modifiers
@export var bonus_die_spent: bool = false  # For thrust damage negation or swing damage boost

## Feint-specific (only used if type == FEINT)
@export var feint_original_zone: TargetZone.SimpleZone = TargetZone.SimpleZone.LIMBS
@export var feint_dice_added: int = 0

## Calculate effective dice for rolling (accounts for thrust bonus)
func get_effective_dice() -> int:
	match type:
		Type.THRUST:
			# Thrust gets +1 die for speed
			var effective = dice_allocated + 1
			# If we spent bonus die to negate damage penalty, subtract it back
			if bonus_die_spent:
				effective -= 1
			return effective
		Type.SWING:
			# Swing uses allocated dice, minus bonus die if spent for damage
			return dice_allocated - (1 if bonus_die_spent else 0)
		Type.FEINT:
			# Feint uses allocated + added dice
			return dice_allocated + feint_dice_added
	return dice_allocated

## Calculate damage modifier from attack type
func get_damage_modifier() -> int:
	match type:
		Type.THRUST:
			# Thrust: -1 damage unless we spent a die to negate
			return -1 if not bonus_die_spent else 0
		Type.SWING:
			# Swing: +1 damage if we spent extra die
			return 1 if bonus_die_spent else 0
		Type.FEINT:
			# Feint has no damage modifier
			return 0
	return 0

## Validate this attack is legal
func validate(character_proficiency: int, available_cp: int) -> bool:
	# Must allocate at least 1 die
	if dice_allocated <= 0:
		print("Attack validation failed: Must allocate at least 1 die")
		return false
	
	# Must have enough CP
	var total_cost = dice_allocated
	if type == Type.FEINT:
		total_cost += 1 + feint_dice_added  # Feint costs 1 + added dice
	if bonus_die_spent:
		total_cost += 1
	
	if total_cost > available_cp:
		print("Attack validation failed: Costs %d CP, only %d available" % [total_cost, available_cp])
		return false
	
	# Feint requires proficiency 4+
	if type == Type.FEINT and character_proficiency < 4:
		print("Attack validation failed: Feint requires Proficiency 4+, you have %d" % character_proficiency)
		return false
	
	return true

## Get human-readable description
func get_description() -> String:
	var desc = ""
	
	match type:
		Type.THRUST:
			desc = "Thrust to " + TargetZone.get_zone_name(target_zone)
			if bonus_die_spent:
				desc += " (negating damage penalty)"
		Type.SWING:
			desc = "Swing at " + TargetZone.get_zone_name(target_zone)
			if bonus_die_spent:
				desc += " (boosting damage)"
		Type.FEINT:
			desc = "Feint from %s to %s" % [
				TargetZone.get_zone_name(feint_original_zone),
				TargetZone.get_zone_name(target_zone)
			]
	
	desc += " (%d dice)" % dice_allocated
	return desc
