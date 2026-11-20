# hypear

**An unofficial fan-made minigame inspired by Umamusume.**

**This project is a personal fan-created contents.**

*English is not my first language so there may be some mistakes. Suggestions or corrections are always welcome. Thank you for your understanding!*

## Project layout

Start with [the game loop](game/game_loop.tscn) to follow a playthrough from the title screen to the stage and back.

| To work on | Start here |
| --- | --- |
| Title screen and license viewer | [game/title/](game/title/) |
| Stage layout, difficulty settings and scoring | [game/stage/](game/stage/) |
| Sorting and shipping | [Cargo items](game/stage/cargo_item/), [boxes](game/stage/boxes/), [character](game/stage/character/), [conveyors](game/stage/conveyors/), [weighing scale](game/stage/weighing_scale/) |
| In-game counters and score displays | [game/stage/hud/](game/stage/hud/) |
| Loading and result shutters | [game/shutters/](game/shutters/) |
| Theme and floor tile shared by multiple screens | [game/shared/](game/shared/) |
| Reusable Godot utilities | [utils/](utils/) |
| Stage tests and scoring simulator | [Test instructions](tests/README.md), [simulator](docs/hypear-score-simulator-simple.html) |

## Setup

The font used by this game is not included in this repository.

### Font

This game uses **DotGothic16**.
Get the font from [Google Fonts](https://fonts.google.com/specimen/DotGothic16) and place the font file at `third_party/fonts/DotGothic16-Regular.ttf`.

## License
The files in this repository are licensed under different terms depending on the directory.

### Most of files
Released under the MIT License.

### `umamusume/` directory
All files under the `umamusume/` directory are **NOT covered by the MIT License**.

Those files are distributed separately under the terms described in `UMAMUSUME_ASSETS_LICENSE.md`.

Please see `UMAMUSUME_ASSETS_LICENSE.md` for details.

### Third-party assets

- Stage input guide icons under the `third_party/freegameui.net/` directory are from [Free Game UI Assets](https://freegameui.net/), released under [CC0 1.0 Universal](https://freegameui.net/license/).
