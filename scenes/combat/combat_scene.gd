# res://scenes/combat/combat_scene.gd
extends Node2D

# Main combat scene that displays the battle

## References to UI elements
@onready var round_label = $UI/HUD/TopPanel/InfoContainer/RoundLabel
@onready var log_text = $UI/HUD/LogPanel/LogScroll/LogText
@onready var player_sprite = $Fighters/PlayerPosition/Sprite
@onready var player_name_label = $Fighters/PlayerPosition/Sprite/NameLabel
@onready var player_health_bar = $Fighters/PlayerPosition/StatsUI/StatsPanel/HealthBar
@onready var player_cp_label = $Fighters/PlayerPosition/StatsUI/StatsPanel/CPLabel
@onready var player_wound_label = $Fighters/PlayerPosition/StatsUI/StatsPanel/WoundLabel

@onready var enemy_sprite = $Fighters/EnemyPosition/Sprite
@onready var enemy_name_label = $Fighters/EnemyPosition/Sprite/NameLabel
@onready var enemy_health_bar = $Fighters/EnemyPosition/StatsUI/StatsPanel/HealthBar
@onready var enemy_cp_label = $Fighters/EnemyPosition/StatsUI/StatsPanel/CPLabel
@onready var enemy_wound_label = $Fighters/EnemyPosition/StatsUI/StatsPanel/WoundLabel

## Combat system
var combat_manager: CombatManager
var ai_controller: AIController

## Character data
var player_character: CharacterData
var enemy_character: CharacterData

func _ready():
	print("Combat scene ready!")
	
	# For testing, create a quick combat
	test_combat()

func test_combat():
	# Create combat systems
	combat_manager = CombatManager.new()
	add_child(combat_manager)
	
	ai_controller = AIController.new()
	add_child(ai_controller)
	
	# Configure combat manager
	combat_manager.set_ai_controller(ai_controller)
	combat_manager.auto_simulate = true
	combat_manager.enable_round_pause = true
	combat_manager.round_pause_duration = 1.0  # Slower so we can see updates
	
	# Connect signals
	combat_manager.combat_started.connect(_on_combat_started)
	combat_manager.round_started.connect(_on_round_started)
	combat_manager.exchange_started.connect(_on_exchange_started)
	combat_manager.attack_resolved.connect(_on_attack_resolved)
	combat_manager.combat_ended.connect(_on_combat_ended)
	
	# Create fighters
	player_character = create_warrior()
	enemy_character = create_bandit()
	
	# Start combat
	combat_manager.start_combat(player_character, enemy_character)

func _on_combat_started(player: CharacterData, enemy: CharacterData):
	print("UI: Combat started!")
	log_message("=== COMBAT BEGINS ===", "yellow")
	log_message("%s vs %s" % [player.character_name, enemy.character_name], "white")
	update_character_display(player, true)
	update_character_display(enemy, false)

func _on_round_started(round_number: int):
	round_label.text = "Round %d" % round_number
	log_message("--- Round %d Begins ---" % round_number, "cyan")
	update_character_display(player_character, true)
	update_character_display(enemy_character, false)

func _on_exchange_started(exchange_number: int, attacker: CharacterData):
	round_label.text = "Round %d | Exchange %d" % [
		combat_manager.current_round,
		exchange_number
	]

func _on_attack_resolved(result: CombatResult, attacker: CharacterData, defender: CharacterData):
	# Log the attack
	if result.hit:
		log_message("%s hits %s! (%d damage)" % [
			attacker.character_name,
			defender.character_name,
			result.damage_wound.level if result.damage_wound else 0
		], "orange")
	else:
		log_message("%s misses %s" % [
			attacker.character_name,
			defender.character_name
		], "gray")
	
	# Update defender's display
	if defender == player_character:
		update_character_display(player_character, true)
	else:
		update_character_display(enemy_character, false)
	
	# Visual feedback
	if result.hit:
		flash_sprite(defender == player_character)

func _on_combat_ended(winner: CharacterData, loser: CharacterData):
	round_label.text = "COMBAT OVER - %s Wins!" % winner.character_name
	log_message("=== COMBAT OVER ===", "yellow")
	log_message("WINNER: %s" % winner.character_name, "green")
	log_message("LOSER: %s" % loser.character_name, "red")

func update_character_display(character: CharacterData, is_player: bool):
	if is_player:
		player_name_label.text = character.character_name
		
		# Health bar (based on Brawn)
		var max_brawn = 7  # Could be stored in character
		player_health_bar.max_value = max_brawn
		player_health_bar.value = character.attributes.brawn
		
		# CP
		if character.combat_pool:
			player_cp_label.text = "CP: %d/%d" % [
				character.combat_pool.current_pool,
				character.combat_pool.max_pool
			]
		
		# Wounds
		if character.injury_manager:
			player_wound_label.text = "Wounds: %d" % character.injury_manager.wounds.size()
	else:
		enemy_name_label.text = character.character_name
		
		var max_brawn = 7
		enemy_health_bar.max_value = max_brawn
		enemy_health_bar.value = character.attributes.brawn
		
		if character.combat_pool:
			enemy_cp_label.text = "CP: %d/%d" % [
				character.combat_pool.current_pool,
				character.combat_pool.max_pool
			]
		
		if character.injury_manager:
			enemy_wound_label.text = "Wounds: %d" % character.injury_manager.wounds.size()

func flash_sprite(is_player: bool):
	# Simple visual feedback - flash red when hit
	var sprite = player_sprite if is_player else enemy_sprite
	var original_color = sprite.color
	
	# Flash red
	sprite.color = Color.RED
	await get_tree().create_timer(0.2).timeout
	sprite.color = original_color

# Test character creation
func create_warrior() -> CharacterData:
	var char = CharacterData.new()
	char.character_name = "Ironclad Warrior"
	
	var attrs = CharacterAttributes.new()
	attrs.agility = 5
	attrs.brawn = 6
	attrs.wits = 4
	attrs.presence = 4
	char.attributes = attrs
	
	var equip = Equipment.new()
	equip.weapon = load("res://data/weapons/longsword_standard.tres")
	equip.armor = load("res://data/armor/chainmail.tres")
	equip.shield = load("res://data/shields/heater_shield.tres")
	char.equipment = equip
	
	char.proficiencies[WeaponData.WeaponType.LONGSWORD] = 5
	
	return char

func create_bandit() -> CharacterData:
	var char = CharacterData.new()
	char.character_name = "Bandit Raider"
	
	var attrs = CharacterAttributes.new()
	attrs.agility = 4
	attrs.brawn = 4
	attrs.wits = 3
	attrs.presence = 3
	char.attributes = attrs
	
	var equip = Equipment.new()
	equip.weapon = load("res://data/weapons/longsword_standard.tres")
	equip.armor = load("res://data/armor/leather_jack.tres")
	equip.shield = null
	char.equipment = equip
	
	char.proficiencies[WeaponData.WeaponType.LONGSWORD] = 3
	
	return char

func log_message(message: String, color: String = "white"):
	if log_text:
		log_text.append_text("[color=%s]%s[/color]\n" % [color, message])
