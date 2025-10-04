import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/session_db.dart';
import '../models/session.dart';

class SessionHistoryPage extends StatefulWidget {
  const SessionHistoryPage({super.key});

  @override
  State<SessionHistoryPage> createState() => _SessionHistoryPageState();
}

class _SessionHistoryPageState extends State<SessionHistoryPage> {
  List<Session> sessions = [];
  bool loading = true;
  Map<DateTime, int> sessionData = {};

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    sessions = await SessionDB.instance.fetchSessions();

    // group sessions by date
    final Map<DateTime, int> data = {};
    for (var session in sessions) {
      final date = DateTime(session.startTime.year, session.startTime.month, session.startTime.day);
      data[date] = (data[date] ?? 0) + 1;
    }

    setState(() {
      sessionData = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (sessions.isEmpty) {
      return const Center(child: Text("No sessions yet."));
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SessionsCalendar(sessionData: sessionData),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),
        const Text(
          "Session History",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...sessions.map((session) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: session.completed ? Colors.green : Colors.orange,
                child: Icon(
                  session.completed ? Icons.check : Icons.pause,
                  color: Colors.white,
                ),
              ),
              title: Text(
                "Session on ${DateFormat.yMMMd().format(session.startTime)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Duration: ${session.durationInMinutes.toStringAsFixed(1)} mins "
                "${session.completed ? '(Completed)' : '(Paused)'}",
              ),
              trailing: null, // removed arrow
            ),
          );
        }).toList(),
      ],
    );
  }
}

/// Purple calendar in 7×N grid style
class SessionsCalendar extends StatelessWidget {
  final Map<DateTime, int> sessionData;
  final int maxSessions;

  const SessionsCalendar({
    Key? key,
    required this.sessionData,
    this.maxSessions = 6,
  }) : super(key: key);

  Color _getColor(int count) {
    if (count == 0) return Colors.grey.shade900; // no sessions
    double intensity = (count / maxSessions).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFF9B4CFF).withOpacity(0.3), const Color(0xFF9B4CFF), intensity)!;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstDayOfMonth = DateTime(today.year, today.month, 1);
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;

    final days = List.generate(daysInMonth, (i) => DateTime(today.year, today.month, i + 1));
    int startWeekday = firstDayOfMonth.weekday % 7; // align calendar

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Sessions Calendar",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Day labels row (Mon-Sun)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
              .map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: daysInMonth + startWeekday,
          itemBuilder: (context, index) {
            if (index < startWeekday) {
              return const SizedBox.shrink(); // empty slots
            }
            final day = days[index - startWeekday];
            final count = sessionData[DateTime(day.year, day.month, day.day)] ?? 0;

            return GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${DateFormat('MMM d').format(day)} → $count sessions"),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _getColor(count),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${day.day}",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}