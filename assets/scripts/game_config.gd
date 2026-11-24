extends RefCounted

## Central configuration for values that are tuned during development.
## Keep scene/controller code focused on behavior, not balancing constants.

const SAVE_PATH := "user://malatang_save.json"
const STAGE1_WALL_TILES_PATH := "res://assets/textures/malatang_wall_tile.png"
const STAGE1_FLOOR_TILES_PATH := "res://assets/textures/malatang_floor_tile.png"
const STAGE1_WALL_PLASTER_PATH := "res://assets/textures/stage1_wall_plaster.png"
const STAGE1_STAINLESS_PATH := "res://assets/textures/stage1_stainless.png"
const UNIFIED_LAYOUT_PATH := "res://assets/layouts/store_stage_1.tscn"
const STAGE3_LAYOUT_PATH := "res://assets/layouts/store_stage_3.tscn"

const COURIER_ENTRANCE := Vector3(6.1, 0.0, 9.2)
const COURIER_WAITING := Vector3(6.55, 0.0, -2.6)
const COURIER_QUEUE_POSITIONS := [Vector3(6.1, 0.0, 9.2), Vector3(6.1, 0.0, 10.0)]
const CUSTOMER_PAYMENT_POSITION := Vector3(6.55, 0.9, -5.15)
const CUSTOMER_EXIT_POSITION := Vector3(7.2, 0.9, 5.8)
const GAS_STOVE_POSITION := Vector3(0.0, 1.10, -7.5)
const COOKING_POT_POSITION := Vector3(1.2, 1.55, -7.5)
const BROTH_POT_POSITION := Vector3(-1.25, 1.82, -7.5)

const WRONG_TABLE_PENALTY := 500
const OPENING_HOUR := 10
const CLOSING_HOUR := 22
const GAME_MINUTES_PER_REAL_MINUTE := 10.0
