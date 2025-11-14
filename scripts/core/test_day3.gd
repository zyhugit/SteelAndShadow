# res://scripts/core/test_day3.gd
extends Node

# Test script for Day 3 - Combat Resolution

func _ready():
	print("\n" + "=".repeat(60))
	print("DAY 3 COMBAT SYSTEM TEST")
	print("=".repeat(60) + "\n")
	
	test_basic_attack()
	test_defense_types()
	test_special_maneuvers()
	test_full_exchange()
	
	print("\n" + "=".repeat(60))
	print("ALL DAY 3 TESTS COMPLETE!")
	print("=".repeat(60) + "\n")

## Test 1: Basic Attack vs Defense
func test_basic_attack():
	print("=== TEST 1: Basic Attack vs Defense ===\n")
	
	var resolver = CombatResolver.new()
	add_child(resolver)
	
	# Create a basic swing attack
	var attack = AttackManeuver.new()
	attack.type = AttackManeuver.Type.SWING
	attack.target_zone = TargetZone.SimpleZone.TORSO
	attack.dice_allocated = 6
	
	# Create a parry defense
	var defense = DefenseManeuver.new()
	defense.type = DefenseManeuver.Type.PARRY
	defense.dice_allocated = 4
	
	# Resolve (weapon ATN 6, parry DTN 6, no shield)
	var result = resolver.resolve_attack(attack, defense, 6, 6, 999)
	
	print("Final outcome: %s\n" % ("HIT" if result.hit else "MISS"))
	
	resolver.queue_free()

## Test 2: Different Defense Types
func test_defense_types():
	print("=== TEST 2: Different Defense Types ===\n")
	
	var resolver = CombatResolver.new()
	add_child(resolver)
	
	# Same attack for all tests
	var attack = AttackManeuver.new()
	attack.type = AttackManeuver.Type.SWING
	attack.target_zone = TargetZone.SimpleZone.HEAD
	attack.dice_allocated = 7
	
	# Test different defenses
	var defense_types = [
		{"type": DefenseManeuver.Type.PARRY, "name": "Parry"},
		{"type": DefenseManeuver.Type.DODGE_STAND, "name": "Dodge & Stand"},
		{"type": DefenseManeuver.Type.DUCK_WEAVE, "name": "Duck & Weave"}
	]
	
	for def_type in defense_types:
		var defense = DefenseManeuver.new()
		defense.type = def_type.type
		defense.dice_allocated = 5
		
		print("--- Testing %s ---" % def_type.name)
		var result = resolver.resolve_attack(attack, defense, 6, 6, 999)
		print("Outcome: %s" % result.get_summary())
		print("")
	
	resolver.queue_free()

## Test 3: Special Maneuvers (Thrust, Feint, Counter)
func test_special_maneuvers():
	print("=== TEST 3: Special Maneuvers ===\n")
	
	var resolver = CombatResolver.new()
	add_child(resolver)
	
	# Test Thrust (fast but less damage)
	print("--- Testing THRUST ---")
	var thrust = AttackManeuver.new()
	thrust.type = AttackManeuver.Type.THRUST
	thrust.target_zone = TargetZone.SimpleZone.TORSO
	thrust.dice_allocated = 5  # Will roll 6 dice (5 + 1 bonus)
	
	var defense1 = DefenseManeuver.new()
	defense1.type = DefenseManeuver.Type.PARRY
	defense1.dice_allocated = 4
	
	var result1 = resolver.resolve_attack(thrust, defense1, 6, 6, 999)
	print("Thrust gets +1 die: allocated %d, rolled %d" % [
		thrust.dice_allocated,
		thrust.get_effective_dice()
	])
	print("Damage modifier: %d\n" % thrust.get_damage_modifier())
	
	# Test Counter (risky but rewarding)
	print("--- Testing COUNTER ---")
	var attack2 = AttackManeuver.new()
	attack2.type = AttackManeuver.Type.SWING
	attack2.target_zone = TargetZone.SimpleZone.TORSO
	attack2.dice_allocated = 8
	
	var counter = DefenseManeuver.new()
	counter.type = DefenseManeuver.Type.COUNTER
	counter.dice_allocated = 5
	
	var result2 = resolver.resolve_attack(attack2, counter, 6, 6, 999)
	if result2.initiative_stolen:
		print("Counter successful! Defender will get %d bonus dice on next attack!" % result2.defender_bonus_dice)
	print("")
	
	# Test Feint (deceptive)
	print("--- Testing FEINT ---")
	var feint = AttackManeuver.new()
	feint.type = AttackManeuver.Type.FEINT
	feint.dice_allocated = 6
	feint.feint_original_zone = TargetZone.SimpleZone.LIMBS
	feint.target_zone = TargetZone.SimpleZone.HEAD
	feint.feint_dice_added = 3  # Spending 3 extra dice to change target
	
	print(feint.get_description())
	print("Effective dice: %d (6 allocated + 3 added)" % feint.get_effective_dice())
	print("")
	
	resolver.queue_free()


# Add this to test_day3.gd
func test_full_exchange():
	print("=== FULL COMBAT EXCHANGE ===\n")
	
	var resolver = CombatResolver.new()
	add_child(resolver)
	
	# Warrior (CP 9) vs Bandit
	var warrior_cp = 9
	
	print("WARRIOR starts with %d CP\n" % warrior_cp)
	
	# Exchange 1: Warrior attacks with 6 dice
	print("--- Exchange 1: Warrior attacks ---")
	var attack1 = AttackManeuver.new()
	attack1.type = AttackManeuver.Type.SWING
	attack1.target_zone = TargetZone.SimpleZone.TORSO
	attack1.dice_allocated = 6
	
	var defense1 = DefenseManeuver.new()
	defense1.type = DefenseManeuver.Type.PARRY
	defense1.dice_allocated = 4
	
	var longsword = load("res://data/weapons/longsword_standard.tres")
	var attack_tn = longsword.attack_tn_swing
	var defense_tn = longsword.defense_tn_parry
	
	var result1 = resolver.resolve_attack(attack1, defense1, attack_tn, defense_tn, 999)
	warrior_cp -= 6  # Spent 6 dice
	print("Warrior CP remaining: %d\n" % warrior_cp)
	
	# Exchange 2: Winner attacks with remaining dice
	if result1.hit:
		print("--- Exchange 2: Warrior attacks again (won Exchange 1) ---")
	else:
		print("--- Exchange 2: Bandit attacks (won Exchange 1) ---")
	
	var attack2 = AttackManeuver.new()
	attack2.type = AttackManeuver.Type.THRUST
	attack2.target_zone = TargetZone.SimpleZone.HEAD
	attack2.dice_allocated = warrior_cp  # Use remaining CP
	
	var defense2 = DefenseManeuver.new()
	defense2.type = DefenseManeuver.Type.DODGE_STAND
	defense2.dice_allocated = 3
	
	var attack_tn2 = longsword.attack_tn_thrust
	var defense_tn2 = longsword.defense_tn_parry
	var result2 = resolver.resolve_attack(attack2, defense2, attack_tn2, defense_tn2, 999)
	
	print("\n--- Round complete! ---")
	print("Warrior would refresh to 9 CP next round\n")
	
	resolver.queue_free()
