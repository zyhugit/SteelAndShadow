# res://scripts/core/test_day5.gd
extends Node

# Test script for Day 5 - Damage and Wounds

func _ready():
	print("\n" + "=".repeat(70))
	print("DAY 5 DAMAGE & WOUND SYSTEM TEST")
	print("=".repeat(70) + "\n")
	
	test_wound_table()
	test_damage_calculation()
	test_injury_manager()
	test_full_combat_with_damage()
	
	print("\n" + "=".repeat(70))
	print("ALL DAY 5 TESTS COMPLETE!")
	print("=".repeat(70) + "\n")

## Test 1: Wound Table Lookups
func test_wound_table():
	print("=== TEST 1: Wound Table ===\n")
	
	# Test each zone at different levels
	var zones = [
		TargetZone.SimpleZone.HEAD,
		TargetZone.SimpleZone.TORSO,
		TargetZone.SimpleZone.LIMBS
	]
	
	for zone in zones:
		print("--- %s Wounds ---" % TargetZone.get_zone_name(zone))
		for level in range(6):
			var effects = WoundTable.get_wound_effects(level, zone)
			print("L%d: %s %s" % [level, effects.description, effects.wdata_tostring()])
		print("")

## Test 2: Damage Calculation
func test_damage_calculation():
	print("=== TEST 2: Damage Calculation ===\n")
	
	# Scenario: Warrior (Brawn 6) with longsword (+2) hits unarmored bandit (Brawn 4)
	var attack = AttackManeuver.new()
	attack.type = AttackManeuver.Type.SWING
	attack.target_zone = TargetZone.SimpleZone.TORSO
	
	print("--- Scenario: Warrior vs Unarmored Bandit ---")
	print("Attacker: Brawn 6, Weapon +2 (DR 8)")
	print("Defender: Brawn 4, No Armor (AV 0)")
	print("")
	
	# Test different margins of success
	for margin in [1, 3, 5]:
		print("Margin of Success: %d" % margin)
		var wound = DamageCalculator.calculate_damage(
			6,  # attacker brawn
			2,  # weapon modifier
			attack,
			margin,
			4,  # defender brawn
			0   # armor value
		)
	
	print("\n--- Scenario: Same attack vs Armored Knight ---")
	print("Defender: Brawn 5, Plate Armor (AV 6)")
	print("")
	
	for margin in [1, 3, 5]:
		print("Margin of Success: %d" % margin)
		var wound = DamageCalculator.calculate_damage(
			6,  # attacker brawn
			2,  # weapon modifier
			attack,
			margin,
			5,  # defender brawn (higher)
			6   # armor value (heavy!)
		)

## Test 3: Injury Manager
func test_injury_manager():
	print("\n=== TEST 3: Injury Manager ===\n")
	
	# Create test character
	var attrs = CharacterAttributes.new()
	attrs.agility = 5
	attrs.brawn = 6
	attrs.wits = 4
	attrs.presence = 4
	
	var pool = CombatPool.new()
	add_child(pool)
	pool.initialize(9)
	
	var injury_mgr = InjuryManager.new()
	add_child(injury_mgr)
	
	print("Character: Brawn %d, Presence %d, CP %d\n" % [attrs.brawn, attrs.presence, pool.max_pool])
	
	# Apply a Level 2 torso wound
	print("--- Applying Level 2 Torso Wound ---")
	var wound1 = WoundData.new()
	wound1.location = TargetZone.SimpleZone.TORSO
	wound1.level = 2
	wound1.effects = WoundTable.get_wound_effects(2, TargetZone.SimpleZone.TORSO)
	
	injury_mgr.add_wound(wound1, attrs, pool)
	
	print("\nAfter wound:")
	print("CP: %d/%d (Shock + Pain applied)" % [pool.current_pool, pool.max_pool])
	print("Blood Loss TN: %d" % injury_mgr.current_blood_loss_tn)
	
	# Apply a Level 3 head wound
	print("\n--- Applying Level 3 Head Wound ---")
	var wound2 = WoundData.new()
	wound2.location = TargetZone.SimpleZone.HEAD
	wound2.level = 3
	wound2.effects = WoundTable.get_wound_effects(3, TargetZone.SimpleZone.HEAD)
	
	injury_mgr.add_wound(wound2, attrs, pool)
	
	print("\nAfter second wound:")
	print("CP: %d/%d" % [pool.current_pool, pool.max_pool])
	print("Blood Loss TN: %d" % injury_mgr.current_blood_loss_tn)
	
	# Test knockdown
	if wound2.effects.knockdown_tn > 0:
		injury_mgr.check_knockdown(attrs, wound2.effects.knockdown_tn)
	
	# Test knockout
	if wound2.effects.knockout_tn > 0:
		injury_mgr.check_knockout(attrs, wound2.effects.knockout_tn)
	
	# Test blood loss
	print("--- Testing Blood Loss Check ---")
	injury_mgr.check_blood_loss(attrs)
	
	print("\nWounds Summary:")
	print(injury_mgr.get_wounds_summary())
	
	pool.queue_free()
	injury_mgr.queue_free()

