# res://scenes/ui/action_panel.gd
extends Control

# Player input panel for choosing combat actions

## Signals
signal action_confirmed(attack: AttackManeuver, defense: DefenseManeuver)

## References
@onready var thrust_button = $PanelContainer/MarginContainer/VBoxContainer/MainContainer/AttackSection/ThrustButton
@onready var swing_button = $PanelContainer/MarginContainer/VBoxContainer/MainContainer/AttackSection/SwingButton
@onready var feint_button = $PanelContainer/MarginContainer/VBoxContainer/MainContainer/AttackSection/FeintButton

@onready var parry_button = $PanelContainer/MarginContainer/VBoxContainer/MainContainer/DefenseSection/ParryButton
@onready var block_button = $PanelContainer/MarginContainer/VBoxContainer/MainContainer/DefenseSection/BlockButton
@onready var dodge_button = $PanelContainer/MarginContainer/VBoxContainer/MainContainer/DefenseSection/DodgeButton
@onready var counter_button = $PanelContainer/MarginContainer/VBoxContainer/MainContainer/DefenseSection/CounterButton

@onready var head_button = $PanelContainer/MarginContainer/VBoxContainer/MainContainer/InfoSection/HeadButton
@onready var torso_button = $PanelContainer/MarginContainer/VBoxContainer/MainContainer/InfoSection/TorsoButton
@onready var limbs_button = $PanelContainer/MarginContainer/VBoxContainer/MainContainer/InfoSection/LimbsButton

@onready var cp_slider = $PanelContainer/MarginContainer/VBoxContainer/MainContainer/InfoSection/CPSlider
@onready var cp_label = $PanelContainer/MarginContainer/VBoxContainer/MainContainer/InfoSection/CPLabel
@onready var probability_label = $PanelContainer/MarginContainer/VBoxContainer/MainContainer/InfoSection/ProbabilityLabel
@onready var target_label = $PanelContainer/MarginContainer/VBoxContainer/MainContainer/InfoSection/TargetLabel

@onready var confirm_button = $PanelContainer/MarginContainer/VBoxContainer/BottomRow/ConfirmButton

# NEW: Add these if you created the UI elements
@onready var cp_info_label = $PanelContainer/MarginContainer/VBoxContainer/MainContainer/InfoSection/CPInfoLabel
@onready var cp_warning_label = $PanelContainer/MarginContainer/VBoxContainer/MainContainer/InfoSection/CPWarningLabel

## State
var player_character: CharacterData
var is_attacking: bool = true  # true = choosing attack, false = choosing defense

var selected_attack_type: AttackManeuver.Type = AttackManeuver.Type.SWING
var selected_defense_type: DefenseManeuver.Type = DefenseManeuver.Type.PARRY
var selected_target_zone: TargetZone.SimpleZone = TargetZone.SimpleZone.TORSO
var selected_cp: int = 6

# NEW: Reference to title label (add this to @onready section)
@onready var title_label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel

