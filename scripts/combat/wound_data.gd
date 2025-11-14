# res://scripts/combat/wound_data.gd
class_name WoundData
extends Resource

# Represents a single wound received in combat
# Wounds have levels (0-5) and effects (Shock, Pain, Blood Loss)

## Where the wound is located
@export var location: TargetZone.SimpleZone = TargetZone.SimpleZone.TORSO

## How severe (0 = scratch, 5 = fatal)
@export var level: int = 0

## When was this wound received? (for tracking)
var received_this_round: bool = true

## The effects of this wound
var effects: WoundEffects = null

## Effects data structure
class WoundEffects:
	var shock: int = 0           # Immediate CP loss (this round only)
	var pain: int = 0            # Persistent CP loss (until healed)
	var blood_loss: int = 0      # Blood Loss TN contribution
	var knockdown_tn: int = 0    # If > 0, must roll RES vs this or fall
	var knockout_tn: int = 0     # If > 0, must roll RES vs this or unconscious
	var instant_death: bool = false  # Level 5 head wounds
	var description: String = ""
	
	func wdata_tostring() -> String:
		var text = "Shock:%d Pain:%d BL:%d" % [shock, pain, blood_loss]
		if knockdown_tn > 0:
			text += " KD:%d" % knockdown_tn
		if knockout_tn > 0:
			text += " KO:%d" % knockout_tn
		if instant_death:
			text += " [FATAL]"
		return text

## Get a summary of this wound
func get_summary() -> String:
	return "L%d %s: %s (%s)" % [
		level,
		TargetZone.get_zone_name(location),
		effects.description if effects else "No effects",
		effects.wdata_tostring() if effects else ""
	]
