import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notenest/main.dart';
import 'package:notenest/note.dart';
import 'package:notenest/notes_store.dart';

class MemoryPreferences implements SharedPreferencesAsync {
  final Map<String, String> values = {};
  String? get value => values['notenest.v1'];
  set value(String? data) {
    if (data == null) {
      values.remove('notenest.v1');
    } else {
      values['notenest.v1'] = data;
    }
  }

  @override
  Future<String?> getString(String key) async => value;
  @override
  Future<void> setString(String key, String value) async {
    this.value = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<NotesStore> setup() async {
  final store = NotesStore(preferences: MemoryPreferences());
  await store.load();
  return store;
}

void main() {
  test('create edit pin delete restore and theme survive reload', () async {
    final store = await setup();
    final note = Note(
      id: 'fixture',
      title: 'Revision',
      body: 'Study Flutter',
      category: 'Study',
      updated: DateTime(2026, 11, 8),
    );
    store.upsert(note);
    store.pin(note);
    store.toggleTheme();
    await store.save();
    final loaded = NotesStore(preferences: store.preferences);
    await loaded.load();
    expect(loaded.dark, true);
    expect(loaded.notes.singleWhere((n) => n.id == 'fixture').pinned, true);
    loaded.upsert(
      Note(
        id: note.id,
        title: 'Updated',
        body: note.body,
        category: note.category,
        updated: DateTime(2026, 11, 9),
        pinned: true,
      ),
    );
    expect(loaded.notes.length, 4);
    loaded.remove(note.id);
    expect(loaded.notes.length, 3);
    loaded.upsert(note);
    await loaded.save();
    final restored = NotesStore(preferences: loaded.preferences);
    await restored.load();
    expect(
      restored.notes.singleWhere((n) => n.id == note.id).title,
      'Revision',
    );
  });
  test(
    'invalid saved data is preserved without replacing it with sample notes',
    () async {
      final prefs = MemoryPreferences()..value = '{broken';
      final store = NotesStore(preferences: prefs);
      await store.load();
      expect(store.error, isNotNull);
      expect(prefs.value, '{broken');
    },
  );
  for (final size in [const Size(1280, 900), const Size(390, 844)]) {
    for (final dark in [false, true]) {
      testWidgets('forms navigation search pin and Undo at $size dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await (FontLoader(
          'Manrope',
        )..addFont(rootBundle.load('assets/fonts/Manrope.ttf'))).load();
        final store = await setup();
        store.dark = dark;
        await tester.pumpWidget(NoteNestApp(store: store));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('new-note')));
        await tester.pumpAndSettle();
        final save = find.byKey(const ValueKey('save-note'));
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(store.notes.length, 3);
        expect(find.text('Please enter some text'), findsNWidgets(2));
        final title = find.byKey(const ValueKey('note-title'));
        final body = find.byKey(const ValueKey('note-body'));
        await tester.ensureVisible(title);
        await tester.enterText(title, 'Exam revision');
        await tester.ensureVisible(body);
        await tester.enterText(body, 'Remember to explain navigation.');
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        final note = store.notes.singleWhere((n) => n.title == 'Exam revision');
        final card = find.byKey(ValueKey('note-${note.id}'));
        await tester.ensureVisible(card);
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(find.text(note.body), findsOneWidget);
        await tester.tap(find.byTooltip('Edit note'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('note-title')),
          'Updated revision',
        );
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(find.text('Updated revision'), findsOneWidget);
        await tester.tap(find.byTooltip('Pin note'));
        await tester.pumpAndSettle();
        expect(store.notes.singleWhere((n) => n.id == note.id).pinned, true);
        await tester.tap(find.byTooltip('Delete note'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
        expect(store.notes.any((n) => n.id == note.id), false);
        await tester.tap(find.text('Undo'));
        await tester.pumpAndSettle();
        expect(
          store.notes.singleWhere((n) => n.id == note.id).title,
          'Updated revision',
        );
        final search = find.byKey(const ValueKey('search'));
        await tester.ensureVisible(search);
        await tester.enterText(search, 'no such note');
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('empty')), findsOneWidget);
        await tester.enterText(search, 'Updated revision');
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('note-${note.id}')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
