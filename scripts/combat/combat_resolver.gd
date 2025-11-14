# res://scripts/combat/combat_resolver.gd
class_name CombatResolver
extends Node

# The Combat Resolver takes an attack and defense maneuver
# and determines the outcome using dice rolls
# This is where the magic happens!

## Resolve an attack/defense exchange
## Returns a CombatResult with all outcome information
func resolve_attack(
	attack: AttackManeuver,
	defense: DefenseManeuver,
	attacker_weapon_atn: int,
	defender_weapon_parry_tn: int,
	defender_shield_block_tn: int
) -> CombatResult:
	
	var result = CombatResult.new()
	
	print("\n--- Resolving Combat Exchange ---")
	print("Attack: ", attack.get_description())
	print("Defense: ", defense.get_description())
	
	# Get effective dice counts
	var attack_dice = attack.get_effective_dice()
	var defense_dice = defense.dice_allocated
	
	result.attack_dice_used = attack_dice
	result.defense_dice_used = defense_dice
	
	# Get target numbers
	var attack_tn = attacker_weapon_atn
	var defense_tn = defense.get_dtn_for_equipment(
		defender_weapon_parry_tn,
		defender_shield_block_tn
	)
	
	print("Rolling: %d attack dice vs TN %d" % [attack_dice, attack_tn])
	print("Rolling: %d defense dice vs TN %d" % [defense_dice, defense_tn])
	
	# ROLL THE DICE!
	var attack_roll = DiceSystem.roll_pool(attack_dice, attack_tn)
	var defense_roll = DiceSystem.roll_pool(defense_dice, defense_tn)
	
	result.attack_successes = attack_roll.successes
	result.defense_successes = defense_roll.successes
	result.attacker_fumbled = attack_roll.is_fumble
	result.defender_fumbled = defense_roll.is_fumble
	
	print("Attack: %s = %d successes%s" % [
		attack_roll.rolls, 
		attack_roll.successes,
		" (FUMBLE!)" if attack_roll.is_fumble else ""
	])
	print("Defense: %s = %d successes%s" % [
		defense_roll.rolls,
		defense_roll.successes,
		" (FUMBLE!)" if defense_roll.is_fumble else ""
	])
	
	# Handle fumbles
	if attack_roll.is_fumble:
		result.attacker_dice_lost = attack_dice / 2
		result.margin = -999  # Auto-fail
		print("Attacker fumbled! Loses %d dice next exchange" % result.attacker_dice_lost)
	else:
		result.margin = attack_roll.successes - defense_roll.successes
	
	# Determine if attack hit
	if result.margin > 0:
		result.hit = true
		print("HIT! Margin of success: %d" % result.margin)
		
		# Calculate damage! (NEW)
		# Note: We need these parameters passed in, so we'll add them to function signature
		# For now, we'll add a separate calculate_damage_for_result function
	else:
		print("MISS! Defense successful (margin: %d)" % result.margin)
	
	# Apply defense special effects
	_apply_defense_effects(result, defense, attack_dice)
	
	print("Result: ", result.get_summary())
	print("---\n")
	
	return result

## Apply special effects from defense maneuvers
func _apply_defense_effects(
	result: CombatResult,
	defense: DefenseManeuver,
	attack_dice: int
):
	# Only apply if defense succeeded (margin <= 0)
	if result.margin > 0:
		return
	
	match defense.type:
		DefenseManeuver.Type.DUCK_WEAVE:
			# Duck & Weave: steal initiative + attacker loses dice
			result.initiative_stolen = true
			result.attacker_dice_lost = attack_dice / 2
			print("Duck & Weave success! Initiative stolen, attacker loses %d dice" % result.attacker_dice_lost)
		
		DefenseManeuver.Type.COUNTER:
			if result.margin < 0:
				# Counter successful: steal initiative + bonus dice
				result.initiative_stolen = true
				result.defender_bonus_dice = attack_dice
				print("Counter success! Initiative stolen, defender gains %d bonus dice" % result.defender_bonus_dice)
			else:
				# Counter tied: attacker gets +1 success
				result.margin = 1
				result.hit = true
				print("Counter tied! Attacker gets +1 success bonus")
		
		DefenseManeuver.Type.DODGE_STAND:
			# Can spend 2 CP to steal initiative (we'll handle CP spending in combat manager)
			result.initiative_stolen = true
			print("Dodge & Stand success! Can steal initiative for 2 CP")
		
		DefenseManeuver.Type.DODGE_BREAK:
			# Combat disengages
			result.combat_disengaged = true
			print("Dodge & Break success! Combat disengaged")

## Calculate damage for a successful hit
## Call this after resolve_attack if result.hit == true
func calculate_damage_for_result(
	result: CombatResult,
	attack: AttackManeuver,
	attacker_brawn: int,
	weapon_brawn_modifier: int,
	defender_brawn: int,
	armor_value: int
):
	if not result.hit:
		return
	
	var wound = DamageCalculator.calculate_damage(
		attacker_brawn,
		weapon_brawn_modifier,
		attack,
		result.margin,
		defender_brawn,
		armor_value
	)
	
	result.damage_wound = wound