func _ready():
	# Connect buttons
	thrust_button.pressed.connect(_on_thrust_pressed)
	swing_button.pressed.connect(_on_swing_pressed)
	feint_button.pressed.connect(_on_feint_pressed)
	
	parry_button.pressed.connect(_on_parry_pressed)
	block_button.pressed.connect(_on_block_pressed)
	dodge_button.pressed.connect(_on_dodge_pressed)
	counter_button.pressed.connect(_on_counter_pressed)
	
	head_button.pressed.connect(_on_head_pressed)
	torso_button.pressed.connect(_on_torso_pressed)
	limbs_button.pressed.connect(_on_limbs_pressed)
	
	cp_slider.value_changed.connect(_on_cp_changed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	
	# Set tooltips
	_setup_tooltips()
	
	# Start hidden
	visible = false

## NEW: Setup helpful tooltips
func _setup_tooltips():
	# Attack tooltips
	thrust_button.tooltip_text = "Fast attack: +1 die, -1 damage\nCan spend +1 die to negate penalty"
	swing_button.tooltip_text = "Standard attack\nCan spend +1 die for +1 damage"
	feint_button.tooltip_text = "Deceptive attack: Change target after defense\nRequires Proficiency 4+"
	
	# Defense tooltips
	parry_button.tooltip_text = "Deflect with weapon\nDTN based on weapon quality"
	block_button.tooltip_text = "Use shield to block\nRequires shield equipped"
	dodge_button.tooltip_text = "Evade attack (DTN 7)\nCan steal initiative for 2 CP"
	counter_button.tooltip_text = "Risky counter-attack\nCosts 2 CP upfront, huge reward if successful"
	
	# Target tooltips
	head_button.tooltip_text = "Most lethal, but well-defended"
	torso_button.tooltip_text = "Balanced risk/reward"
	limbs_button.tooltip_text = "Crippling wounds, less lethal"

## Show panel for player to choose action
func show_for_action(character: CharacterData, attacking: bool):
	print("🎯 ACTION PANEL: show_for_action called")
	print("  - Character: %s" % character.character_name)
	print("  - Attacking: %s" % attacking)
	
	player_character = character
	is_attacking = attacking
	
	# Update title based on action type
	if title_label:
		if attacking:
			title_label.text = "⚔️ YOUR ATTACK"
			title_label.modulate = Color.ORANGE_RED
		else:
			title_label.text = "🛡️ YOUR DEFENSE"
			title_label.modulate = Color.STEEL_BLUE
	
	# Update CP slider range
	var available_cp = character.combat_pool.get_remaining()
	cp_slider.max_value = available_cp
	
	# Smart default: Use 60% of available CP
	var suggested_cp = max(1, int(available_cp * 0.6))
	selected_cp = min(suggested_cp, available_cp)
	cp_slider.value = selected_cp
	
	# Update UI
	_update_display()
	
	# Force layout update (fixes visibility issues)
	queue_redraw()
	
	# CRITICAL FIX: Use visible = true instead of show()
	# This forces immediate visibility instead of queuing it
	visible = true
	
	# Force position update on next frame
	await get_tree().process_frame
	
	print("  - Panel visible: %s" % visible)
	print("  - Panel rect: %s" % get_global_rect())
	
	# Ensure it's on top
	move_to_front()

## Hide panel
func hide_panel():
	print("🔒 ACTION PANEL: Hiding panel")
	visible = false

## Update all UI elements
func _update_display():
	# Update CP label
	cp_label.text = "Allocate CP: %d" % selected_cp
	
	# Update target label
	target_label.text = "Target: %s" % TargetZone.get_zone_name(selected_target_zone)
	
	# Update CP info (if nodes exist)
	if cp_info_label and player_character:
		var available = player_character.combat_pool.get_remaining()
		var after = available - selected_cp
		cp_info_label.text = "Available: %d | After this: %d" % [available, after]
		
		# Show warning if spending too much
		if cp_warning_label:
			if after < 2:
				cp_warning_label.text = "⚠️ Save some CP for next exchange!"
				cp_warning_label.modulate = Color.ORANGE
				cp_warning_label.visible = true
			else:
				cp_warning_label.visible = false
	
	# Update probability (if attacking)
	if is_attacking and player_character:
		var weapon_atn = player_character.equipment.get_weapon_atn(selected_attack_type)
		var hit_chance = DiceSystem.calculate_success_probability(selected_cp, weapon_atn)
		probability_label.text = "Hit Chance: %.0f%%" % (hit_chance * 100)
	else:
		probability_label.text = ""
	
	# Highlight selected buttons
	_update_button_states()
	
	# Disable unavailable options
	_update_button_availability()

## Update button visual states
func _update_button_states():
	# Attack buttons
	thrust_button.button_pressed = (selected_attack_type == AttackManeuver.Type.THRUST)
	swing_button.button_pressed = (selected_attack_type == AttackManeuver.Type.SWING)
	feint_button.button_pressed = (selected_attack_type == AttackManeuver.Type.FEINT)
	
	# Defense buttons
	parry_button.button_pressed = (selected_defense_type == DefenseManeuver.Type.PARRY)
	block_button.button_pressed = (selected_defense_type == DefenseManeuver.Type.BLOCK)
	dodge_button.button_pressed = (selected_defense_type == DefenseManeuver.Type.DODGE_STAND)
	counter_button.button_pressed = (selected_defense_type == DefenseManeuver.Type.COUNTER)
	
	# Target buttons
	head_button.button_pressed = (selected_target_zone == TargetZone.SimpleZone.HEAD)
	torso_button.button_pressed = (selected_target_zone == TargetZone.SimpleZone.TORSO)
	limbs_button.button_pressed = (selected_target_zone == TargetZone.SimpleZone.LIMBS)

## Disable buttons player can't use
func _update_button_availability():
	if not player_character:
		return
	
	var available_cp = player_character.combat_pool.get_remaining()
	var has_shield = player_character.equipment.has_shield()
	var proficiency = player_character.proficiencies.get(
		player_character.equipment.weapon.weapon_type, 0
	)
	
	# Feint requires proficiency 4+
	feint_button.disabled = (proficiency < 4)
	
	# Block requires shield
	block_button.disabled = not has_shield
	
	# Counter requires 3+ CP (2 upfront + 1 to roll)
	counter_button.disabled = (available_cp < 3)

## Button callbacks
func _on_thrust_pressed():
	selected_attack_type = AttackManeuver.Type.THRUST
	_update_display()

func _on_swing_pressed():
	selected_attack_type = AttackManeuver.Type.SWING
	_update_display()

func _on_feint_pressed():
	selected_attack_type = AttackManeuver.Type.FEINT
	_update_display()

func _on_parry_pressed():
	selected_defense_type = DefenseManeuver.Type.PARRY
	_update_display()

func _on_block_pressed():
	selected_defense_type = DefenseManeuver.Type.BLOCK
	_update_display()

func _on_dodge_pressed():
	selected_defense_type = DefenseManeuver.Type.DODGE_STAND
	_update_display()

func _on_counter_pressed():
	selected_defense_type = DefenseManeuver.Type.COUNTER
	_update_display()

func _on_head_pressed():
	selected_target_zone = TargetZone.SimpleZone.HEAD
	_update_display()

func _on_torso_pressed():
	selected_target_zone = TargetZone.SimpleZone.TORSO
	_update_display()

func _on_limbs_pressed():
	selected_target_zone = TargetZone.SimpleZone.LIMBS
	_update_display()

func _on_cp_changed(value: float):
	selected_cp = int(value)
	_update_display()

func _on_confirm_pressed():
	# Create maneuvers from selections
	var attack = AttackManeuver.new()
	attack.type = selected_attack_type
	attack.target_zone = selected_target_zone
	attack.dice_allocated = selected_cp
	
	var defense = DefenseManeuver.new()
	defense.type = selected_defense_type
	defense.dice_allocated = selected_cp
	
	# Hide panel BEFORE emitting signal
	# This prevents race condition with next exchange
	hide_panel()
	
	# Emit signal AFTER hiding
	action_confirmed.emit(attack, defense)