## Test 4: Full Combat with Damage
func test_full_combat_with_damage():
	print("\n=== TEST 4: Full Combat with Damage ===\n")
	
	# Create two fighters
	var warrior_attrs = CharacterAttributes.new()
	warrior_attrs.agility = 5
	warrior_attrs.brawn = 6
	warrior_attrs.wits = 4
	warrior_attrs.presence = 4
	
	var bandit_attrs = CharacterAttributes.new()
	bandit_attrs.agility = 4
	bandit_attrs.brawn = 4
	bandit_attrs.wits = 3
	bandit_attrs.presence = 3
	
	var warrior_pool = CombatPool.new()
	add_child(warrior_pool)
	warrior_pool.initialize(9)  # Coordination 4 + Prof 5
	
	var bandit_pool = CombatPool.new()
	add_child(bandit_pool)
	bandit_pool.initialize(7)  # Coordination 3 + Prof 4
	
	var warrior_injuries = InjuryManager.new()
	add_child(warrior_injuries)
	
	var bandit_injuries = InjuryManager.new()
	add_child(bandit_injuries)
	
	var resolver = CombatResolver.new()
	add_child(resolver)
	
	print("WARRIOR: Brawn %d, CP %d" % [warrior_attrs.brawn, warrior_pool.max_pool])
	print("BANDIT: Brawn %d, CP %d" % [bandit_attrs.brawn, bandit_pool.max_pool])
	print("")
	
	# Round 1
	print("=== ROUND 1 ===\n")
	
	# Warrior attacks
	var attack = AttackManeuver.new()
	attack.type = AttackManeuver.Type.SWING
	attack.target_zone = TargetZone.SimpleZone.TORSO
	attack.dice_allocated = 6
	
	var defense = DefenseManeuver.new()
	defense.type = DefenseManeuver.Type.PARRY
	defense.dice_allocated = 4
	
	warrior_pool.allocate(6)
	bandit_pool.allocate(4)
	
	var result = resolver.resolve_attack(attack, defense, 6, 6, 999)
	
	if result.hit:
		resolver.calculate_damage_for_result(
			result,
			attack,
			warrior_attrs.brawn,
			2,  # longsword modifier
			bandit_attrs.brawn,
			1   # light armor
		)
		
		if result.damage_wound:
			bandit_injuries.add_wound(result.damage_wound, bandit_attrs, bandit_pool)
	
	print("\nEnd of Round 1:")
	print("WARRIOR: CP %d/%d, Wounds: %s" % [
		warrior_pool.current_pool, warrior_pool.max_pool,
		"None" if warrior_injuries.wounds.is_empty() else warrior_injuries.get_wounds_summary()
	])
	print("BANDIT: CP %d/%d, Wounds: %s" % [
		bandit_pool.current_pool, bandit_pool.max_pool,
		"None" if bandit_injuries.wounds.is_empty() else bandit_injuries.get_wounds_summary()
	])
	
	# Clean up
	warrior_pool.queue_free()
	bandit_pool.queue_free()
	warrior_injuries.queue_free()
	bandit_injuries.queue_free()
	resolver.queue_free()
