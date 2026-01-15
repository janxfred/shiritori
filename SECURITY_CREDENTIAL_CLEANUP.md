# 機密情報（API キー）漏洩時の対応メモ

## 1) まずやること（最優先）

- 既に公開されたキーは **漏洩したものとして扱う**（第三者にコピーされ得る）
- 可能なら **GCP 側でキーを無効化/削除** し、新しいキーにローテーションする（手順は後述）

## 2) リポジトリ（HEAD）からの除去

このリポジトリでは `google-services.json` をコミット禁止にしています。

- `.gitignore` で `**/google-services.json` を無視
- `mobile-client/android/app/google-services.json.example` を追加
- 誤コミット検知:
  - ローカル: `.githooks/pre-commit`
  - CI: `.github/workflows/secret-scan.yml`（`scripts/secret-scan.sh`）

## 3) Git 履歴からの除去（重要）

GitHub 上で既に公開されているコミットに機密が入っている場合、HEAD から消しても **履歴には残り続けます**。
公開物としてのリスクを下げるには、履歴を書き換えて当該ファイルを消します。

注意:

- 履歴書き換えは破壊的です。**共同開発者は rebase / 再 clone が必要**になります。
- 実行前にバックアップ推奨（例: `git clone --mirror`）。

### 手順（git-filter-repo 推奨）

インストール（macOS）:

```bash
brew install git-filter-repo
```

履歴からファイルを削除:

```bash
cd shiritori

git filter-repo \
  --path mobile-client/android/app/google-services.json \
  --invert-paths
```

強制 push（例。ブランチ名は状況に合わせて変更）:

```bash
# 例: ver2 ブランチを上書き
git push --force origin ver2

# タグも必要なら
git push --force --tags origin
```

共同開発者向け案内（例）:

```bash
# 一番安全: 再 clone
# もしくは
git fetch --all
# 各自の作業状況に応じて reset/rebase
```

## 4) 追加の確認

- GitHub の公開 URL や Issue/PR コメント等にキー文字列が貼られていないか
- CI ログにキーが出力されていないか
- GCP の請求/クォータの異常がないか
