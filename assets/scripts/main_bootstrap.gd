extends RefCounted

## Startup orchestration for the main scene.
## The scene controller owns state and callbacks; this object owns startup order.

const INGREDIENT_CATALOG = preload("res://assets/scripts/ingredient_catalog.gd")

static func run(host) -> void:
	host.manager_registry = load("res://assets/scripts/manager_registry.gd").new()
	host.manager_registry.name = "ManagerRegistry"
	host.add_child(host.manager_registry)
	host.manager_registry.setup(host, INGREDIENT_CATALOG.ALL, host.OPENING_HOUR, host.CUSTOMER_EXIT_POSITION)
	for ingredient in INGREDIENT_CATALOG.ALL:
		host.stock[str(ingredient[0])] = 10
	host._load_game()
	if not host.tutorial_seen and host.broth_stock_packs <= 0:
		host.broth_stock_packs = 1
	host._load_stage_layout()
	host._build_world()
	host._apply_store_structure()
	host._apply_upgrade_effects()
	host._build_ui()
	host._build_tutorial_quest_ui()
	if not host.tutorial_seen:
		host._start_tutorial_quests()
	host.ui_manager.show_start_menu()
