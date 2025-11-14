# res://scripts/core/dice_system.gd
class_name DiceSystem
extends Node

# This class handles all dice rolling for the game
# Players never see this - it runs in the background!

## Roll a pool of dice against a target number
## Returns a DiceResult with all the information we need
static func roll_pool(num_dice: int, target_number: int) -> DiceResult:
	var result = DiceResult.new()
	result.total_dice = num_dice
	result.target_number = target_number
	
	# Roll each die
	for i in range(num_dice):
		var roll = roll_single_die()
		result.rolls.append(roll)
		
		# Count successes
		if roll >= target_number:
			result.successes += 1
	
	# Check for fumble (critical failure)
	result.is_fumble = check_fumble(result)
	
	return result

## Roll a single d10 with stacking (10s explode)
static func roll_single_die() -> int:
	var total = 0
	var current_roll = randi_range(1, 10)  # Roll 1-10
	
	# If we roll 10, keep rolling and adding!
	while current_roll == 10:
		total += current_roll
		current_roll = randi_range(1, 10)
	
	total += current_roll
	return total

## Check if this roll is a fumble (critical failure)
## Fumble = no successes AND 2+ dice showing 1
static func check_fumble(result: DiceResult) -> bool:
	if result.successes > 0:
		return false  # Can't fumble if you succeeded
	
	var ones_count = 0
	for roll in result.rolls:
		if roll == 1:
			ones_count += 1
	
	return ones_count >= 2

## Calculate probability of at least 1 success
## This is shown to the player as "Hit Chance: 67%"
static func calculate_success_probability(num_dice: int, tn: int) -> float:
	if num_dice == 0:
		return 0.0
	
	# Math: P(at least 1 success) = 1 - P(all failures)
	# P(single die fails) = (tn - 1) / 10
	var prob_single_fail = float(tn - 1) / 10.0
	var prob_all_fail = pow(prob_single_fail, num_dice)
	
	return 1.0 - prob_all_fail

## Data class to hold dice roll results
class DiceResult:
	var total_dice: int = 0
	var target_number: int = 0
	var rolls: Array[int] = []  # Individual die results
	var successes: int = 0
	var is_fumble: bool = false
