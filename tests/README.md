# Tests

現在のステージと箱表示は、リポジトリのルートで次のコマンドを実行して検証します。

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/boxes_view_controller/boxes_view_controller_test.gd
godot --headless --path . --script tests/stage/stage_test.gd
godot --headless --path . --script tests/demo_settings/demo_settings_test.gd
godot --headless --path . --script tests/fruit_generator/fruit_generator_test.gd
godot --headless --path . --quit-after 120
```

## 構成と検証範囲

- `tests/<target>/<target>_test.gd`: 個別に実行するヘッドレステスト。
- `tests/<target>/fixtures/`: そのテストだけで使用する設定やスクリプト。
- `tests/supports/test_helper.gd`: アサーションと結果集計の共通ヘルパー。

`boxes_view_controller` は実ステージを使用し、配置先と兄弟順、親変更時の変換保持、
重量通知の切断、複数組の連続出荷、搬送・終端での解放、投入待ちの箱の交換を検証します。
`stage` は実際の入力から手元表示、左右の仕分け、出荷・搬送までの連携を検証します。
`demo_settings` と `fruit_generator` は設定と果実生成を検証します。

各テストは共通ヘルパーを使用し、アサーション失敗時に終了コード1を返します。
スクリプトの実行時エラーでもテスト関数だけが中断し、終了コード0になる場合があるため、
成功表示に加えて `SCRIPT ERROR` / `ERROR` がないことも確認してください。
ヘッドレステストは画面の見た目を検証しません。
責務と画面確認の手順は [箱の表示](../prefabs/boxes/README.md) を参照してください。

## 既存テストの未追従

`character`、`conveyor`、`fruit_box`、`game_scene`、`game_session`、
`score_calculator` は移動・削除前のシーンやAPIを参照しており、
`feat/box-effect` の変更前から実行に失敗します。これらの復旧は今回の箱表示の変更には含めません。
全テストの現状を確認する場合は、各スクリプトの終了コードとエラーログを確認してください。

```sh
for test_script in tests/*/*_test.gd; do
    godot --headless --path . --script "$test_script"
done
```
