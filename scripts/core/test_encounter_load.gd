# res://scripts/core/test_encounter_load.gd
extends Node

# Test loading encounters from resources

func _ready():
	print("\n" + "=".repeat(70))
	print("ENCOUNTER LOADING TEST")
	print("=".repeat(70) + "\n")
	
	# Load encounter
	var encounter = load("res://data/encounters/duel_warrior_vs_bandit.tres") as EncounterData
	
	if not encounter:
		print("ERROR: Could not load encounter!")
		return
	
	print("Loaded encounter:")
	print(encounter.get_summary())
	print("")
	
	# Create combat manager and AI
	var combat_manager = CombatManager.new()
	add_child(combat_manager)
	
	var ai = AIController.new()
	add_child(ai)
	
	# Start combat from encounter
	combat_manager.start_combat(
		encounter.player_character,
		encounter.enemy_character
	)
	
	# Simulate combat
	simulate_combat(combat_manager, ai, encounter.max_rounds)

func simulate_combat(manager: CombatManager, ai: AIController, max_rounds: int):
	for round in range(max_rounds):
		if not manager.is_combat_active():
			break
		
		# Exchange 1
		var attacker = manager.initiative_holder
		var defender = manager.get_opponent(attacker)
		
		var attack_action = ai.decide_action(attacker, defender, true)
		var defense_action = ai.decide_action(defender, attacker, false)
		
		manager.execute_exchange(
			attacker, defender,
			attack_action.attack,
			defense_action.defense
		)
		
		if not manager.is_combat_active():
			break
		
		# Exchange 2
		attacker = manager.initiative_holder
		defender = manager.get_opponent(attacker)
		
		if attacker.combat_pool.get_remaining() > 0:
			attack_action = ai.decide_action(attacker, defender, true)
			defense_action = ai.decide_action(defender, attacker, false)
			
			manager.execute_exchange(
				attacker, defender,
				attack_action.attack,
				defense_action.defense
			)
