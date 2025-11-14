# res://scripts/core/test_dice_system.gd
extends Node

# This is a simple test script to verify our dice system works
# We'll run this once and then delete it

func _ready():
	print("=== Testing DiceSystem ===")
	
	# Test 1: Roll 5 dice against TN 6
	print("\nTest 1: Rolling 5 dice vs TN 6")
	var result1 = DiceSystem.roll_pool(5, 6)
	print("Rolls: ", result1.rolls)
	print("Successes: ", result1.successes)
	print("Fumble: ", result1.is_fumble)
	
	# Test 2: Calculate probability
	print("\nTest 2: Probability calculation")
	var prob = DiceSystem.calculate_success_probability(5, 6)
	print("5 dice vs TN 6 has %.1f%% chance of at least 1 success" % (prob * 100))
	
	# Test 3: Roll multiple times to see randomness
	print("\nTest 3: Rolling 5 times to see variation")
	for i in range(5):
		var result = DiceSystem.roll_pool(3, 7)
		print("Roll %d: %s = %d successes" % [i+1, result.rolls, result.successes])
	
	# Test 4: Roll 10 dice against TN 8, to see how many rolls were exactly 10
	print("\nTest 4: Rolling 10 dice against TN 8")
	var num_allhit:int = 0
	for i in range(100):
		var result = DiceSystem.roll_pool(10, 4)
		print("Roll %d: %s = %d successes" % [i+1, result.rolls, result.successes])
		if result.successes == 10:
			num_allhit += 1
	print("Number of times that all 10 dice hit: %d" % [num_allhit])
	
	print("\n=== All tests complete! ===")
