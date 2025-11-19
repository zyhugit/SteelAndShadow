# res://scripts/combat/combat_manager.gd
class_name CombatManager
extends Node

# The Combat Manager orchestrates entire combat encounters
# It manages rounds, exchanges, initiative, and determines victory/defeat

## Flow control
@export var enable_round_pause: bool = true
@export var round_pause_duration: float = 0.5
@export var enable_action_pause: bool = true  # NEW
@export var action_pause_duration: float = 0.8  # NEW - pause after each action
@export var auto_simulate: bool = false
var ai_controller: AIController = null

## Signals for UI to react to combat events
signal combat_started(player: CharacterData, enemy: CharacterData)
signal round_started(round_number: int)
signal exchange_started(exchange_number: int, attacker: CharacterData)
signal attack_resolved(result: CombatResult, attacker: CharacterData, defender: CharacterData)
signal round_ended(round_number: int)
signal combat_ended(winner: CharacterData, loser: CharacterData)

## NEW: Add this signal with the others at the top
signal player_action_requested(character: CharacterData, is_attacking: bool)

## NEW: Add these state variables
var awaiting_player_input: bool = false
var player_attack: AttackManeuver = null
var player_defense: DefenseManeuver = null

## Combat participants
var player: CharacterData
var enemy: CharacterData

## Combat state
var current_round: int = 0
var current_exchange: int = 0
var initiative_holder: CharacterData = null
var combat_active: bool = false

## Systems
var resolver: CombatResolver

## Set AI controller for auto-simulation
func set_ai_controller(ai: AIController):
	ai_controller = ai

## Enable/disable pause between rounds
func set_pause_enabled(enabled: bool):
	enable_round_pause = enabled

## Set pause duration
func set_pause_duration(seconds: float):
	round_pause_duration = seconds
	
## Wait for a brief pause (if enabled)
func _pause_for_action():
	if enable_action_pause:
		await get_tree().create_timer(action_pause_duration).timeout
	
## Initialize combat with two fighters
func start_combat(player_character: CharacterData, enemy_character: CharacterData):
	print("\n" + "=".repeat(70))
	print("COMBAT BEGINS!")
	print("=".repeat(70) + "\n")
	
	player = player_character
	enemy = enemy_character
	
	# Initialize both characters for combat
	player.initialize_for_combat()
	enemy.initialize_for_combat()
	
	# Create resolver
	resolver = CombatResolver.new()
	add_child(resolver)
	
	# Combat state
	current_round = 0
	current_exchange = 0
	initiative_holder = null
	combat_active = true
	
	print("PLAYER: %s" % player.character_name)
	print(player.get_summary())
	print("\nENEMY: %s" % enemy.character_name)
	print(enemy.get_summary())
	
	combat_started.emit(player, enemy)
	
	# Start first round
	start_new_round()

## Start a new combat round
func start_new_round():
	current_round += 1
	current_exchange = 0
	
	print("\n" + "=".repeat(70))
	print("ROUND %d BEGINS" % current_round)
	print("=".repeat(70) + "\n")
	
	# Refresh combat pools
	player.combat_pool.refresh()
	enemy.combat_pool.refresh()
	
	# Mark wounds as old (no longer cause shock)
	if player.injury_manager:
		player.injury_manager.end_round()
	if enemy.injury_manager:
		enemy.injury_manager.end_round()
	
	# Check blood loss (after round 1)
	if current_round > 1:
		print("--- Blood Loss Checks ---")
		check_blood_loss(player)
		check_blood_loss(enemy)
		print("")
	
	# Check if anyone died from blood loss
	if not player.can_act():
		end_combat(enemy, player, "blood loss")
		return
	if not enemy.can_act():
		end_combat(player, enemy, "blood loss")
		return
	
	# Determine initiative if not held from previous round
	if initiative_holder == null:
		determine_initiative()
	
	round_started.emit(current_round)
	
	stats.total_rounds += 1
	
	# Start first exchange
	start_exchange()

## Start a new exchange within the round
func start_exchange():
	current_exchange += 1
	
	print("\n--- Exchange %d ---" % current_exchange)
	
	exchange_started.emit(current_exchange, initiative_holder)
	
	var attacker = initiative_holder
	var defender = get_opponent(attacker)
	
	# Check if player input is needed
	if not auto_simulate:
		if attacker == player:
			# Player is attacking
			awaiting_player_input = true
			player_action_requested.emit(player, true)
			return  # Wait for player input
		elif defender == player:
			# Player is defending  
			awaiting_player_input = true
			player_action_requested.emit(player, false)
			return  # Wait for player input
	
	# If we get here, it's AI vs AI or auto_simulate is on
	if auto_simulate and ai_controller:
		_auto_execute_exchange()

## Auto-execute exchange using AI (for testing/simulation)
func _auto_execute_exchange():
	var attacker = initiative_holder
	var defender = get_opponent(attacker)
	
	# Get AI decisions
	var attack_action = ai_controller.decide_action(attacker, defender, true)
	var defense_action = ai_controller.decide_action(defender, attacker, false)
	
	# Execute
	execute_exchange(
		attacker,
		defender,
		attack_action.attack,
		defense_action.defense
	)

