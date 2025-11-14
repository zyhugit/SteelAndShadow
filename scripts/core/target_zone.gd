# res://scripts/core/target_zone.gd
class_name TargetZone
extends Node

# Defines body zones that can be targeted in combat
# For the demo, we use a simplified 3-zone system

## Simplified zones for demo (easier to balance)
enum SimpleZone {
	HEAD = 0,   # High risk, high reward (lethal but well-defended)
	TORSO = 1,  # Balanced choice (good damage, moderate defense)
	LIMBS = 2   # Lower risk (crippling but less lethal)
}

## Get human-readable name for a zone
static func get_zone_name(zone: SimpleZone) -> String:
	match zone:
		SimpleZone.HEAD:
			return "Head"
		SimpleZone.TORSO:
			return "Torso"
		SimpleZone.LIMBS:
			return "Limbs"
	return "Unknown"

## Get description of what hitting this zone does
static func get_zone_description(zone: SimpleZone) -> String:
	match zone:
		SimpleZone.HEAD:
			return "Lethal damage but heavily defended"
		SimpleZone.TORSO:
			return "Balanced damage and defense"
		SimpleZone.LIMBS:
			return "Crippling wounds, harder to defend"
	return "Unknown zone"

## Get all available zones as an array
static func get_all_zones() -> Array[SimpleZone]:
	return [SimpleZone.HEAD, SimpleZone.TORSO, SimpleZone.LIMBS]
