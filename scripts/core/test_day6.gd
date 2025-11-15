# res://scripts/core/test_day6.gd
extends Node

var combat_manager: CombatManager
var ai: AIController

func _ready():
	print("\n" + "=".repeat(70))
	print("DAY 6: FULL COMBAT MANAGER TEST")
	print("=".repeat(70) + "\n")
	
	# Create systems
	combat_manager = CombatManager.new()
	add_child(combat_manager)
	
	ai = AIController.new()
	add_child(ai)
	
	# Configure combat manager
	combat_manager.set_ai_controller(ai)
	combat_manager.auto_simulate = true  # Let it run automatically
	combat_manager.enable_round_pause = true  # Enable pause (test the fix!)
	combat_manager.round_pause_duration = 0.5
	
	# Connect signals to see what's happening
	combat_manager.combat_started.connect(_on_combat_started)
	combat_manager.round_started.connect(_on_round_started)
	combat_manager.exchange_started.connect(_on_exchange_started)
	combat_manager.combat_ended.connect(_on_combat_ended)
	
	# Create fighters
	var warrior = create_warrior()
	var bandit = create_bandit()
	
	# Start combat! (It will run itself)
	combat_manager.start_combat(warrior, bandit)

# Remove the old simulate_combat function entirely!

func _on_combat_started(player: CharacterData, enemy: CharacterData):
	print("⚔️ Combat started between %s and %s!" % [player.character_name, enemy.character_name])

func _on_round_started(round_number: int):
	print("🔄 Round %d begins!" % round_number)

func _on_exchange_started(exchange_number: int, attacker: CharacterData):
	print("👊 Exchange %d: %s has initiative" % [exchange_number, attacker.character_name])

func _on_combat_ended(winner: CharacterData, loser: CharacterData):
	print("🏆 %s is victorious!" % winner.character_name)
	print("💀 %s has fallen!" % loser.character_name)

# Keep create_warrior() and create_bandit() functions as they were
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