## MODIFY: execute_exchange to add pauses
## Execute an attack/defense exchange
func execute_exchange(
	attacker: CharacterData,
	defender: CharacterData,
	attack: AttackManeuver,
	defense: DefenseManeuver
):
	print("\n%s attacks %s!" % [attacker.character_name, defender.character_name])
	print("Attack: %s" % attack.get_description())
	print("Defense: %s" % defense.get_description())
	
	# Allocate CP
	var attack_cost = attack.dice_allocated
	if attack.type == AttackManeuver.Type.FEINT:
		attack_cost += 1 + attack.feint_dice_added
	if attack.bonus_die_spent:
		attack_cost += 1
	
	var defense_cost = defense.dice_allocated + defense.get_upfront_cost()
	
	if not attacker.combat_pool.allocate(attack_cost):
		print("ERROR: Attacker doesn't have enough CP!")
		return
	
	if not defender.combat_pool.allocate(defense_cost):
		print("ERROR: Defender doesn't have enough CP!")
		return
	
	# NEW: Pause to show allocations
	await _pause_for_action()
	
	# Resolve the attack
	var result = resolver.resolve_attack(
		attack, defense,
		attacker.equipment.get_weapon_atn(attack.type),
		defender.equipment.get_weapon_parry_tn(),
		defender.equipment.get_shield_block_tn()
	)
	
	# Handle fumble penalty
	if result.attacker_fumbled and result.attacker_dice_lost > 0:
		attacker.combat_pool.apply_shock(result.attacker_dice_lost)
	
	# Emit result immediately so UI can show it
	attack_resolved.emit(result, attacker, defender)
	
	# NEW: Pause to let player see the result
	await _pause_for_action()
	
	# Calculate damage if hit
	if result.hit:
		resolver.calculate_damage_for_result(
			result, attack,
			attacker.attributes.brawn,
			attacker.equipment.weapon.brawn_modifier,
			defender.attributes.brawn,
			defender.equipment.get_total_protection(attack.target_zone)
		)
		
		# Apply wound
		if result.damage_wound:
			apply_wound(defender, result.damage_wound)
			
			# NEW: Extra pause after wounds
			await _pause_for_action()
	
	# Handle initiative changes
	if result.initiative_stolen:
		initiative_holder = defender
		print("\n%s stole initiative!" % defender.character_name)
	else:
		initiative_holder = attacker
	
	# Handle special effects
	if result.attacker_dice_lost > 0:
		print("%s loses %d dice!" % [attacker.character_name, result.attacker_dice_lost])
	
	if result.combat_disengaged:
		print("Combat disengaged! New initiative next round.")
		initiative_holder = null
	
	# Track statistics
	stats.total_exchanges += 1
	if result.hit:
		if attacker == player:
			stats.player_hits += 1
			if result.damage_wound:
				stats.player_damage_dealt += result.damage_wound.level
				stats.enemy_wounds_received += 1
		else:
			stats.enemy_hits += 1
			if result.damage_wound:
				stats.enemy_damage_dealt += result.damage_wound.level
				stats.player_wounds_received += 1
	else:
		if attacker == player:
			stats.player_misses += 1
		else:
			stats.enemy_misses += 1
	
	# Check if defender can continue
	if not defender.can_act():
		var cause = "fatal wound" if defender.is_dead else "unconscious"
		end_combat(attacker, defender, cause)
		return
	
	# Continue to next exchange or next round
	if current_exchange < 2:
		start_exchange()
	else:
		end_round()

## Apply a wound to a character
func apply_wound(character: CharacterData, wound: WoundData):
	character.injury_manager.add_wound(
		wound,
		character.attributes,
		character.combat_pool
	)
	
	# Check for knockdown
	if wound.effects.knockdown_tn > 0:
		var knocked_down = character.injury_manager.check_knockdown(
			character.attributes,
			wound.effects.knockdown_tn
		)
		if knocked_down:
			character.is_prone = true
			# Reduce CP to 1/3 when prone
			character.combat_pool.max_pool = character.combat_pool.max_pool / 3
			character.combat_pool.current_pool = min(
				character.combat_pool.current_pool,
				character.combat_pool.max_pool
			)
	
	# Check for knockout
	if wound.effects.knockout_tn > 0:
		var knocked_out = character.injury_manager.check_knockout(
			character.attributes,
			wound.effects.knockout_tn
		)
		if knocked_out:
			character.is_unconscious = true
	
	# Check for instant death
	if wound.effects.instant_death:
		character.is_dead = true

## Check blood loss for a character
func check_blood_loss(character: CharacterData):
	var survived = character.injury_manager.check_blood_loss(character.attributes)
	
	if not survived:
		character.is_dead = true

