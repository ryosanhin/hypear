# hypear

**An unofficial fan-made minigame inspired by Umamusume.**

**This project is a personal fan-created contents.**

*English is not my first language so there may be some mistakes. Suggestions or corrections are always welcome. Thank you for your understanding!*

## Playable demo

Open `project.godot` in Godot 4 and run the project (F6 runs the current scene;
F5 runs the game). The demo uses the included animated conveyor tiles, pear and
cardboard scenes, and the character in `character/character.tscn`. It does not require external assets.
The original project's Godot 4.7 feature declaration is preserved; this demo was
validated with Godot 4.6.1 using the compatibility renderer.

| Input | Action |
| --- | --- |
| Enter / Space or START button | Start or retry |
| Left / Right | Put the arrived fruit in the left / right box |
| Down | Ship both boxes |
| D or Show weights checkbox | Toggle all fruit weight numbers |

Fruit weights are 2, 3, 5, 7 and 10, with equal probabilities by default.
Pear sprites use `pear/pear.tscn` at its original size for weight 5; each sprite
scales by the cube root of `weight / 5.0` around its foot, while weight labels keep
a fixed font size. This treats weight as proportional to volume for fruit of the
same shape and density.
A fruit arrives every 1.5 seconds. The queue holds 10 fruit; the next supply while
full ends the game. The count includes all fruit currently on the conveyor.
Fruit follows the belt from the top entrance through the bends to the sorting
station above the worker. Only the oldest fruit that has reached the station can
be sorted; each following fruit then advances, maintaining a 56-pixel path gap.
If the entrance is still occupied when another fruit is supplied, the game also
ends instead of creating overlapping fruit. With the default settings, the first
fruit takes about 4.4 seconds to reach the station after appearing.
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

- `game/`: fruit data, generation, box state, scoring and the `GameSession` coordinator.
- `backgrounds/conveyor.tscn`: floor, animated belt, editable path and conveyor component.
- `scenes/game/`: main scene, component connections, input and HUD.
- `character/`: character presentation, held fruit and sorting poses.
- `views/`: fruit presentation and the box component.
- `tests/<target>/<target>_test.gd`: independently runnable headless test suites.
- `tests/<target>/fixtures/`: settings and scripts used only by that suite.
- `tests/supports/test_helper.gd`: shared assertions and result reporting.

The conveyor owns fruit order, PathFollow2D nodes, movement, stopping and arrival
checks. Its `add_fruit()`, `peek_ready_fruit()`, `take_ready_fruit()` and `clear()`
methods are the interface used by the rest of the game. It has no automatic
process: `GameSession` advances it up to each supply time, so long frames preserve
both supply timing and movement. Fruit paths do not loop or rotate the visuals.

Each box owns its `BoxState` and updates its label when fruit is added or cleared.
`GameSession` is a Node connected to the conveyor and two boxes in the Inspector.
It controls start/retry, supply, sorting, shipping, score and game over; it does
not keep a second fruit queue. Input and HUD connections belong to `game.gd`.

To adjust the route, open `backgrounds/conveyor.tscn` and edit the Curve2D on
`FruitPath`. The first point is the entrance and the last is the sorting station.
The initial route approximates the bends with radius-48 quarter circles; refine
it visually in the editor as needed. `fruit_spacing` belongs to the conveyor.
If the endpoint changes, also move the worker, boxes and HUD in the game scene.
Check spacing, travel time, capacity and supply interval together when tuning.

The fruit and box views instance `pear/pear.tscn` and `cardboard/cardboard.tscn`.
To change their art, edit those scenes, retaining the fruit
`configure()` method and box `configure()`, `add_fruit()` and `clear()` methods.
The game displays the arrived fruit under `Body/HoldPoint`, between the body and
front hands, and hides its conveyor visual until it is sorted. Fruit size and
weight display remain consistent with the conveyor. On a successful sort, the
character shows the selected side pose for `pose_duration` seconds (default 0.2),
then returns to the front pose. Set `left_pose_texture` and `right_pose_texture`
on `character.tscn` independently; a missing side uses the other texture flipped
horizontally. If both are empty, the front pose is retained. The included scene
sets only the left texture.

The HUD and overlays are editable nodes in `scenes/game/game.tscn`. Scoring can be
changed in `game/score_calculator.gd` without modifying the components.

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
leak into other tests. Conveyor and box suites instantiate their real scenes.
Session tests connect fresh conveyor and box instances without the HUD. Tests
cover generation, FIFO, path movement, arrival restrictions, spacing, capacity,
blocked entrances, box display, shipping, scoring, state restrictions, timer reset
and retry. A game scene integration test checks InputMap bindings and the full
start-to-retry connection flow.

For visual verification, run the game with a GUI and check the route against the
belt centers, fruit overlap at bends, animation direction, HUD placement and
sorting feel. Headless tests do not verify rendered appearance.

This is a fixed-layout 960 x 720 demo with 4:3 letterboxing. Text is currently
English. It has no audio, character abilities,
stages, saves, rankings or difficulty progression.

## License
The files in this repository are licensed under different terms depending on the directory.

### Most of files
Released under the MIT License.

### `umamusume/` directory
All files under the `umamusume/` directory are **NOT covered by the MIT License**.

Those files are distributed separately under the terms described in `UMAMUSUME_ASSETS_LICENSE.md`.

Please see `UMAMUSUME_ASSETS_LICENSE.md` for details.
