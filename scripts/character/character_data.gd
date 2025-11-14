# res://scripts/character/character_data.gd
class_name CharacterData
extends Resource

# Complete character definition with attributes, equipment, and combat state

@export var character_name: String = "Warrior"
@export var attributes: CharacterAttributes
@export var equipment: Equipment
@export var proficiencies: Dictionary = {}  # WeaponData.WeaponType: proficiency_level

## Combat state (initialized when combat starts)
var combat_pool: CombatPool = null
var injury_manager: InjuryManager = null
var is_dead: bool = false
var is_unconscious: bool = false
var is_prone: bool = false

## Initialize for combat (call this when battle starts)
func initialize_for_combat():
	# Create combat pool
	combat_pool = CombatPool.new()
	
	# Calculate base CP
	var proficiency = 0
	if equipment and equipment.weapon:
		proficiency = proficiencies.get(equipment.weapon.weapon_type, 0)
	
	var base_cp = attributes.coordination + proficiency
	var cp_penalty = equipment.get_total_cp_penalty() if equipment else 0
	
	combat_pool.initialize(base_cp - cp_penalty)
	
	# Create injury manager
	injury_manager = InjuryManager.new()
	
	# Reset state
	is_dead = false
	is_unconscious = false
	is_prone = false
	
	print("%s initialized for combat: CP %d" % [character_name, combat_pool.max_pool])

## Check if character can still fight
func can_act() -> bool:
	return not is_dead and not is_unconscious and attributes.brawn > 0

## Get summary string
func get_summary() -> String:
	var text = "%s\n" % character_name
	text += "  %s\n" % attributes.attr_tostring()
	if equipment:
		text += "  %s\n" % equipment.equip_tostring()
	if combat_pool:
		text += "  CP: %d/%d\n" % [combat_pool.current_pool, combat_pool.max_pool]
	if injury_manager and not injury_manager.wounds.is_empty():
		text += "  Wounds:\n"
		for wound in injury_manager.wounds:
			text += "    - %s\n" % wound.get_summary()
	return text
