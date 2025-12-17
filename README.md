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

1. Place the resource in your `resources` folder.
2. Import the SQL tables (see below).
3. Ensure all dependencies are started before this resource.
4. Add the following to your server.cfg:

```cfg
ensure oxmysql
ensure ox_lib
ensure pawnshop_market
```

## SQL Setup

Import the following tables into your database:

```sql
CREATE TABLE IF NOT EXISTS pawnshop_stock (
  shop_id VARCHAR(32) NOT NULL,
  item VARCHAR(64) NOT NULL,
  stock INT NOT NULL DEFAULT 0,
  PRIMARY KEY (shop_id, item)
);

CREATE TABLE IF NOT EXISTS pawnshop_history (
  id INT AUTO_INCREMENT PRIMARY KEY,
  shop_id VARCHAR(32) NOT NULL,
  item VARCHAR(64) NOT NULL,
  action VARCHAR(8) NOT NULL,
  unit_price INT NOT NULL,
  qty INT NOT NULL,
  ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Usage

- Interact with pawn shop NPCs to buy or sell items.
- Prices and stock are dynamic and update based on player activity.
- Use the market graph and price history features to make informed trades.

## Configuration

Edit `config.lua` to adjust shop locations, framework integration, pricing, and junk rules.

## Integration Notes

- Compatible with both ox and qb frameworks. Auto-detection is enabled by default.
- For custom inventory/target/menu/money systems, adjust the relevant settings in `config.lua`.

## Support

For issues or questions, open an issue on the repository or contact the author.

