import 'package:flutter/material.dart';

import 'note.dart';
import 'notes_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = NotesStore();
  await store.load();
  runApp(NoteNestApp(store: store));
}

const categories = ['Personal', 'Study', 'Ideas'];
const teal = Color(0xff315e58);
String dateLabel(DateTime d) =>
    '${d.day} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} ${d.year}';
Color noteColor(BuildContext context, String category) {
  if (Theme.of(context).brightness == Brightness.dark) {
    return switch (category) {
      'Study' => const Color(0xff343d46),
      'Ideas' => const Color(0xff48412f),
      _ => const Color(0xff2d443c),
    };
  }
  return switch (category) {
    'Study' => const Color(0xffe7edf1),
    'Ideas' => const Color(0xfff5eccf),
    _ => const Color(0xffe1ece2),
  };
}

class NoteNestApp extends StatelessWidget {
  final NotesStore store;
  const NoteNestApp({super.key, required this.store});
  ThemeData theme(bool dark) => ThemeData(
    useMaterial3: true,
    fontFamily: 'Manrope',
    colorScheme: ColorScheme.fromSeed(
      seedColor: teal,
      brightness: dark ? Brightness.dark : Brightness.light,
    ),
    scaffoldBackgroundColor: dark
        ? const Color(0xff1d2525)
        : const Color(0xfff8f7f2),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.all(16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NoteNest',
      theme: theme(false),
      darkTheme: theme(true),
      themeMode: store.dark ? ThemeMode.dark : ThemeMode.light,
      home: NotesHome(store: store),
    ),
  );
}

class NotesHome extends StatefulWidget {
  final NotesStore store;
  const NotesHome({super.key, required this.store});
  @override
  State<NotesHome> createState() => _NotesHomeState();
}

