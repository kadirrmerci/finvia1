import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/note.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> _notes = [];
  final _db = DatabaseService();
  final _uuid = const Uuid();
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';

  final List<String> _categories = [
    'Tümü',
    'Kişisel',
    'İş',
    'Alışveriş',
    'Sağlık',
    'Diğer',
  ];

  final List<Map<String, dynamic>> _colors = [
    {'name': 'Beyaz', 'color': '#FFFFFF'},
    {'name': 'Sarı', 'color': '#FFF9C4'},
    {'name': 'Yeşil', 'color': '#C8E6C9'},
    {'name': 'Mavi', 'color': '#BBDEFB'},
    {'name': 'Pembe', 'color': '#F8BBD9'},
    {'name': 'Mor', 'color': '#E1BEE7'},
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final data = await _db.getNotes();
    if (!mounted) return;
    setState(() => _notes = data);
  }

  List<Note> get _filteredNotes {
    return _notes.where((n) {
      final matchesSearch =
          n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          n.content.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'Tümü' || n.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notlar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Not ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (v) => setState(() => _selectedCategory = cat),
                    selectedColor: const Color(
                      0xFF6C63FF,
                    ).withValues(alpha: 0.2),
                    checkmarkColor: const Color(0xFF6C63FF),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredNotes.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.note_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Henüz not yok',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        Text(
                          '+ butonuna basarak ekle',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: _filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = _filteredNotes[index];
                      return GestureDetector(
                        onTap: () => _showNoteDetail(note),
                        onLongPress: () => _showNoteOptions(note),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _hexToColor(note.color),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      note.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (note.isPinned)
                                    const Icon(
                                      Icons.push_pin,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(
                                  note.content,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.fade,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      note.category,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                  if (note.reminderTime != null)
                                    const Icon(
                                      Icons.alarm,
                                      size: 14,
                                      color: Colors.orange,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMM').format(note.createdAt),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNote(),
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showNoteDetail(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _NoteDetailScreen(
          note: note,
          onSave: (updatedNote) async {
            await _db.updateNote(updatedNote);
            await _loadNotes();
          },
          onDelete: () async {
            await _db.deleteNote(note.id);
            await NotificationService().cancelNotification(
              1000 + note.id.hashCode,
            );
            await _loadNotes();
          },
        ),
      ),
    );
  }

  void _showNoteOptions(Note note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              ),
              title: Text(note.isPinned ? 'Sabitlemeyi Kaldır' : 'Sabitle'),
              onTap: () async {
                await _db.updateNote(note.copyWith(isPinned: !note.isPinned));
                await _loadNotes();
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Sil', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await _db.deleteNote(note.id);
                await NotificationService().cancelNotification(
                  1000 + note.id.hashCode,
                );
                await _loadNotes();
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNote() {
    final titleC = TextEditingController();
    final contentC = TextEditingController();
    String selectedCategory = 'Kişisel';
    String selectedColor = '#FFFFFF';
    DateTime? reminderTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, set) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Yeni Not',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleC,
                  decoration: InputDecoration(
                    labelText: 'Başlık',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentC,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Not içeriği',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: _categories
                      .where((c) => c != 'Tümü')
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      set(() => selectedCategory = v ?? selectedCategory),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Renk:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _colors.map((c) {
                    final isSelected = selectedColor == c['color'];
                    return GestureDetector(
                      onTap: () => set(() => selectedColor = c['color']),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _hexToColor(c['color']),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF6C63FF)
                                : Colors.grey.shade300,
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Color(0xFF6C63FF),
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.alarm, color: Color(0xFF6C63FF)),
                  title: Text(
                    reminderTime != null
                        ? 'Hatırlatıcı: ${DateFormat('dd MMM HH:mm').format(reminderTime!)}'
                        : 'Hatırlatıcı Ekle',
                  ),
                  trailing: reminderTime != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => set(() => reminderTime = null),
                        )
                      : null,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(hours: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null && context.mounted) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        set(
                          () => reminderTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      if (titleC.text.isEmpty) return;
                      final note = Note(
                        id: _uuid.v4(),
                        title: titleC.text,
                        content: contentC.text,
                        category: selectedCategory,
                        color: selectedColor,
                        createdAt: DateTime.now(),
                        reminderTime: reminderTime,
                      );
                      await _db.insertNote(note);
                      if (reminderTime != null) {
                        await NotificationService().scheduleNoteReminder(
                          id: note.id.hashCode,
                          noteTitle: note.title,
                          noteBody: note.content.isNotEmpty
                              ? note.content
                              : 'Not hatırlatması',
                          scheduledTime: reminderTime!,
                        );
                      }
                      await _loadNotes();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Kaydet', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteDetailScreen extends StatefulWidget {
  final Note note;
  final Function(Note) onSave;
  final VoidCallback onDelete;

  const _NoteDetailScreen({
    required this.note,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<_NoteDetailScreen> {
  late TextEditingController _titleC;
  late TextEditingController _contentC;
  bool _isEditing = false;

  Color _hexToColor(String hex) =>
      Color(int.parse(hex.replaceAll('#', '0xFF')));

  @override
  void initState() {
    super.initState();
    _titleC = TextEditingController(text: widget.note.title);
    _contentC = TextEditingController(text: widget.note.content);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _hexToColor(widget.note.color),
      appBar: AppBar(
        backgroundColor: _hexToColor(widget.note.color),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () async {
              if (_isEditing) {
                final updated = widget.note.copyWith(
                  title: _titleC.text,
                  content: _contentC.text,
                );
                await widget.onSave(updated);
              }
              setState(() => _isEditing = !_isEditing);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              widget.onDelete();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _isEditing
                ? TextField(
                    controller: _titleC,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(border: InputBorder.none),
                  )
                : Text(
                    _titleC.text,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd MMMM yyyy HH:mm').format(widget.note.createdAt),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (widget.note.reminderTime != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.alarm, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Hatırlatıcı: ${DateFormat('dd MMM HH:mm').format(widget.note.reminderTime!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            Expanded(
              child: _isEditing
                  ? TextField(
                      controller: _contentC,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        _contentC.text,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
