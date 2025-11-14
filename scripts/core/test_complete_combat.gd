# res://scripts/core/test_complete_combat.gd
extends Node

# Complete combat test with full character data

func _ready():
	print("\n" + "=".repeat(70))
	print("COMPLETE COMBAT TEST - WARRIOR VS BANDIT")
	print("=".repeat(70) + "\n")
	
	# Load or create characters
	var warrior = create_warrior()
	var bandit = create_bandit()
	
	# Initialize for combat
	warrior.initialize_for_combat()
	bandit.initialize_for_combat()
	
	print("=== FIGHTERS ===\n")
	print(warrior.get_summary())
	print(bandit.get_summary())
	
	# Create resolver
	var resolver = CombatResolver.new()
	add_child(resolver)
	
	# Fight!
	simulate_combat_rounds(warrior, bandit, resolver, 3)
	
	# Clean up
	resolver.queue_free()
	
	print("\n" + "=".repeat(70))
	print("COMBAT TEST COMPLETE")
	print("=".repeat(70) + "\n")

func create_warrior() -> CharacterData:
	var char = CharacterData.new()
	char.character_name = "Ironclad Warrior"
	
	# Attributes
	var attrs = CharacterAttributes.new()
	attrs.agility = 5
	attrs.brawn = 6
	attrs.wits = 4
	attrs.presence = 4
	char.attributes = attrs
	
	# Equipment
	var equip = Equipment.new()
	equip.weapon = load("res://data/weapons/longsword_standard.tres")
	equip.armor = load("res://data/armor/chainmail.tres")
	equip.shield = load("res://data/shields/heater_shield.tres")
	char.equipment = equip
	
	# Proficiency
	char.proficiencies[WeaponData.WeaponType.LONGSWORD] = 5
	
	return char

func create_bandit() -> CharacterData:
	var char = CharacterData.new()
	char.character_name = "Bandit Raider"
	
	# Attributes (weaker)
	var attrs = CharacterAttributes.new()
	attrs.agility = 4
	attrs.brawn = 4
	attrs.wits = 3
	attrs.presence = 3
	char.attributes = attrs
	
	# Equipment (lighter)
	var equip = Equipment.new()
	equip.weapon = load("res://data/weapons/longsword_standard.tres")
	equip.armor = load("res://data/armor/leather_jack.tres")
	equip.shield = null  # No shield!
	char.equipment = equip
	
	# Proficiency (lower)
	char.proficiencies[WeaponData.WeaponType.LONGSWORD] = 3
	
	return char

func simulate_combat_rounds(
	warrior: CharacterData,
	bandit: CharacterData,
	resolver: CombatResolver,
	max_rounds: int
):
	for round_num in range(1, max_rounds + 1):
		print("\n" + "=".repeat(60))
		print("ROUND %d" % round_num)
		print("=".repeat(60) + "\n")
		
		# Refresh pools
		warrior.combat_pool.refresh()
		bandit.combat_pool.refresh()
		
		# Check blood loss
		if round_num > 1:
			print("--- Blood Loss Checks ---")
			warrior.injury_manager.check_blood_loss(warrior.attributes)
			bandit.injury_manager.check_blood_loss(bandit.attributes)
			print("")
		
		# Check if anyone died
		if not warrior.can_act():
			print("WARRIOR is out of the fight!")
			break
		if not bandit.can_act():
			print("BANDIT is out of the fight!")
			break
		
		# Exchange 1: Warrior attacks
		print("--- Exchange 1: Warrior Attacks ---\n")
		
		var attack1 = AttackManeuver.new()
		attack1.type = AttackManeuver.Type.SWING
		attack1.target_zone = TargetZone.SimpleZone.TORSO
		attack1.dice_allocated = 6
		
		var defense1 = DefenseManeuver.new()
		defense1.type = DefenseManeuver.Type.PARRY
		defense1.dice_allocated = 4
		
		warrior.combat_pool.allocate(6)
		bandit.combat_pool.allocate(4)
		
		var result1 = resolver.resolve_attack(
			attack1, defense1,
			warrior.equipment.get_weapon_atn(attack1.type),
			bandit.equipment.get_weapon_parry_tn(),
			bandit.equipment.get_shield_block_tn()
		)
		
		if result1.hit:
			resolver.calculate_damage_for_result(
				result1, attack1,
				warrior.attributes.brawn,
				warrior.equipment.weapon.brawn_modifier,
				bandit.attributes.brawn,
				bandit.equipment.get_total_protection(attack1.target_zone)
			)
			
			if result1.damage_wound:
				bandit.injury_manager.add_wound(
					result1.damage_wound,
					bandit.attributes,
					bandit.combat_pool
				)
				
				# Check for knockdown/knockout
				var wound_effects = result1.damage_wound.effects
				if wound_effects.knockdown_tn > 0:
					bandit.is_prone = bandit.injury_manager.check_knockdown(
						bandit.attributes,
						wound_effects.knockdown_tn
					)
				if wound_effects.knockout_tn > 0:
					bandit.is_unconscious = bandit.injury_manager.check_knockout(
						bandit.attributes,
						wound_effects.knockout_tn
					)
		
		# Check if bandit can continue
		if not bandit.can_act():
			print("\nBANDIT cannot continue!")
			break
		
		# Exchange 2: Counter-attack (if bandit has CP left)
		if bandit.combat_pool.get_remaining() > 0:
			print("\n--- Exchange 2: Bandit Counter-Attacks ---\n")
			
			var attack2 = AttackManeuver.new()
			attack2.type = AttackManeuver.Type.THRUST
			attack2.target_zone = TargetZone.SimpleZone.TORSO
			attack2.dice_allocated = bandit.combat_pool.get_remaining()
			
			var defense2 = DefenseManeuver.new()
			defense2.type = DefenseManeuver.Type.BLOCK
			defense2.dice_allocated = warrior.combat_pool.get_remaining()
			
			bandit.combat_pool.allocate(attack2.dice_allocated)
			warrior.combat_pool.allocate(defense2.dice_allocated)
			
			var result2 = resolver.resolve_attack(
				attack2, defense2,
				bandit.equipment.get_weapon_atn(attack2.type),
				warrior.equipment.get_weapon_parry_tn(),
				warrior.equipment.get_shield_block_tn()
			)
			
			if result2.hit:
				resolver.calculate_damage_for_result(
					result2, attack2,
					bandit.attributes.brawn,
					bandit.equipment.weapon.brawn_modifier,
					warrior.attributes.brawn,
					warrior.equipment.get_total_protection(attack2.target_zone)
				)
				
				if result2.damage_wound:
					warrior.injury_manager.add_wound(
						result2.damage_wound,
						warrior.attributes,
						warrior.combat_pool
					)
		
		# Round summary
		print("\n--- End of Round %d ---" % round_num)
		print("WARRIOR: CP %d/%d, Brawn %d, %d wounds" % [
			warrior.combat_pool.current_pool,
			warrior.combat_pool.max_pool,
			warrior.attributes.brawn,
			warrior.injury_manager.wounds.size()
		])
		print("BANDIT: CP %d/%d, Brawn %d, %d wounds" % [
			bandit.combat_pool.current_pool,
			bandit.combat_pool.max_pool,
			bandit.attributes.brawn,
			bandit.injury_manager.wounds.size()
		])
	
	# Final result
	print("\n" + "=".repeat(60))
	print("FINAL RESULT")
	print("=".repeat(60))
	print("\nWARRIOR:")
	print(warrior.get_summary())
	print("\nBANDIT:")
	print(bandit.get_summary())
