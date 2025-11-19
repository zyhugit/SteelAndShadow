# res://scenes/combat/combat_scene.gd
extends Node2D

# Main combat scene that displays the battle

## References to UI elements
@onready var round_label = $UI/HUD/TopPanel/InfoContainer/RoundLabel
@onready var log_text = $UI/HUD/LogPanel/LogScroll/LogText
@onready var action_panel = $UI/ActionPanel  # NEW!

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

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):  # Press Space
		print("\n=== UI DEBUG INFO ===")
		print("ActionPanel exists: %s" % (action_panel != null))
		if action_panel:
			print("ActionPanel visible: %s" % action_panel.visible)
			print("ActionPanel position: %s" % action_panel.position)
			print("ActionPanel global_position: %s" % action_panel.global_position)
			print("ActionPanel size: %s" % action_panel.size)
			print("ActionPanel rect: %s" % action_panel.get_global_rect())
			print("ActionPanel z_index: %s" % action_panel.z_index)
			print("ActionPanel modulate: %s" % action_panel.modulate)
			
			# Check if it's on screen
			var screen_rect = get_viewport_rect()
			var panel_rect = action_panel.get_global_rect()
			var on_screen = screen_rect.intersects(panel_rect)
			print("On screen: %s" % on_screen)
			
			# Check parent visibility
			var parent = action_panel.get_parent()
			print("Parent visible: %s" % parent.visible if parent else "No parent")
		print("===================\n")

func test_combat():
	# Create combat systems
	combat_manager = CombatManager.new()
	add_child(combat_manager)
	
	ai_controller = AIController.new()
	add_child(ai_controller)
	
	# Configure combat manager
	combat_manager.set_ai_controller(ai_controller)
	combat_manager.auto_simulate = false
	combat_manager.enable_round_pause = true
	combat_manager.round_pause_duration = 1.0
	combat_manager.enable_action_pause = true  # NEW
	combat_manager.action_pause_duration = 0.8  # NEW - adjust to taste
	
	# Connect signals
	combat_manager.combat_started.connect(_on_combat_started)
	combat_manager.round_started.connect(_on_round_started)
	combat_manager.exchange_started.connect(_on_exchange_started)
	combat_manager.attack_resolved.connect(_on_attack_resolved)
	combat_manager.combat_ended.connect(_on_combat_ended)
	combat_manager.player_action_requested.connect(_on_player_action_requested)  # NEW!
	
	# Connect action panel
	action_panel.action_confirmed.connect(_on_action_confirmed)  # NEW!
	
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

## MODIFY: _on_attack_resolved to use new logging
func _on_attack_resolved(result: CombatResult, attacker: CharacterData, defender: CharacterData):
	# Log the attack details
	log_attack(
		attacker.character_name,
		defender.character_name,
		"Using %d dice" % result.attack_dice_used
	)
	
	log_defense(
		defender.character_name,
		"Using %d dice" % result.defense_dice_used
	)
	
	# Log result
	if result.hit:
		var wound_level = result.damage_wound.level if result.damage_wound else 0
		log_hit(attacker.character_name, wound_level)
		
		# Log wound details
		if result.damage_wound:
			log_wound_effects(result.damage_wound)
	else:
		log_miss(attacker.character_name)
	
	# Log special effects
	if result.initiative_stolen:
		log_special_effect("Initiative Stolen", "%s takes control!" % defender.character_name)
	
	if result.attacker_dice_lost > 0:
		log_special_effect("Dice Lost", "%s loses %d dice" % [attacker.character_name, result.attacker_dice_lost])
	
	if result.combat_disengaged:
		log_special_effect("Disengaged", "Combat distance increased")
	
	log_separator()
	
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
	
	# Hide action panel if visible
	action_panel.hide_panel()

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
	# Add screen shake
	var camera = get_viewport().get_camera_2d()
	if camera:
		var tween = create_tween()
		tween.tween_property(camera, "offset", Vector2(10, 0), 0.05)
		tween.tween_property(camera, "offset", Vector2(-10, 0), 0.05)
		tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)

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
		
		# Auto-scroll to bottom
		await get_tree().process_frame
		var scroll = log_text.get_parent() as ScrollContainer
		if scroll:
			scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func log_separator():
	log_text.append_text("[color=gray]" + "─".repeat(50) + "[/color]\n")

