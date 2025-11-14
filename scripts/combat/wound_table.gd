# res://scripts/combat/wound_table.gd
class_name WoundTable
extends Node

# The Wound Table defines effects for each wound level at each body location
# This is a simplified 3-zone version for the demo

## Wound effect data organized by [zone][level]
const WOUND_DATA = {
	# HEAD WOUNDS - Most lethal
	TargetZone.SimpleZone.HEAD: {
		0: {
			"shock": 0, "pain": 0, "bl": 0,
			"desc": "Glancing blow to head"
		},
		1: {
			"shock": 2, "pain": 1, "bl": 3,
			"desc": "Bleeding cut to the head"
		},
		2: {
			"shock": 4, "pain": 3, "bl": 5,
			"knockdown": 8,
			"desc": "Deep gash, vision blurred and swimming"
		},
		3: {
			"shock": 6, "pain": 5, "bl": 7,
			"knockdown": 10, "knockout": 8,
			"desc": "Skull fracture, severe trauma, ears ringing"
		},
		4: {
			"shock": 8, "pain": 7, "bl": 9,
			"knockdown": 12, "knockout": 10,
			"desc": "Critical head trauma, brain damage likely"
		},
		5: {
			"death": true,
			"desc": "Instant death - head destroyed"
		}
	},
	
	# TORSO WOUNDS - Balanced
	TargetZone.SimpleZone.TORSO: {
		0: {
			"shock": 0, "pain": 0, "bl": 0,
			"desc": "Scratch, armor took most of it"
		},
		1: {
			"shock": 1, "pain": 1, "bl": 3,
			"desc": "Flesh wound, minor bleeding"
		},
		2: {
			"shock": 3, "pain": 2, "bl": 5,
			"desc": "Deep cut, blood flowing freely"
		},
		3: {
			"shock": 5, "pain": 4, "bl": 6,
			"desc": "Organ damage, severe internal bleeding"
		},
		4: {
			"shock": 7, "pain": 6, "bl": 8,
			"knockdown": 10,
			"desc": "Critical internal damage, organs failing"
		},
		5: {
			"shock": 8, "pain": 8, "bl": 10,
			"desc": "Fatal wound - dying within minutes"
		}
	},
	
	# LIMB WOUNDS - Less lethal but crippling
	TargetZone.SimpleZone.LIMBS: {
		0: {
			"shock": 0, "pain": 0, "bl": 0,
			"desc": "Glancing blow, barely felt"
		},
		1: {
			"shock": 1, "pain": 0, "bl": 2,
			"desc": "Minor cut, barely bleeding"
		},
		2: {
			"shock": 2, "pain": 2, "bl": 4,
			"desc": "Muscle damage, limb weakened"
		},
		3: {
			"shock": 4, "pain": 3, "bl": 5,
			"desc": "Limb crippled, barely functional"
		},
		4: {
			"shock": 5, "pain": 4, "bl": 6,
			"desc": "Limb severed or nearly so"
		},
		5: {
			"shock": 6, "pain": 5, "bl": 7,
			"desc": "Limb completely destroyed"
		}
	}
}

## Look up wound effects for a given level and location
static func get_wound_effects(level: int, zone: TargetZone.SimpleZone) -> WoundData.WoundEffects:
	# Get the data for this zone and level
	var zone_data = WOUND_DATA.get(zone, {})
	var level_data = zone_data.get(level, {})
	
	if level_data.is_empty():
		push_error("No wound data for zone %d level %d!" % [zone, level])
		return WoundData.WoundEffects.new()
	
	# Create effects object
	var effects = WoundData.WoundEffects.new()
	effects.shock = level_data.get("shock", 0)
	effects.pain = level_data.get("pain", 0)
	effects.blood_loss = level_data.get("bl", 0)
	effects.knockdown_tn = level_data.get("knockdown", 0)
	effects.knockout_tn = level_data.get("knockout", 0)
	effects.instant_death = level_data.get("death", false)
	effects.description = level_data.get("desc", "Unknown wound")
	
	return effects

## Get a preview of what wound would result from given damage
static func preview_wound(
	damage_level: int,
	zone: TargetZone.SimpleZone
) -> String:
	damage_level = clampi(damage_level, 0, 5)
	var effects = get_wound_effects(damage_level, zone)
	return "L%d %s: %s" % [damage_level, TargetZone.get_zone_name(zone), effects.description]
