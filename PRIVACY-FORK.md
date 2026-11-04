# scp-forks/yaak: privacy branch

`main` is an untouched mirror of [mountain-loop/yaak](https://github.com/mountain-loop/yaak).
`privacy` is `main` + the changes below. Build and run from `privacy`.

See exactly what differs at any time: `git diff main privacy`

## What is changed

| Upstream behaviour                                                                    | How it is removed                                                                               |
| ------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| App auto-updater (`update.yaak.app`)                                                  | Built without the `updater` feature (`tauri.privacy.conf.json`)                                 |
| License check (`license.yaak.app`)                                                    | Built without the `license` feature                                                             |
| Notification check (`notify.yaak.app`; sends launch count, install date, version, OS) | `PRIVACY_ALLOW_PHONE_HOME = false` guard in `crates-tauri/yaak-app-client/src/notifications.rs` |
| Background plugin update check (`api.yaak.app`)                                       | Same guard in `crates-tauri/yaak-app-client/src/plugins_ext.rs`                                 |
| CLI update check (`update.yaak.app`)                                                  | Same guard in `crates-cli/yaak-cli/src/version_check.rs`                                        |

Still present, but only when _you_ click them: plugin search/install, feedback form,
import from URL, `yaak://` deep links.

All code edits are marked `[privacy]`: `git grep -n '\[privacy\]'`

## Getting upstream updates

1. On GitHub, open `scp-forks/yaak`, branch `main`, click **Sync fork → Update branch**.
   (`main` has no local commits, so this never conflicts.)
2. Merge it into `privacy`, either on GitHub (pull request `main` → `privacy`, Merge) or locally:
   ```sh
   git switch privacy
   git pull                       # get the merged privacy branch, or:
   git fetch origin && git merge origin/main
   git push
   ```
   If there is a conflict it will be in one of the small `[privacy]` guards: keep the guard.
3. Re-check for new phone-home code (anything new here needs a guard):
   ```sh
   git grep -nE 'https://[a-z]+\.yaak\.app' -- '*.rs' '*.json' ':!*.md'
   ```
4. Rebuild and install (quit Yaak first):
   ```sh
   scripts/privacy-build.sh --install
   ```

## Building

`scripts/privacy-build.sh [--install]`. Needs Node 24 (via nvm, `.node-version`), Rust,
and `wasm-bindgen-cli` matching the repo's `wasm-bindgen` version
(`cargo install wasm-bindgen-cli --version <x> --locked`, run from outside the repo).

The app is ad-hoc signed. After each rebuild macOS may ask once more whether Yaak may use
its Keychain item: choose **Always Allow**.

## Where data lives

- App data (requests, environments, encrypted secrets): `~/Library/Application Support/app.yaak.desktop`,
  symlinked to `/Users/shaun/data/Apps/Yaak`.
- Encryption master key: macOS Keychain, item `app.yaak.desktop.EncryptionKey`.
  Secrets in the data folder cannot be decrypted without it.