func log_attack(attacker_name: String, defender_name: String, attack_desc: String):
	log_message("⚔️ %s attacks %s" % [attacker_name, defender_name], "yellow")
	log_message("   %s" % attack_desc, "white")

func log_defense(defender_name: String, defense_desc: String):
	log_message("🛡️ %s defends" % defender_name, "cyan")
	log_message("   %s" % defense_desc, "white")

func log_hit(attacker_name: String, damage_level: int):
	var severity_color = "orange"
	var severity_icon = "💥"
	
	if damage_level >= 4:
		severity_color = "red"
		severity_icon = "☠️"
	elif damage_level >= 2:
		severity_color = "orange"
		severity_icon = "💢"
	else:
		severity_color = "yellow"
		severity_icon = "✓"
	
	log_message("%s HIT! (Level %d wound)" % [severity_icon, damage_level], severity_color)

func log_miss(attacker_name: String):
	log_message("○ Miss - attack deflected", "gray")

func log_wound_effects(wound: WoundData):
	if not wound or not wound.effects:
		return
	
	var effects = wound.effects
	log_message("   💔 %s" % effects.description, "red")
	
	if effects.shock > 0:
		log_message("   ⚡ Shock: -%d CP this round" % effects.shock, "orange")
	
	if effects.pain > 0:
		log_message("   😣 Pain: -%d CP persistent" % effects.pain, "orange")
	
	if effects.blood_loss > 0:
		log_message("   🩸 Blood Loss TN: %d" % effects.blood_loss, "red")
	
	if effects.knockdown_tn > 0:
		log_message("   ⬇️ Knockdown check required!", "yellow")
	
	if effects.knockout_tn > 0:
		log_message("   😵 Knockout check required!", "red")

func log_special_effect(effect_name: String, description: String):
	log_message("✨ %s: %s" % [effect_name, description], "magenta")

## NEW: Highlight whose turn it is
func highlight_active_character(character: CharacterData):
	if character == player_character:
		# Player's turn - brighten player, dim enemy
		player_sprite.modulate = Color(1.2, 1.2, 1.2)  # Brighter
		enemy_sprite.modulate = Color(0.6, 0.6, 0.6)   # Dimmer
		
		# Add pulsing effect (optional)
		_pulse_sprite(player_sprite)
	else:
		# Enemy's turn - brighten enemy, dim player
		player_sprite.modulate = Color(0.6, 0.6, 0.6)
		enemy_sprite.modulate = Color(1.2, 1.2, 1.2)
		
		_pulse_sprite(enemy_sprite)

## Reset highlighting
func clear_highlights():
	player_sprite.modulate = Color.WHITE
	enemy_sprite.modulate = Color.WHITE

## Pulsing effect
func _pulse_sprite(sprite: ColorRect):
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 1.5), 0.3)
	tween.tween_property(sprite, "modulate", Color(1.2, 1.2, 1.2), 0.3)

## MODIFY: _on_player_action_requested to use highlighting
func _on_player_action_requested(character: CharacterData, is_attacking: bool):
	var action_type = "attack" if is_attacking else "defend"
	log_message("Your turn to %s!" % action_type, "cyan")
	
	# Highlight player
	highlight_active_character(character)
	
	action_panel.show_for_action(character, is_attacking)

## MODIFY: _on_action_confirmed to clear highlighting
func _on_action_confirmed(attack: AttackManeuver, defense: DefenseManeuver):
	log_message("Action confirmed!", "green")
	
	# Clear highlights
	clear_highlights()
	
	# Tell combat manager to continue with player's choice
	combat_manager.receive_player_action(attack, defense)
