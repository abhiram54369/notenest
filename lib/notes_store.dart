import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'note.dart';

// One shared store keeps the list, detail page and theme in sync.
class NotesStore extends ChangeNotifier {
  final SharedPreferencesAsync preferences;
  NotesStore({SharedPreferencesAsync? preferences})
    : preferences = preferences ?? SharedPreferencesAsync();
  List<Note> notes = [];
  bool dark = false;
  String? error;
  Future<void> _writes = Future.value();

  Future<void> load() async {
    try {
      final raw = await preferences.getString('notenest.v1');
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final loaded = (data['notes'] as List)
            .map((n) => Note.fromJson(Map<String, dynamic>.from(n)))
            .toList();
        notes = loaded;
        dark = data['dark'] as bool;
      } else {
        final now = DateTime.now();
        notes = [
          Note(
            id: 'welcome',
            title: 'A little space for your big ideas',
            body: 'Welcome to NoteNest.\n\nKeep lecture notes, quick reminders and ideas together. Tap a card to read it, or start a new note. Pin the ones you want to keep close.',
            category: 'Personal',
            updated: now,
            pinned: true,
          ),
          Note(
            id: 'study',
            title: 'Flutter revision checklist',
            body: '1. Understand Row and Column.\n2. Practice Navigator.push and pop.\n3. Validate a form before saving.\n4. Explain setState and ChangeNotifier.\n5. Test the app on a small screen.',
            category: 'Study',
            updated: now,
          ),
          Note(
            id: 'idea',
            title: 'An idea worth keeping',
            body: 'Build something small that solves one clear problem. Start with a working flow, then improve the details.',
            category: 'Ideas',
            updated: now,
          ),
        ];
        await save();
      }
    } catch (_) {
      error = 'Saved notes could not be loaded. Existing browser storage has not been overwritten.';
    }
    notifyListeners();
  }

  Future<void> save() {
    final snapshot = jsonEncode({
      'notes': notes.map((n) => n.toJson()).toList(),
      'dark': dark,
    });
    _writes = _writes.then((_) async {
      try {
        await preferences.setString('notenest.v1', snapshot);
        error = null;
      } catch (_) {
        error = 'Changes could not be saved in this browser.';
      }
      notifyListeners();
    });
    return _writes;
  }

  void changed() {
    notifyListeners();
    save();
  }

  void upsert(Note note) {
    final index = notes.indexWhere((n) => n.id == note.id);
    if (index < 0) {
      notes.add(note);
    } else {
      notes[index] = note;
    }
    changed();
  }

  void pin(Note note) => upsert(note.withPin(!note.pinned));
  void remove(String id) {
    notes.removeWhere((n) => n.id == id);
    changed();
  }

  void toggleTheme() {
    dark = !dark;
    changed();
  }
}
