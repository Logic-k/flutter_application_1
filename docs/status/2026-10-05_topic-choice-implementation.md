# 2026-10-05 Topic Choice Implementation

## Scope

- First implementation slice after the dementia-center evidence report.
- Added one self-authored participation-only activity: `topic_choice` / "함께 고르는 한 주제".
- Added non-diagnostic attempt metadata:
  - `completion_status`
  - `assistance_level`
  - `session_context`
  - `content_version`
  - `response_code`
- Preserved existing training score, XP, unlock, history, and local SQLite behavior.

## User Flow

1. Open training hub.
2. Start "함께 고르는 한 주제".
3. Choose one topic: `meal`, `season`, or `hobby`.
4. Read the short reflection prompt.
5. Choose assistance level: `independent`, `verbal_prompt`, or `hands_on_help`.
6. Tap the completion button.

The activity records only participation metadata. It does not collect or store free conversation text.

## Guardrails

- No protected cognitive test items, norms, cutoffs, or scoring algorithms were added.
- The new activity is participation-only and does not write a legacy cognitive score.
- The UI describes the activity as a choice/help record, not as a diagnosis, prevention claim, or center assignment.
- `TrainingCompletionService` currently writes only `completed` attempts. `stopped` and `technical_issue` are reserved schema values and are rejected by the completion path until a separate non-XP capture UI exists.
- No Firebase, patient data, external contacts, paid services, deployment, commit, or push were performed.

## Files Changed

- `lib/core/database_helper.dart`
- `lib/core/router.dart`
- `lib/features/training/application/training_attempt_input.dart`
- `lib/features/training/application/training_completion_service.dart`
- `lib/features/training/application/training_completion_ui.dart`
- `lib/features/training/data/sqlite_training_progress_repository.dart`
- `lib/features/training/data/training_progress_repository.dart`
- `lib/features/training/domain/training_catalog.dart`
- `lib/features/training/topic_choice_page.dart`
- `lib/features/training/training_hub_page.dart`
- `test/documentation_consistency_test.dart`
- `test/unit/core/database_v9_migration_test.dart`
- `test/unit/training/training_catalog_test.dart`
- `test/unit/training/training_completion_service_test.dart`
- `test/widget/core/router_contract_test.dart`
- `test/widget/training/topic_choice_page_test.dart`
- `test/widget/training/training_hub_screen_test.dart`

## Verification

- Focused topic-choice and migration tests: passed.
- `flutter analyze`: passed, no issues found.
- Full `flutter test --machine`: passed.
  - Log: `docs/status/2026-10-05_topic-choice-full-test.machine.jsonl`
  - Summary: `docs/status/2026-10-05_topic-choice-full-test-summary.txt`
  - Result markers: `success=true`, failure results `0`, skipped results `2`.
- Debug APK build: passed.
  - APK: `build/app/outputs/flutter-apk/app-debug.apk`
  - Size: `181,812,296` bytes
  - SHA256: `5CE0F1CD1C6C15EA406682CA07D49ADF8A6DB867EC44A63C3DB2A7A1EAF0DC79`

Tool note: `dart`/`flutter` wrapper commands needed a workspace-local `APPDATA`; formatting, tests, analysis, and build required read access to the Flutter/Pub/Gradle caches.
