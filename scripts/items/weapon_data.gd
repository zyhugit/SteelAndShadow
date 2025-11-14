# res://scripts/items/weapon_data.gd
class_name WeaponData
extends Resource

# Defines a weapon's combat statistics

enum WeaponType {
	LONGSWORD,
	SHORTSWORD,
	GREATSWORD,
	DAGGER,
	MACE
}

@export var weapon_type: WeaponType = WeaponType.LONGSWORD
@export var weapon_name: String = "Longsword"

## Damage
@export var damage_rating: int = 8  # Base damage (usually Brawn + modifier)
@export var brawn_modifier: int = 2  # Added to wielder's Brawn

## Target Numbers
@export var attack_tn_swing: int = 6
@export var attack_tn_thrust: int = 6
@export var defense_tn_parry: int = 6

## Properties
@export var grip: String = "1-handed"
@export var weight: float = 3.5

func get_atn_for_type(attack_type: AttackManeuver.Type) -> int:
	match attack_type:
		AttackManeuver.Type.THRUST:
			return attack_tn_thrust
		AttackManeuver.Type.SWING, AttackManeuver.Type.FEINT:
			return attack_tn_swing
	return attack_tn_swing
