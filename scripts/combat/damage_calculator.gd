# res://scripts/combat/damage_calculator.gd
class_name DamageCalculator
extends Node

# The Damage Calculator determines wound severity from attack parameters
# Formula: Base Damage - Defender Brawn - Armor Value = Wound Level (0-5)

## Calculate damage and create a wound
static func calculate_damage(
	attacker_brawn: int,
	weapon_brawn_modifier: int,
	attack_maneuver: AttackManeuver,
	margin_of_success: int,
	defender_brawn: int,
	armor_value: int
) -> WoundData:
	
	print("\n--- Calculating Damage ---")
	
	# Step 1: Base damage = Weapon DR + Margin
	var weapon_dr = attacker_brawn + weapon_brawn_modifier
	var base_damage = weapon_dr + margin_of_success
	print("Weapon DR: %d (Brawn %d + Modifier %d)" % [weapon_dr, attacker_brawn, weapon_brawn_modifier])
	print("Margin of Success: %d" % margin_of_success)
	print("Base Damage: %d" % base_damage)
	
	# Step 2: Apply attack modifiers
	var attack_modifier = attack_maneuver.get_damage_modifier()
	base_damage += attack_modifier
	if attack_modifier != 0:
		print("Attack Modifier: %+d (now %d)" % [attack_modifier, base_damage])
	
	# Step 3: Subtract resistances
	var final_damage = base_damage - defender_brawn - armor_value
	print("Defender Brawn: -%d" % defender_brawn)
	print("Armor Value: -%d" % armor_value)
	print("Final Damage: %d" % final_damage)
	
	# Step 4: Clamp to valid wound level (0-5)
	var wound_level = clampi(final_damage, 0, 5)
	print("Wound Level: %d (clamped to 0-5)" % wound_level)
	
	# Step 5: Create wound with effects from table
	var wound = WoundData.new()
	wound.location = attack_maneuver.target_zone
	wound.level = wound_level
	wound.effects = WoundTable.get_wound_effects(wound_level, attack_maneuver.target_zone)
	
	print("Result: %s" % wound.get_summary())
	print("---\n")
	
	return wound

## Preview damage without creating a wound (for UI)
static func preview_damage_range(
	attacker_brawn: int,
	weapon_brawn_modifier: int,
	attack_maneuver: AttackManeuver,
	min_successes: int,
	max_successes: int,
	defender_brawn: int,
	armor_value: int
) -> Dictionary:
	
	var weapon_dr = attacker_brawn + weapon_brawn_modifier
	var attack_modifier = attack_maneuver.get_damage_modifier()
	
	# Calculate damage range
	var min_damage = weapon_dr + attack_modifier + min_successes - defender_brawn - armor_value
	var max_damage = weapon_dr + attack_modifier + max_successes - defender_brawn - armor_value
	
	# Clamp to valid levels
	min_damage = clampi(min_damage, 0, 5)
	max_damage = clampi(max_damage, 0, 5)
	
	return {
		"min": min_damage,
		"max": max_damage,
		"min_desc": WoundTable.preview_wound(min_damage, attack_maneuver.target_zone),
		"max_desc": WoundTable.preview_wound(max_damage, attack_maneuver.target_zone)
	}
