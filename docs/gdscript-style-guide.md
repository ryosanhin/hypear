# GDScriptのコーディングスタイル

GDScriptのコーディングスタイルは基本的に https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html に従う。

## メソッド定義時のドキュメントコメントについて

ドキュメントコメントは基本的に https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_documentation_comments.html に従う。

ドキュメントコメントは日本語で記載する。

ドキュメントコメントはメソッドの説明と引数の説明を記載する。

ドキュメントコメントの例を以下に示す。

```
## 与えられた値の和を二倍にして返す。[br]
## [param arg_a]: 対象の値[br]
## [param arg_b]: 対象の値
func example_method(arg_a: int, arg_b: int) -> int:
	return (arg_a + arg_b) * 2
```

## 実装の方針

過剰なテストや防護は実装しない。

まずゲームが遊べることを目標年、ゲーム内で正常に遊んだ範囲で発生しうる不具合を回避する実装を行う。