## End the current round
func end_round():
	print("\n--- Round %d Complete ---" % current_round)
	print("PLAYER: CP %d/%d, Brawn %d, %d wounds" % [
		player.combat_pool.current_pool,
		player.combat_pool.max_pool,
		player.attributes.brawn,
		player.injury_manager.wounds.size()
	])
	print("ENEMY: CP %d/%d, Brawn %d, %d wounds" % [
		enemy.combat_pool.current_pool,
		enemy.combat_pool.max_pool,
		enemy.attributes.brawn,
		enemy.injury_manager.wounds.size()
	])
	
	round_ended.emit(current_round)
	
	# Check if combat should continue
	if not combat_active:
		return
	
	# Schedule next round (properly handles async)
	_schedule_next_round()

## Schedule the next round (handles pause correctly)
func _schedule_next_round():
	if enable_round_pause:
		# Create timer and connect to its timeout
		var timer = get_tree().create_timer(round_pause_duration)
		timer.timeout.connect(_on_pause_complete)
	else:
		# No pause, continue immediately
		_on_pause_complete()

## Called when pause is complete (or immediately if no pause)
func _on_pause_complete():
	if combat_active:
		start_new_round()

## End combat with winner/loser
func end_combat(winner: CharacterData, loser: CharacterData, cause: String):
	combat_active = false
	
	print("\n" + "=".repeat(70))
	print("COMBAT ENDED!")
	print("=".repeat(70))
	print("\nWINNER: %s" % winner.character_name)
	print("LOSER: %s (died from %s)" % [loser.character_name, cause])
	print("\nFinal Stats:")
	print("\n" + winner.get_summary())
	print("\n" + loser.get_summary())
	print("=".repeat(70) + "\n")
	
	combat_ended.emit(winner, loser)
	
	print("\n" + stats.get_summary())

## Determine initial initiative (simple: higher Coordination goes first)
func determine_initiative():
	if player.attributes.coordination > enemy.attributes.coordination:
		initiative_holder = player
		print("Player has initiative (Coordination %d > %d)" % [
			player.attributes.coordination,
			enemy.attributes.coordination
		])
	elif enemy.attributes.coordination > player.attributes.coordination:
		initiative_holder = enemy
		print("Enemy has initiative (Coordination %d > %d)" % [
			enemy.attributes.coordination,
			player.attributes.coordination
		])
	else:
		# Tie: coin flip
		initiative_holder = player if randf() > 0.5 else enemy
		print("%s wins initiative (tied Coordination, coin flip)" % initiative_holder.character_name)

## Get the opponent of a given character
func get_opponent(character: CharacterData) -> CharacterData:
	return enemy if character == player else player

## Check if combat is still active
func is_combat_active() -> bool:
	return combat_active
	
## NEW: Function to receive player's action
func receive_player_action(attack: AttackManeuver, defense: DefenseManeuver):
	if not awaiting_player_input:
		print("ERROR: Not waiting for player input!")
		return
	
	awaiting_player_input = false
	
	# Store player's choices
	player_attack = attack
	player_defense = defense
	
	# Now get AI's action and execute
	var attacker = initiative_holder
	var defender = get_opponent(attacker)
	
	var final_attack: AttackManeuver
	var final_defense: DefenseManeuver
	
	if attacker == player:
		# Player is attacking, AI defends
		final_attack = player_attack
		var ai_action = ai_controller.decide_action(defender, attacker, false)
		final_defense = ai_action.defense
	else:
		# AI is attacking, player defends
		var ai_action = ai_controller.decide_action(attacker, defender, true)
		final_attack = ai_action.attack
		final_defense = player_defense
	
	# Execute the exchange
	execute_exchange(attacker, defender, final_attack, final_defense)

## Combat statistics (for post-combat display)
class CombatStats:
	var total_rounds: int = 0
	var total_exchanges: int = 0
	var player_hits: int = 0
	var player_misses: int = 0
	var enemy_hits: int = 0
	var enemy_misses: int = 0
	var player_damage_dealt: int = 0
	var enemy_damage_dealt: int = 0
	var player_wounds_received: int = 0
	var enemy_wounds_received: int = 0
	
	func get_summary() -> String:
		var text = "COMBAT STATISTICS\n"
		text += "=".repeat(50) + "\n"
		text += "Rounds: %d | Exchanges: %d\n" % [total_rounds, total_exchanges]
		text += "\nPLAYER:\n"
		text += "  Hits: %d | Misses: %d | Hit Rate: %.1f%%\n" % [
			player_hits,
			player_misses,
			(float(player_hits) / float(player_hits + player_misses) * 100.0) if (player_hits + player_misses) > 0 else 0.0
		]
		text += "  Damage Dealt: %d | Wounds Given: %d\n" % [
			player_damage_dealt,
			enemy_wounds_received
		]
		text += "\nENEMY:\n"
		text += "  Hits: %d | Misses: %d | Hit Rate: %.1f%%\n" % [
			enemy_hits,
			enemy_misses,
			(float(enemy_hits) / float(enemy_hits + enemy_misses) * 100.0) if (enemy_hits + enemy_misses) > 0 else 0.0
		]
		text += "  Damage Dealt: %d | Wounds Given: %d\n" % [
			enemy_damage_dealt,
			player_wounds_received
		]
		return text

var stats: CombatStats = CombatStats.new()
