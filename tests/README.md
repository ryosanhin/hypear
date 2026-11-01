# Tests

Run the following commands from the repository root:

```sh
godot --headless --path . --editor --import --quit
for test_script in tests/*/*_test.gd; do
    godot --headless --path . --script "$test_script" || exit 1
done
godot --headless --path . --quit-after 120
```

## Structure and coverage

- `tests/<target>/<target>_test.gd`: independently runnable headless test suites.
- `tests/<target>/fixtures/`: settings and scripts used only by that suite.
- `tests/supports/test_helper.gd`: shared assertions and result reporting.

Each suite uses `tests/supports/test_helper.gd` and exits with code 1 on failure.
To run one suite, for example:
`godot --headless --path . --script tests/game_session/game_session_test.gd`.

Run the current stage's arrival display, sorting poses and shipping transport
integration test with:
`godot --headless --path . --script tests/stage/stage_test.gd`.

Fixture resources are duplicated for each test so configuration changes do not
leak into other tests. Conveyor and box suites instantiate their real scenes.
Session tests connect fresh conveyor and box instances without the HUD. Tests
cover generation, FIFO, path movement, arrival restrictions, spacing, capacity,
blocked entrances, box display, shipping, scoring, state restrictions, timer reset
and retry. A game scene integration test checks InputMap bindings and the full
start-to-retry connection flow.

Headless tests do not verify rendered appearance. See [the playable demo README](../scenes/game/README.md) for visual verification and demo details.
