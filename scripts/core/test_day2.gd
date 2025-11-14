# res://scripts/core/test_day2.gd
extends Node

# Test script for Day 2 systems
# Tests CharacterAttributes, CombatPool, and TargetZone

func _ready():
	print("\n" + "=".repeat(50))
	print("DAY 2 SYSTEMS TEST")
	print("=".repeat(50) + "\n")
	
	test_character_attributes()
	test_combat_pool()
	test_target_zones()
	
	var warrior = load("res://data/preset_characters/warrior_attributes.tres")
	var rogue = load("res://data/preset_characters/rogue_attributes.tres")
	print("Loaded Warrior: ", warrior.attr_tostring())
	print("Loaded Rogue: ", rogue.attr_tostring())
	
	print("\n" + "=".repeat(50))
	print("ALL DAY 2 TESTS COMPLETE!")
	print("=".repeat(50) + "\n")

## Test 1: Character Attributes
func test_character_attributes():
	print("--- TEST 1: Character Attributes ---\n")
	
	# Create a warrior character
	var warrior_attrs = CharacterAttributes.new()
	warrior_attrs.agility = 5
	warrior_attrs.brawn = 6
	warrior_attrs.wits = 4
	warrior_attrs.presence = 4
	
	print("Warrior attributes: ", warrior_attrs.attr_tostring())
	print("Coordination (AGL+WTS)/2 = (%d+%d)/2 = %d" % [
		warrior_attrs.agility, warrior_attrs.wits, warrior_attrs.coordination
	])
	print("Resistance (BRN+PRS)/2 = (%d+%d)/2 = %d" % [
		warrior_attrs.brawn, warrior_attrs.presence, warrior_attrs.resistance
	])
	print("Valid attributes? ", warrior_attrs.validate())
	
	# Create a rogue character
	var rogue_attrs = CharacterAttributes.new()
	rogue_attrs.agility = 6
	rogue_attrs.brawn = 4
	rogue_attrs.wits = 6
	rogue_attrs.presence = 4
	
	print("\nRogue attributes: ", rogue_attrs.attr_tostring())
	print("Rogue is faster (AGL %d > %d) but weaker (BRN %d < %d)" % [
		rogue_attrs.agility, warrior_attrs.agility,
		rogue_attrs.brawn, warrior_attrs.brawn
	])
	
	print("\n")

## Test 2: Combat Pool
func test_combat_pool():
	print("--- TEST 2: Combat Pool ---\n")
	
	# Create a combat pool
	var pool = CombatPool.new()
	add_child(pool)  # Need to add to tree for signals to work
	
	# Simulate a character with Coordination 5 + Proficiency 4
	var base_cp = 5 + 4
	pool.initialize(base_cp)
	
	print("Starting Combat Pool: %d\n" % base_cp)
	
	# Simulate Exchange 1: Attack with 6 dice
	print("Exchange 1: Allocating 6 dice for attack")
	var success = pool.allocate(6)
	print("Success: %s, Remaining: %d\n" % [success, pool.get_remaining()])
	
	# Try to allocate more than we have
	print("Trying to allocate 5 dice (only %d available)" % pool.get_remaining())
	success = pool.allocate(5)
	print("Success: %s\n" % success)
	
	# Allocate remaining for defense
	print("Allocating remaining %d dice for defense" % pool.get_remaining())
	success = pool.allocate(pool.get_remaining())
	print("Success: %s, Remaining: %d\n" % [success, pool.get_remaining()])
	
	# Refresh for next round
	print("--- New Round Begins ---")
	pool.refresh()
	
	# Simulate taking a wound (3 shock, 2 pain)
	print("\nSimulating wound: 3 Shock, 2 Pain")
	pool.apply_shock(3)
	pool.apply_pain_penalty(2)
	
	var stats = pool.get_stats()
	print("Pool stats: Max=%d, Current=%d (%.1f%% remaining)" % [
		stats.max, stats.current, stats.percentage_remaining
	])
	
	pool.queue_free()  # Clean up
	print("\n")

## Test 3: Target Zones
func test_target_zones():
	print("--- TEST 3: Target Zones ---\n")
	
	var zones = TargetZone.get_all_zones()
	print("Available target zones:")
	
	for zone in zones:
		print("  - %s: %s" % [
			TargetZone.get_zone_name(zone),
			TargetZone.get_zone_description(zone)
		])
	
	print("\n")
