# NoteNest

A small working Flutter Notes App for the UI Flutter Lab examination.
Original suggested idea: **37 — Notes App**.

## Features

- Three screens: notes list, note detail, note editor.
- Add, read, edit and delete notes; deletion has an 8-second Undo action.
- Required title and body validation, categories, title/body search and pinning.
- Responsive one/two/three-column grid, light/dark themes, a short empty-state transition.
- Device-local JSON persistence with shared_preferences.

## Run

```sh
flutter pub get
flutter run -d chrome
```

## Checks and build

```sh
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
```

## Understand the code

- `lib/note.dart`: data model and JSON conversion.
- `lib/notes_store.dart`: ChangeNotifier, CRUD, pinning, theme and queued persistence.
- `lib/main.dart`: app, three screens, form validation and reusable UI widgets.

The UI uses StatefulWidget/setState for search, filters and the editor. Shared data is observed using ListenableBuilder. Provider is not required. Notes stay in the same browser/device; there is no backend, sign-in or cloud sync. Clear browser storage only after saving any important note elsewhere. The sample notes are created only on the first visit.

## Examination requirements

1. Widgets: Container, Row, Column, Stack, GridView, cards and buttons.
2. Responsive design: MediaQuery and LayoutBuilder.
3. Navigation: Navigator.push, MaterialPageRoute and Navigator.pop.
4. Animation: AnimatedSwitcher with a 220 ms transition between empty and populated states.
5. State: StatefulWidget, setState, ChangeNotifier and ListenableBuilder.
6. Themes and reusable widgets: ThemeData, NoteCard, CountBadge and Brand.
7. Forms: Form, GlobalKey<FormState>, TextFormField validators and category dropdown.

## Test coverage

Six tests cover create/edit/pin/delete/restore and persistence, invalid stored data preservation, plus navigation, validation, search and Undo on desktop/mobile in both themes.

## Web deployment

GitHub Pages publishes at https://abhiram54369.github.io/notenest/ after the deployment workflow succeeds. The workflow builds with `--base-href /notenest/` and runs `python3 tool/prepare_web_release.py` to version the application and assets. Local hosting of `build/web` is also possible after a release build.
