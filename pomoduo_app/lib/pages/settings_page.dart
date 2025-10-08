import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/subject_db.dart';
import '../models/subject.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _focusMinutes = 25;
  int _breakMinutes = 5;
  final TextEditingController _subjectController = TextEditingController();
  List<Subject> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadSubjects();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _focusMinutes = prefs.getInt('focusMinutes') ?? 25;
      _breakMinutes = prefs.getInt('breakMinutes') ?? 5;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('focusMinutes', _focusMinutes);
    await prefs.setInt('breakMinutes', _breakMinutes);
  }

  Future<void> _loadSubjects() async {
    final subjects = await SubjectDB.instance.getSubjects();
    setState(() => _subjects = subjects);
  }

  Future<void> _addSubject() async {
    if (_subjectController.text.trim().isEmpty) return;
    await SubjectDB.instance
        .insertSubject(Subject(name: _subjectController.text.trim()));
    _subjectController.clear();
    _loadSubjects();
  }

  Future<void> _deleteSubject(int id) async {
    await SubjectDB.instance.deleteSubject(id);
    _loadSubjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              "Timer Settings",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListTile(
              title: const Text("Focus Duration (minutes)"),
              trailing: DropdownButton<int>(
                value: _focusMinutes,
                items: [15, 20, 25, 30, 45, 60]
                    .map((e) => DropdownMenuItem(value: e, child: Text("$e")))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _focusMinutes = val);
                  _saveSettings();
                },
              ),
            ),
            ListTile(
              title: const Text("Break Duration (minutes)"),
              trailing: DropdownButton<int>(
                value: _breakMinutes,
                items: [3, 5, 10, 15, 20]
                    .map((e) => DropdownMenuItem(value: e, child: Text("$e")))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _breakMinutes = val);
                  _saveSettings();
                },
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              "Subjects",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      hintText: "Enter subject name",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.purple),
                  onPressed: _addSubject,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._subjects.map((s) => ListTile(
                  title: Text(s.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteSubject(s.id!),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
