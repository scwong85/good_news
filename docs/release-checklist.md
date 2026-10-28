# Release checklist (Phase 8)

Nothing here is signed off yet. The cloud session has no Android SDK, so no item that needs a device or emulator has been done.

## Blockers the owner must supply
- [ ] Contact/takedown email. Build with `--dart-define=CONTACT_EMAIL=you@example.org`; the contact tile and the policy's contact line stay empty without it. Do not publish with the placeholder.
- [ ] Application id (currently `com.example.good_news`) and final app name.
- [ ] Public privacy-policy URL hosting `docs/legal/privacy-policy.md` (Play Store requires one).
- [ ] Per-source terms/licensing review of the 10 allowlisted feeds (see `source-allowlist.csv`); replace the Squirrel News feed (404) or drop it.
- [ ] Human review of the draft labels (`data/seed_labels.jsonl`), because the published accuracy figures rest on Claude-drafted labels.
- [ ] Phase 7 (UI overhaul) brand assets, if the release should include them.

## Automated (run before every release)
- [ ] `cd app && flutter analyze && flutter test`
- [ ] `scripts/sync-rules.sh --check`, `scripts/sync-legal.sh --check`
- [ ] Classifier parity: `rules/golden_cases.jsonl` passes in Dart and Python
- [ ] `app/test/policy_test.dart`: INTERNET only, no services/receivers, backup off, no analytics/ads/background packages

## Build and signing
- [ ] Create an upload keystore outside the repo; add `android/key.properties` (git-ignored) with `storeFile`, `storePassword`, `keyAlias`, `keyPassword`, and a `signingConfigs.release` in `android/app/build.gradle` that reads it (see `deployment.md`).
- [ ] `flutter build appbundle --release --dart-define=CONTACT_EMAIL=...`
- [ ] Confirm the release manifest has only the INTERNET permission (`aapt dump permissions` or the Play Console report).

## Manual QA on a real device (phone and, if possible, tablet)
- [ ] Clean install: first launch fetches, Today shows 5 stories; each "Read at <source>" opens the publisher's page.
- [ ] Airplane mode: cached Today still shows, with a clear offline note; Explore/Saved work.
- [ ] Change stories per day (5 to 10 and back); picks stay stable and do not repeat tomorrow.
- [ ] Hide a story (each reason): it disappears and the slot is refilled; Undo works; Hidden stories lists it and Show again restores it.
- [ ] Save/share a story; saved stories open offline.
- [ ] Disable a source in Settings; its stories disappear.
- [ ] Dark mode, font size 200%, TalkBack: reading order and labels make sense; nothing is clipped.
- [ ] Rotate, background/foreground, kill and reopen.
- [ ] Privacy policy screen reads correctly; contact tile opens a mail app with the right address.
- [ ] Clear storage / uninstall removes all data.
- [ ] Cold start to cached Today under 1 s; no jank; battery and data use look reasonable after a day of normal use.

## Store
- [ ] Listing text, screenshots and graphics (`store-listing.md`).
- [ ] Data-safety form: no data collected, no data shared; no ads; no accounts.
- [ ] Content rating questionnaire; target audience adults/general.
- [ ] Internal test track first, then closed/open testing.

## After release
- [ ] Smoke test on a clean device from the store build.
- [ ] Watch for publisher or reader takedown requests and respond per `editorial-policy.md`.
