# res://scripts/character/equipment.gd
class_name Equipment
extends Resource

# Container for all equipment a character has

@export var weapon: WeaponData
@export var shield: ShieldData
@export var armor: ArmorData

## Get total CP penalty from all equipment
func get_total_cp_penalty() -> int:
	var penalty = 0
	if armor:
		penalty += armor.cp_penalty
	if shield:
		penalty += shield.cp_penalty
	return penalty

## Get armor value for a specific zone
func get_armor_value(zone: TargetZone.SimpleZone) -> int:
	if not armor:
		return 0
	return armor.get_armor_value(zone)

## Get passive shield protection (even when not blocking)
func get_passive_shield_av(zone: TargetZone.SimpleZone) -> int:
	if not shield:
		return 0
	# Shields protect torso and arms
	if zone in [TargetZone.SimpleZone.TORSO, TargetZone.SimpleZone.LIMBS]:
		return shield.passive_av
	return 0

## Get total protection (armor + passive shield)
func get_total_protection(zone: TargetZone.SimpleZone) -> int:
	return get_armor_value(zone) + get_passive_shield_av(zone)

## Check if we have a shield equipped
func has_shield() -> bool:
	return shield != null

## Get weapon attack TN for attack type
func get_weapon_atn(attack_type: AttackManeuver.Type) -> int:
	if not weapon:
		return 7  # Unarmed default
	return weapon.get_atn_for_type(attack_type)

## Get weapon parry TN
func get_weapon_parry_tn() -> int:
	if not weapon:
		return 8  # Unarmed default
	return weapon.defense_tn_parry

## Get shield block TN
func get_shield_block_tn() -> int:
	if not shield:
		return 999  # Can't block without shield
	return shield.defense_tn_block

## Get summary string
func equip_tostring() -> String:
	var parts = []
	if weapon:
		parts.append("Weapon: " + weapon.weapon_name)
	if shield:
		parts.append("Shield: " + shield.shield_name)
	if armor:
		parts.append("Armor: " + armor.armor_name)
	
	if parts.is_empty():
		return "Unarmed, Unarmored"
	
	return " | ".join(parts)
