# Malatang Business Diary

A first-person restaurant management simulation made with Godot 4.

You run a Korean-style malatang shop: prepare ingredients, cook orders, serve customers, manage stock, and expand the store.

## Features

- First-person kitchen and restaurant gameplay
- Ingredient selection and malatang cooking flow
- Delivery orders and customer service
- Dine-in customer flow for later shop stages
- Inventory, supplies, upgrades, and daily sales management
- Korean malatang shop interior and dining area
- Monitor UI with order management, purchasing, upgrades, and store management
- Start screen with automatic save loading

## Requirements

- Godot 4.7 or later
- Godot Compatibility renderer

## Run locally

1. Clone this repository.
2. Open the project in Godot.
3. Run `Malatang.tscn` or press `F6` from the main scene.

The configured project entry point is `Malatang.tscn`.

## Controls

| Key | Action |
| --- | --- |
| `WASD` | Move |
| Mouse | Look around |
| `E` | Interact |
| `ESC` | Close the monitor or menu |

## Project structure

- `Malatang.tscn` — main game scene
- `assets/scripts/main.gd` — game coordinator
- `assets/scripts/*_manager.gd` — feature-specific managers
- `assets/layouts/` — store layouts for each stage
- `assets/models/` — 3D models and textures

## Status

This project is actively being developed. UI, cooking, customer, and store layout systems are still being refined.

## License

This repository is for the project owner's game development work. Asset licenses and attribution requirements may vary by asset.
