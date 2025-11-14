# res://scripts/combat/injury_manager.gd
class_name InjuryManager
extends Node

# The Injury Manager tracks all wounds and manages their cumulative effects
# It handles Blood Loss checks, Pain accumulation, and death conditions

## All wounds this character has received
var wounds: Array[WoundData] = []

## Blood Loss tracking
var current_blood_loss_tn: int = 0
var affected_locations: Array = []

## Signals
signal wound_added(wound: WoundData)
signal blood_loss_checked(success: bool, brawn_lost: bool)
signal character_died(cause: String)

## Add a new wound and apply its immediate effects
func add_wound(wound: WoundData, character_attributes: CharacterAttributes, combat_pool: CombatPool):
	wounds.append(wound)
	
	print("\n=== WOUND RECEIVED ===")
	print(wound.get_summary())
	
	# Check for instant death
	if wound.effects.instant_death:
		print("INSTANT DEATH!")
		character_died.emit("Instant death from wound")
		return
	
	# Update Blood Loss TN if this is a new location
	if wound.location not in affected_locations:
		affected_locations.append(wound.location)
		current_blood_loss_tn += wound.effects.blood_loss
		print("Blood Loss TN increased to %d" % current_blood_loss_tn)
	
	# Apply immediate Shock
	if wound.effects.shock > 0:
		combat_pool.apply_shock(wound.effects.shock)
		print("Applied %d Shock to Combat Pool" % wound.effects.shock)
	
	# Apply persistent Pain (reduced by Presence)
	if wound.effects.pain > 0:
		var effective_pain = calculate_effective_pain(
			wound.effects.pain,
			character_attributes.presence
		)
		combat_pool.apply_pain_penalty(effective_pain)
		print("Applied %d Pain to Combat Pool (reduced from %d by Presence)" % [
			effective_pain, wound.effects.pain
		])
	
	print("===================\n")
	
	wound_added.emit(wound)

## Calculate effective pain after Presence reduction
func calculate_effective_pain(base_pain: int, presence: int) -> int:
	# Presence 4 = average, higher reduces pain
	var reduction = max(0, presence - 4)
	var effective = max(0, base_pain - reduction)
	return effective

## Check for blood loss at start of round
## Returns true if survived, false if lost Brawn
func check_blood_loss(character_attributes: CharacterAttributes) -> bool:
	if current_blood_loss_tn == 0:
		return true  # No bleeding
	
	print("\n--- Blood Loss Check ---")
	print("Rolling Brawn %d vs TN %d" % [character_attributes.brawn, current_blood_loss_tn])
	
	var roll = DiceSystem.roll_pool(character_attributes.brawn, current_blood_loss_tn)
	print("Rolled: %s = %d successes" % [roll.rolls, roll.successes])
	
	var success = roll.successes > 0
	
	if success:
		print("Resisted blood loss!")
		blood_loss_checked.emit(true, false)
		return true
	else:
		print("Failed! Losing 1 Brawn...")
		character_attributes.brawn -= 1
		print("Brawn now: %d" % character_attributes.brawn)
		
		blood_loss_checked.emit(false, true)
		
		# Check for death
		if character_attributes.brawn <= 0:
			print("DEATH BY BLOOD LOSS!")
			character_died.emit("Bled to death")
			return false
	
	print("---\n")
	return true

## Check for knockdown
func check_knockdown(character_attributes: CharacterAttributes, tn: int) -> bool:
	if tn == 0:
		return false
	
	print("\n--- Knockdown Check ---")
	print("Rolling Resistance %d vs TN %d" % [character_attributes.resistance, tn])
	
	var roll = DiceSystem.roll_pool(character_attributes.resistance, tn)
	print("Rolled: %s = %d successes" % [roll.rolls, roll.successes])
	
	var knocked_down = roll.successes == 0
	
	if knocked_down:
		print("KNOCKED DOWN! Combat Pool reduced to 1/3")
	else:
		print("Stayed on feet!")
	
	print("---\n")
	
	return knocked_down

## Check for knockout
func check_knockout(character_attributes: CharacterAttributes, tn: int) -> bool:
	if tn == 0:
		return false
	
	print("\n--- Knockout Check ---")
	print("Rolling Resistance %d vs TN %d" % [character_attributes.resistance, tn])
	
	var roll = DiceSystem.roll_pool(character_attributes.resistance, tn)
	print("Rolled: %s = %d successes" % [roll.rolls, roll.successes])
	
	var knocked_out = roll.successes == 0
	
	if knocked_out:
		print("KNOCKED UNCONSCIOUS!")
		if roll.is_fumble:
			print("Fumbled! Unconscious for extended time...")
	else:
		print("Stayed conscious!")
	
	print("---\n")
	
	return knocked_out

## Get total pain from all wounds
func get_total_pain() -> int:
	var total = 0
	for wound in wounds:
		if wound.effects:
			total += wound.effects.pain
	return total

## Get current shock (only from wounds received this round)
func get_current_shock() -> int:
	var total = 0
	for wound in wounds:
		if wound.received_this_round and wound.effects:
			total += wound.effects.shock
	return total

## Mark all wounds as old (called at end of round)
func end_round():
	for wound in wounds:
		wound.received_this_round = false

## Get summary of all wounds
func get_wounds_summary() -> String:
	if wounds.is_empty():
		return "No wounds"
	
	var summary = ""
	for i in range(wounds.size()):
		summary += "%d. %s\n" % [i + 1, wounds[i].get_summary()]
	
	return summary.strip_edges()
