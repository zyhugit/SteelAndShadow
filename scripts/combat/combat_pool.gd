# res://scripts/combat/combat_pool.gd
class_name CombatPool
extends Node

# The Combat Pool (CP) represents action points available for combat
# Players allocate these dice between attacks and defenses
# CP = Coordination + Weapon Proficiency - Equipment Penalties

## Pool values
var max_pool: int = 0      # Maximum CP (refreshes each round)
var current_pool: int = 0  # Currently available CP this round

## Tracking
var allocated_this_exchange: int = 0
var total_allocated_this_round: int = 0

## Signals (for UI to react to changes)
signal pool_changed(current: int, maximum: int)
signal dice_allocated(amount: int)
signal pool_refreshed()

## Initialize the combat pool
## Called at start of combat
func initialize(base_pool: int):
	max_pool = base_pool
	refresh()
	print("Combat Pool initialized: %d dice" % max_pool)

## Refresh the pool (happens at start of each round)
func refresh():
	current_pool = max_pool
	total_allocated_this_round = 0
	allocated_this_exchange = 0
	pool_refreshed.emit()
	pool_changed.emit(current_pool, max_pool)
	print("Combat Pool refreshed: %d/%d" % [current_pool, max_pool])

## Allocate dice for an action (attack or defense)
## Returns true if successful, false if not enough dice
func allocate(amount: int) -> bool:
	if amount > current_pool:
		print("Cannot allocate %d dice - only %d available!" % [amount, current_pool])
		return false
	
	if amount < 0:
		print("Cannot allocate negative dice!")
		return false
	
	current_pool -= amount
	allocated_this_exchange = amount
	total_allocated_this_round += amount
	
	dice_allocated.emit(amount)
	pool_changed.emit(current_pool, max_pool)
	
	print("Allocated %d dice, %d remaining" % [amount, current_pool])
	return true

## Get remaining dice
func get_remaining() -> int:
	return current_pool

## Apply shock (immediate CP loss from wounds)
## Shock only lasts this round
func apply_shock(shock_amount: int):
	current_pool = max(0, current_pool - shock_amount)
	pool_changed.emit(current_pool, max_pool)
	print("Shock applied: -%d CP (now %d/%d)" % [shock_amount, current_pool, max_pool])

## Apply pain penalty (persistent CP loss until wound heals)
## This reduces the MAXIMUM pool
func apply_pain_penalty(pain_amount: int):
	max_pool = max(1, max_pool - pain_amount)
	current_pool = min(current_pool, max_pool)
	pool_changed.emit(current_pool, max_pool)
	print("Pain penalty applied: Max CP now %d (was %d)" % [max_pool, max_pool + pain_amount])

## Remove pain penalty (when wound heals)
func remove_pain_penalty(pain_amount: int):
	max_pool += pain_amount
	pool_changed.emit(current_pool, max_pool)
	print("Pain penalty removed: Max CP now %d" % max_pool)

## Get statistics (for debugging/UI)
func get_stats() -> Dictionary:
	return {
		"max": max_pool,
		"current": current_pool,
		"allocated_this_exchange": allocated_this_exchange,
		"allocated_this_round": total_allocated_this_round,
		"percentage_remaining": float(current_pool) / float(max_pool) * 100.0
	}
