# res://scripts/core/character_attributes.gd
class_name CharacterAttributes
extends Resource

# This defines a character's physical and mental capabilities
# Attributes range from 2 (weak) to 7 (exceptional), average is 4

## Temporal Attributes (Physical)
@export var agility: int = 4  # Speed, balance, dodging
@export var brawn: int = 4    # Strength, toughness, damage

## Mental Attributes  
@export var wits: int = 4     # Intelligence, perception
@export var presence: int = 4 # Willpower, intimidation

## Derived Attributes (calculated automatically)
var coordination: int:
	get:
		return (agility + wits) / 2  # How well you react under pressure

var resistance: int:
	get:
		return (brawn + presence) / 2  # How hard you are to knock down

var movement: int:
	get:
		return agility + (brawn / 2)  # How fast you move (not used in demo)

## Validate that attributes are in valid range (2-7)
func validate() -> bool:
	return agility >= 2 and agility <= 7 \
		and brawn >= 2 and brawn <= 7 \
		and wits >= 2 and wits <= 7 \
		and presence >= 2 and presence <= 7

## Get a readable string of all attributes (for debugging)
func attr_tostring() -> String:
	return "AGL:%d BRN:%d WTS:%d PRS:%d | CRD:%d RES:%d MOV:%d" % [
		agility, brawn, wits, presence,
		coordination, resistance, movement
	]
