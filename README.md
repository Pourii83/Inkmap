# Inkmap

A Leatrix Maps style world map addon for **OctoWoW**, which runs on the Turtle WoW 1.17.2 client (a 1.12 / vanilla client, Interface 11200).

## Features

- **Windowed map**: the world map is a movable window instead of fullscreen, so you can keep moving and fighting with it open. Turtle WoW's own minimize/maximize map mode is replaced.
- **Zoom**: the mouse wheel over the map zooms in and out around the cursor (up to 4x), and the +/- buttons do the same. While zoomed in, drag with the left mouse button to pan. The zoom resets when the map shows another zone.
- **Scale and opacity**: Ctrl + mouse wheel scales the map. Shift + mouse wheel changes its opacity. The position is saved.
- **Fade while moving**: the map turns transparent while you move and becomes solid again when the mouse is over it.
- **Unexplored areas**: shows the parts of the map you have not explored yet, with an optional tint. This includes Turtle zones such as Gilneas, Hyjal, Tel'Abim and Thalassian Highlands.
- **Coordinates**: shows player and cursor coordinates at the bottom of the map.
- **Zone level ranges**: shows the level range next to a zone's name when you hover it, colored by difficulty for your level.
- **Follow zone changes**: an open map switches to the new zone when you enter it.
- **Minimap button**: left click toggles the map, right click opens the options, drag to move the button.

## Install

**Launcher:** add the addon from its GitHub link, `https://github.com/Pourii83/Inkmap`.

**Manual:**
1. Download the repository as a ZIP and extract it.
2. Rename the extracted folder to exactly `Inkmap`, so you have `Interface\AddOns\Inkmap\Inkmap.toc`.
3. Move it into `<OctoWoW folder>\Interface\AddOns\`.
4. Restart the game and enable Inkmap on the AddOns screen at character select.

## Commands

| Command | What it does |
| --- | --- |
| `/inkmap` or `/ink` | Open the options window |
| `/inkmap reset` | Reset map position, scale and opacity |
| `/inkmap lock` | Lock or unlock the map position |
| `/inkmap data auto\|turtle\|vanilla` | Choose the unexplored area data set (default `auto` detects the client) |

## Notes

- Switching the windowed map off needs a `/reload`.
- If Cartographer, MetaMap or pfUI's world map module is loaded, Inkmap leaves the map window and unexplored areas to that addon.
- Level ranges for custom Turtle/OctoWoW zones can be added in `Data/ZoneLevels.lua`.

## Credits

The unexplored area data and the drawing approach come from [pfUI](https://github.com/shagu/pfUI) by Shagu (MIT License).

---

## راهنمای فارسی

Inkmap یک ادان نقشه شبیه Leatrix Maps برای سرور **OctoWoW** است. OctoWoW روی کلاینت Turtle WoW 1.17.2 اجرا می‌شود که پایه‌اش 1.12 است.

**نصب:** از لانچر با لینک گیت‌هاب نصب کنید، یا ZIP را دانلود کنید، اسم پوشه را دقیقاً `Inkmap` بگذارید و در `Interface\AddOns` بازی کپی کنید و بازی را دوباره باز کنید.

**امکانات:**
- نقشه به شکل پنجره درمی‌آید و می‌شود آن را جابه‌جا کرد. وقتی نقشه باز است هم می‌توانید حرکت کنید.
- با چرخ موس یا دکمه‌های + و - روی نقشه زوم کنید. وقتی زوم کرده‌اید، با کشیدن موس نقشه را جابه‌جا کنید.
- با Ctrl و چرخ موس اندازه‌ی نقشه عوض می‌شود. با Shift و چرخ موس شفافیتش عوض می‌شود.
- وقتی حرکت می‌کنید نقشه کم‌رنگ می‌شود.
- مناطقی که هنوز کشف نکرده‌اید روی نقشه نشان داده می‌شوند.
- مختصات بازیکن و نشانگر موس پایین نقشه نمایش داده می‌شود.
- وقتی موس را روی یک منطقه می‌برید، محدوده‌ی لول آن منطقه نشان داده می‌شود.
- یک دکمه کنار مینی‌مپ هست.

**تنظیمات:** دستور `/inkmap` را بزنید یا روی دکمه‌ی کنار مینی‌مپ راست‌کلیک کنید.
