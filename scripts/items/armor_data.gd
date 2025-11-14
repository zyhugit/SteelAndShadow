# res://scripts/items/armor_data.gd
class_name ArmorData
extends Resource

# Defines armor statistics and protection values

enum ArmorType {
	NONE,
	LEATHER,
	CHAINMAIL,
	PLATE
}

@export var armor_type: ArmorType = ArmorType.LEATHER
@export var armor_name: String = "Leather Jack"

## Armor Values by zone (damage reduction)
@export var armor_values: Dictionary = {
	TargetZone.SimpleZone.HEAD: 0,
	TargetZone.SimpleZone.TORSO: 2,
	TargetZone.SimpleZone.LIMBS: 1
}

## Combat Pool penalty (heavy armor slows you down)
@export var cp_penalty: int = 0

## Properties
@export var weight: float = 10.0

func get_armor_value(zone: TargetZone.SimpleZone) -> int:
	return armor_values.get(zone, 0)