class _NotesHomeState extends State<NotesHome> {
  String query = '', category = 'All';
  bool pinnedOnly = false;
  NotesStore get store => widget.store;
  void openEditor() =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => NoteEditor(store: store)));

  @override
  Widget build(BuildContext context) {
    final visible =
        store.notes
            .where(
              (n) =>
                  (category == 'All' || n.category == category) &&
                  (!pinnedOnly || n.pinned) &&
                  '${n.title} ${n.body}'.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList()
          ..sort(
            (a, b) => a.pinned != b.pinned
                ? (a.pinned ? -1 : 1)
                : b.updated.compareTo(a.updated),
          );
    final compact = MediaQuery.sizeOf(context).width < 650;
    return Scaffold(
      appBar: AppBar(
        title: const Brand(),
        actions: [
          IconButton(
            tooltip: store.dark ? 'Use light theme' : 'Use dark theme',
            onPressed: store.toggleTheme,
            icon: Icon(
              store.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) => SingleChildScrollView(
          padding: EdgeInsets.all(compact ? 20 : 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (store.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        store.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  Container(
                    padding: EdgeInsets.all(compact ? 24 : 36),
                    decoration: BoxDecoration(
                      color: noteColor(context, 'Personal'),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'A SMALL SPACE FOR EVERYTHING ON YOUR MIND',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Good ideas deserve\na place to land.',
                                style: TextStyle(
                                  fontSize: compact ? 31 : 45,
                                  height: 1.1,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Lecture notes, passing thoughts, and the things you want to remember.',
                                style: TextStyle(height: 1.7, fontSize: 13),
                              ),
                              const SizedBox(height: 22),
                              FilledButton.icon(
                                key: const ValueKey('new-note'),
                                onPressed: openEditor,
                                icon: const Icon(Icons.add),
                                label: const Text('Write a note'),
                              ),
                            ],
                          ),
                        ),
                        if (!compact)
                          Padding(
                            padding: const EdgeInsets.only(left: 26),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Transform.rotate(
                                  angle: -.12,
                                  child: Container(
                                    width: 150,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surface
                                          .withValues(alpha: .5),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                                Transform.rotate(
                                  angle: .08,
                                  child: Container(
                                    width: 150,
                                    height: 160,
                                    padding: const EdgeInsets.all(23),
                                    decoration: BoxDecoration(
                                      color: noteColor(context, 'Ideas'),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.edit_note_rounded, size: 38),
                                        SizedBox(height: 12),
                                        Text(
                                          'Make a little\nroom for ideas.',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            height: 1.7,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      CountBadge(
                        '${store.notes.length} notes',
                        Icons.notes_rounded,
                      ),
                      CountBadge(
                        '${store.notes.where((n) => n.pinned).length} pinned',
                        Icons.push_pin_outlined,
                      ),
                      const CountBadge(
                        'Saved on this device',
                        Icons.check_circle_outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    key: const ValueKey('search'),
                    decoration: const InputDecoration(
                      hintText: 'Find a note by title or content',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...['All', ...categories].map(
                        (c) => ChoiceChip(
                          label: Text(c),
                          selected: category == c,
                          onSelected: (_) => setState(() => category = c),
                        ),
                      ),
                      FilterChip(
                        label: const Text('Pinned only'),
                        avatar: const Icon(Icons.push_pin_outlined, size: 16),
                        selected: pinnedOnly,
                        onSelected: (v) => setState(() => pinnedOnly = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    pinnedOnly ? 'Your pinned notes' : 'Your notes',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: visible.isEmpty
                        ? Padding(
                            key: const ValueKey('empty'),
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                const Icon(Icons.note_add_outlined, size: 42),
                                const SizedBox(height: 12),
                                const Text(
                                  'A little room for something new.',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  store.notes.isEmpty
                                      ? 'Write your first note to get started.'
                                      : 'Try another search or filter.',
                                ),
                              ],
                            ),
                          )
                        : LayoutBuilder(
                            key: const ValueKey('notes-grid'),
                            builder: (context, c) => GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: visible.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: c.maxWidth < 540
                                        ? 1
                                        : c.maxWidth < 850
                                        ? 2
                                        : 3,
                                    mainAxisExtent: 256,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                  ),
                              itemBuilder: (context, i) => NoteCard(
                                note: visible[i],
                                store: store,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => NoteDetail(
                                      store: store,
                                      id: visible[i].id,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Simple notes. A clearer mind.',
                    style: TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Brand extends StatelessWidget {
  const Brand({super.key});
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.layers_outlined, size: 25),
      SizedBox(width: 9),
      Text(
        'notenest',
        style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -.7),
      ),
    ],
  );
}

class CountBadge extends StatelessWidget {
  final String text;
  final IconData icon;
  const CountBadge(this.text, this.icon, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 7),
        Text(text, style: const TextStyle(fontSize: 11)),
      ],
    ),
  );
}

class NoteCard extends StatelessWidget {
  final Note note;
  final NotesStore store;
  final VoidCallback onTap;
  const NoteCard({
    super.key,
    required this.note,
    required this.store,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: noteColor(context, note.category),
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('note-${note.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  key: ValueKey('pin-${note.id}'),
                  tooltip: note.pinned ? 'Unpin note' : 'Pin note',
                  onPressed: () => store.pin(note),
                  icon: Icon(
                    note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                    size: 17,
                  ),
                ),
              ],
            ),
            Text(
              note.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                note.body.replaceAll('\n', ' '),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, height: 1.7),
              ),
            ),
            Row(
              children: [
                Text(
                  dateLabel(note.updated),
                  style: const TextStyle(fontSize: 10),
                ),
                const Spacer(),
                const Icon(Icons.arrow_outward, size: 18),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class NoteDetail extends StatelessWidget {
  final NotesStore store;
  final String id;
  const NoteDetail({super.key, required this.store, required this.id});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final note = store.notes.where((n) => n.id == id).firstOrNull;
      if (note == null) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('This note has been removed.')),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('Your note'),
          actions: [
            IconButton(
              tooltip: note.pinned ? 'Unpin note' : 'Pin note',
              onPressed: () => store.pin(note),
              icon: Icon(
                note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
            ),
            IconButton(
              tooltip: 'Edit note',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NoteEditor(store: store, existing: note),
                ),
              ),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete note',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialog) => AlertDialog(
                    title: const Text('Delete this note?'),
                    content: const Text(
                      'You can use Undo immediately after deletion.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialog, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(dialog, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true || !context.mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                store.remove(note.id);
                Navigator.pop(context);
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Note deleted'),
                    duration: const Duration(seconds: 8),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () => store.upsert(note),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 600 ? 24 : 40,
                ),
                decoration: BoxDecoration(
                  color: noteColor(context, note.category),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.category.toUpperCase(),
                      style: const TextStyle(
                        letterSpacing: 1.2,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SelectableText(
                      note.title,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Updated ${dateLabel(note.updated)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 28),
                    SelectableText(
                      note.body,
                      style: const TextStyle(height: 1.9, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class NoteEditor extends StatefulWidget {
  final NotesStore store;
  final Note? existing;
  const NoteEditor({super.key, required this.store, this.existing});
  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title, body;
  late String category;
  bool submitted = false;
  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.existing?.title);
    body = TextEditingController(text: widget.existing?.body);
    category = widget.existing?.category ?? 'Personal';
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'Please enter some text' : null;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.existing == null ? 'Write a note' : 'Edit your note'),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: form,
            autovalidateMode: submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Start with a thought.',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You can always come back and make it better.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  key: const ValueKey('note-title'),
                  controller: title,
                  maxLength: 100,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Give your note a title',
                  ),
                  validator: requiredText,
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => category = v!),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  key: const ValueKey('note-body'),
                  controller: body,
                  minLines: 9,
                  maxLines: 18,
                  maxLength: 5000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Your note',
                    alignLabelWithHint: true,
                    hintText: 'What would you like to remember?',
                  ),
                  validator: requiredText,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('save-note'),
                      onPressed: () {
                        setState(() => submitted = true);
                        if (!form.currentState!.validate()) return;
                        final old = widget.existing;
                        widget.store.upsert(
                          Note(
                            id:
                                old?.id ??
                                DateTime.now().microsecondsSinceEpoch
                                    .toString(),
                            title: title.text.trim(),
                            body: body.text.trim(),
                            category: category,
                            updated: DateTime.now(),
                            pinned:
                                widget.store.notes
                                    .where((n) => n.id == old?.id)
                                    .firstOrNull
                                    ?.pinned ??
                                false,
                          ),
                        );
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Save note'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
