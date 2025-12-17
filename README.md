# Pawnshop Market System

A dynamic pawn shop market system for FiveM with real supply & demand pricing.

This script automatically determines what items players can sell based on their inventory, learns prices over time, and maintains persistent stock per pawn shop.

Supports both **ESX** and **QB** frameworks.

---

## Features

- Dynamic sell & buy-back pricing
- Market prices react to supply and demand
- Per-shop stock stored in SQL
- Sell and buy items in custom quantities
- Confirmation dialogs for transactions
- Price history per item
- Interactive market price graph (NUI)
- NPC dialogue reacts to market conditions
- Smart junk filtering (price + time based)
- No item config lists required

---

## Supported Frameworks

- ox_inventory / ox_target / ox_lib
- qb-inventory / qb-target / qb-menu
- Auto-detection built in

---

## Requirements

- oxmysql
- ox_lib (recommended)
- ox_inventory or qb-inventory
- ox_target or qb-target

---

## Installation

1. Place the resource in your `resources` folder
2. Import the SQL tables
3. Ensure the resource in your server config

```cfg
ensure oxmysql
ensure ox_lib
ensure pawnshop_market

