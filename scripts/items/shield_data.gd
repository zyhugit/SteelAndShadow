# res://scripts/items/shield_data.gd
class_name ShieldData
extends Resource

# Defines shield statistics

enum ShieldType {
	BUCKLER,
	HEATER,
	KITE
}

@export var shield_type: ShieldType = ShieldType.HEATER
@export var shield_name: String = "Heater Shield"

## Defense
@export var defense_tn_block: int = 5  # TN for Block maneuver
@export var passive_av: int = 4  # Armor value even when not blocking

## Penalties
@export var cp_penalty: int = 1

## Properties
@export var weight: float = 8.0
