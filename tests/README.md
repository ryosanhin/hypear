# テスト

リポジトリのルートで実行する。

```sh
godot --headless --path . --editor --import --quit
for test_script in tests/*/*_test.gd; do
    godot --headless --fixed-fps 60 --path . --script "$test_script" || exit 1
done
godot --headless --fixed-fps 60 --path . --quit-after 120
```

- `tests/<対象>/<対象>_test.gd`: 独立して実行できるテスト。
- `tests/<対象>/fixtures/`: そのテストだけが使用する設定や補助スクリプト。
- `tests/supports/test_helper.gd`: 共通アサーションと結果集計。失敗時は終了コード1。

```sh
godot --headless --path . --script tests/game_session/game_session_test.gd
godot --headless --path . --script tests/shipping_conveyor/shipping_conveyor_test.gd
godot --headless --fixed-fps 60 --path . --script tests/game_scene/game_scene_test.gd
```

`discrete_stepper` は更新境界、複数回更新、端数とリセットを検証する。
`game_session` は供給順序と入口の詰まり、供給頻度・速度、果実と二回の出荷の
起点差（0.00秒・0.23秒・0.37秒）、周期途中の即時入力、終了と再開始を検証する。
`shipping_conveyor` は同時出荷、既存出荷からの独立、下向き移動からパスへの
残り時間の引き継ぎ、周期の連続性、設定間隔を変えた搬送距離と後始末を検証する。
これらは実時間を待たず、直接 `advance(delta)` に経過時間を渡す。

`game_scene` は実際のエンジン更新を30フレームずつ使い、`Engine.time_scale`
が1と2のときの経過時間・供給・果実と箱の距離を比較する。
`--fixed-fps 60` は実時間を待たずにフレームのdeltaを固定するための実行オプション。
`stage` は実ステージの到着表示、左右の仕分けと終端での箱の解放を検証する。
その他のテストは生成、FIFO、間隔・容量、箱の状態、ポーズと得点計算を確認する。

ヘッドレス実行では、描画の見た目や操作感を目視確認しない。
[周期の所有者と開始・終了](../game/README.md)も参照。
