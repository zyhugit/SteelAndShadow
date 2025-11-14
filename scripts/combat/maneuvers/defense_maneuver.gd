# res://scripts/combat/maneuvers/defense_maneuver.gd
class_name DefenseManeuver
extends Resource

# Represents a defensive action in combat
# Player chooses: defense type and how many dice to use

## Defense Types
enum Type {
	PARRY,        # Deflect with weapon (DTN = weapon's parry TN)
	BLOCK,        # Block with shield (requires shield, DTN = shield's block TN)
	DODGE_BREAK,  # Full evasion, combat disengages (DTN 4)
	DODGE_STAND,  # Partial evasion, can steal initiative (DTN 7)
	DUCK_WEAVE,   # Step inside blow, steal initiative + opponent loses dice (DTN 9)
	COUNTER       # Riposte: costs 2 CP, huge payoff if successful (DTN = weapon's parry TN)
}

## Core properties
@export var type: Type = Type.PARRY
@export var dice_allocated: int = 0

## Calculate the target number for this defense
## Note: Requires equipment info, so we'll pass it as parameter
func get_dtn_for_equipment(weapon_parry_tn: int, shield_block_tn: int) -> int:
	match type:
		Type.PARRY:
			return weapon_parry_tn
		Type.BLOCK:
			return shield_block_tn
		Type.DODGE_BREAK:
			return 4
		Type.DODGE_STAND:
			return 7
		Type.DUCK_WEAVE:
			return 9
		Type.COUNTER:
			return weapon_parry_tn
	return 7  # Default fallback

## Get the upfront CP cost (only Counter costs extra)
func get_upfront_cost() -> int:
	return 2 if type == Type.COUNTER else 0

## Can this defense steal initiative?
func can_steal_initiative() -> bool:
	return type in [Type.DUCK_WEAVE, Type.COUNTER, Type.DODGE_STAND]

## Does this defense break combat?
func breaks_combat() -> bool:
	return type == Type.DODGE_BREAK

## Validate this defense is legal
func validate(has_shield: bool, available_cp: int) -> bool:
	# Must allocate at least 1 die
	if dice_allocated <= 0:
		print("Defense validation failed: Must allocate at least 1 die")
		return false
	
	# Block requires shield
	if type == Type.BLOCK and not has_shield:
		print("Defense validation failed: Block requires a shield")
		return false
	
	# Must have enough CP (including upfront cost)
	var total_cost = dice_allocated + get_upfront_cost()
	if total_cost > available_cp:
		print("Defense validation failed: Costs %d CP, only %d available" % [total_cost, available_cp])
		return false
	
	# Counter needs at least 3 total dice (2 upfront + 1 to roll)
	if type == Type.COUNTER and dice_allocated < 1:
		print("Defense validation failed: Counter needs at least 1 die to roll after paying 2 CP cost")
		return false
	
	return true

## Get human-readable description
func get_description() -> String:
	var desc = ""
	
	match type:
		Type.PARRY:
			desc = "Parry with weapon"
		Type.BLOCK:
			desc = "Block with shield"
		Type.DODGE_BREAK:
			desc = "Dodge and disengage"
		Type.DODGE_STAND:
			desc = "Dodge and stand ground"
		Type.DUCK_WEAVE:
			desc = "Duck and weave inside"
		Type.COUNTER:
			desc = "Counter-attack (riposte)"
	
	desc += " (%d dice)" % dice_allocated
	
	if get_upfront_cost() > 0:
		desc += " [Costs %d CP upfront]" % get_upfront_cost()
	
	return desc
