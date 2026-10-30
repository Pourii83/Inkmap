# Inkmap

A Leatrix Maps style world map addon for **OctoWoW**, which runs on the Turtle WoW 1.17.2 client (a 1.12 / vanilla client, Interface 11200).

## Features

- **Windowed map**: the world map is a movable window instead of fullscreen, so you can keep moving and fighting with it open. It has a dark frame with a silver border; grab the border to move the window and the coordinates in a strip below the map. The map's buttons and dropdowns (including ones other addons add, such as pfQuest's quest filter) are hidden: left click a zone to open it, right click to zoom out, and press ESC or the map key to close. This can be turned off in the options. Turtle WoW's own minimize/maximize map mode is replaced.
- **Zoom**: the mouse wheel over the map zooms in and out at the cursor (up to 4x). While zoomed in, drag with the left mouse button to pan. The zoom resets when the map shows another zone.
- **Resize and opacity**: drag the silver bottom right corner to resize the map window (it keeps its shape). Ctrl + mouse wheel also resizes it. Shift + mouse wheel changes its opacity. The position is saved.
- **Fade**: the map turns half transparent when the mouse leaves it, so you can see your character behind it, and more transparent while you move. It becomes solid again when the mouse is over it.
- **Unexplored areas**: shows the parts of the map you have not explored yet, with an optional tint. This includes Turtle zones such as Gilneas, Hyjal, Tel'Abim and Thalassian Highlands.
- **Coordinates**: cursor coordinates on the left and player coordinates on the right, in the strip below the map.
- **Zone level ranges**: shows the level range next to a zone's name when you hover it, colored by difficulty for your level.
- **Class colored group icons**: party and raid members show on the world map and the battlefield minimap as small circles in their class color.
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
- با چرخ موس روی همان نقطه‌ای که موس هست زوم کنید. وقتی زوم کرده‌اید، با کشیدن موس نقشه را جابه‌جا کنید.
- قاب نقشه تیره است با حاشیه‌ی نقره‌ای؛ برای جابه‌جا کردن پنجره حاشیه را بگیرید و بکشید. مختصات در نوار پایین نقشه است. دکمه‌ها و منوهای روی نقشه مخفی هستند: برای رفتن به یک منطقه روی آن کلیک چپ کنید، برای برگشت کلیک راست کنید، و با ESC یا کلید M نقشه را ببندید.
- با کشیدن گوشه‌ی نقره‌ای پایین راست پنجره، اندازه‌ی نقشه را تغییر دهید. Ctrl و چرخ موس هم اندازه را عوض می‌کند. با Shift و چرخ موس شفافیتش عوض می‌شود.
- وقتی موس از روی نقشه کنار برود نقشه نیمه‌شفاف می‌شود تا کاراکتر پشتش دیده شود، و موقع حرکت شفاف‌تر.
- مناطقی که هنوز کشف نکرده‌اید روی نقشه نشان داده می‌شوند.
- مختصات نشانگر موس سمت چپ و مختصات بازیکن سمت راست نوار پایین نقشه نمایش داده می‌شود.
- وقتی موس را روی یک منطقه می‌برید، محدوده‌ی لول آن منطقه نشان داده می‌شود.
- هم‌گروهی‌های پارتی و رید روی نقشه به شکل دایره‌ی کوچک با رنگ کلاسشان نمایش داده می‌شوند.
- یک دکمه کنار مینی‌مپ هست.

**تنظیمات:** دستور `/inkmap` را بزنید یا روی دکمه‌ی کنار مینی‌مپ راست‌کلیک کنید.
