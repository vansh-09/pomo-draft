import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SessionsCalendar extends StatelessWidget {
  final Map<DateTime, int> sessionData;
  final int maxSessions;

  const SessionsCalendar({
    Key? key,
    required this.sessionData,
    this.maxSessions = 6,
  }) : super(key: key);

  Color _getColor(int count) {
    if (count == 0) return Colors.grey.shade900; // empty = dark bg
    double intensity = (count / maxSessions).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFF9B4CFF).withOpacity(0.3), const Color(0xFF9B4CFF), intensity)!;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstDayOfMonth = DateTime(today.year, today.month, 1);
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;

    final days = List.generate(daysInMonth, (i) => DateTime(today.year, today.month, i + 1));

    // get weekday offset (so calendar starts correctly)
    int startWeekday = firstDayOfMonth.weekday % 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Sessions Calendar",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, // 7 days in a week
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: daysInMonth + startWeekday,
          itemBuilder: (context, index) {
            if (index < startWeekday) {
              return const SizedBox.shrink(); // empty slot before first day
            }
            final day = days[index - startWeekday];
            final count = sessionData[DateTime(day.year, day.month, day.day)] ?? 0;

            return GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "${DateFormat('MMM d').format(day)} → $count sessions",
                    ),
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