# hypear

**An unofficial fan-made minigame inspired by Umamusume.**

**This project is a personal fan-created contents.**

*English is not my first language so there may be some mistakes. Suggestions or corrections are always welcome. Thank you for your understanding!*

## Playable demo

Open `project.godot` in Godot 4 and run the project (F6 runs the current scene;
F5 runs the game). The demo uses shapes only and does not require external assets.
The original project's Godot 4.7 feature declaration is preserved; this demo was
validated with Godot 4.6.1 using the compatibility renderer.

| Input | Action |
| --- | --- |
| Enter / Space or START button | Start or retry |
| Left / Right | Put the oldest fruit in the left / right box |
| Down | Ship both boxes |
| D or Show weights checkbox | Toggle all fruit weight numbers |

Fruit weights are 2, 3, 5, 7 and 10, with equal probabilities by default.
A fruit arrives every 1.5 seconds. The queue holds 10 fruit; the next supply while
full ends the game. Sorting is allowed as soon as fruit enters the queue, including
while its visual is moving. The oldest fruit moves toward the ring above the worker.
Boxes accept weights above the target of 20. Only shipped boxes earn points;
unshipped fruit does not add points at game over.

Each nonempty box earns `max(0, 100 - abs(weight - target) * 5)` points.
An empty box earns 0. Both boxes ship together, their scores are added, and both
weights reset. Shipping two empty boxes does nothing.

### Settings and structure

Edit `game/demo_settings.tres` in the Inspector to change weights, relative
probabilities (0 disables a weight), supply interval, capacity, target weight,
movement speed and initial number visibility. Weight and probability arrays must
have matching sizes, weights must be positive, and at least one probability must
be positive. Time, speed, capacity and target must also be positive.

- `game/`: display-independent fruit data, generation, boxes, scoring and session.
- `scenes/game/`: main scene, input, UI and visual queue movement.
- `views/`: independent fruit, conveyor, worker and box presentation scenes.
- `tests/<target>/<target>_test.gd`: independently runnable headless test suites.
- `tests/<target>/fixtures/`: settings and scripts used only by that suite.
- `tests/supports/test_helper.gd`: shared assertions and result reporting.

To add art, replace drawing in the `views/*_view.tscn` scenes with Sprite2D or
animated nodes, keeping the fruit `configure()` and box `update_weight()` entry
points. The conveyor view only draws the belt; fruit movement belongs to the main
scene controller. The HUD and overlays are editable nodes in `scenes/game/game.tscn`.
Scoring can be changed in `game/score_calculator.gd` without modifying the views.

### Tests

```sh
godot --headless --path . --editor --import --quit
for test_script in tests/*/*_test.gd; do
    godot --headless --path . --script "$test_script" || exit 1
done
godot --headless --path . --quit-after 120
```

Each suite uses `tests/supports/test_helper.gd` and exits with code 1 on failure.
To run one suite, for example:
`godot --headless --path . --script tests/game_session/game_session_test.gd`.
Fixture resources are duplicated for each test so configuration changes do not
leak into other tests. Tests cover generation, FIFO, sorting,
shipping, scoring, overflow, state restrictions, timer reset and retry. A scene
integration test also checks InputMap bindings and the start-to-retry flow.

This is a fixed-layout 960 x 720 demo with 4:3 letterboxing. Text is currently
English and visuals are placeholders. It has no audio, character abilities,
stages, saves, rankings or difficulty progression.

## License
The files in this repository are licensed under different terms depending on the directory.

### Most of files
Released under the MIT License.

### `umamusume/` directory
All files under the `umamusume/` directory are **NOT covered by the MIT License**.

Those files are distributed separately under the terms described in `UMAMUSUME_ASSETS_LICENSE.md`.

Please see `UMAMUSUME_ASSETS_LICENSE.md` for details.
