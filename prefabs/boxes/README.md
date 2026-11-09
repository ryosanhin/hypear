# 箱の表示

`GameSession` が左右の `BoxState` を生成し、
`BoxesViewController.create_boxes(left_state, right_state)` へ直接渡します。
投入・出荷判断・採点・次の状態への交換は `GameSession` が担当します。

`BoxesViewController` は箱のプレハブ、表示先、左右の生成・出荷マーカー、
`ShippingConveyor` と現在の左右の `BoxView` を参照します。
投入待ちの状態と表示の対応を保持し、状態ごとの出荷通知を一度だけ受けます。

| タイミング | 箱の親 | 処理 |
|---|---|---|
| 投入待ち・投入中 | `Stage/BoxesViewRoot` | Controllerが生成・配置し、BoxViewが重量通知で表示を更新 |
| 出荷開始 | `Stage/BoxesEntryViewRoot` | Controllerが重量接続を解除し、親変更後に `BoxView.ship_to()` を呼ぶ |
| ベルト到着 | `ShippingConveyor/Path2D/PathFollow2D` | Controllerが到着を通知した箱自身を `ShippingConveyor.accept_box()` へ渡す |
| 経路終端 | — | ShippingConveyorが追従ノードと箱を解放 |

`BoxesEntryViewRoot` はStage直下にあり、`ShippingConveyor` より前に並びます。
`ShippingConveyor` の子は `TileMapLayer`、`Path2D` の順です。
描画順の見え方は実際のステージで確認します。
各表示先では新しい箱（経路上では追従ノード）を兄弟の先頭へ追加するため、
先に追加した箱が手前になります。親変更ではグローバル変換を保持します。

`BoxView` は重量表示、蓋を閉じる演出、指定されたグローバル座標への移動、
自身を含む到着通知だけを担当し、出荷シグナルやコンベアを直接参照しません。
出荷中の箱は次の左右の箱を生成しても残り、到着通知から同じインスタンスを搬送へ渡します。
出荷前の箱を交換する場合は、古い状態との接続と表示を解除します。

## 検証

箱表示の演出と描画順はデバッグプレイで確認します。
採点とゲーム進行のCLIテストは [テスト手順](../../tests/README.md) を参照してください。

画面では左右に果実を入れて下キーで出荷し、移動開始から箱が出荷ベルトの手前に
表示されること、蓋が閉じてベルトへ移ること、続けて出荷しても各箱が残ることを確認します。
