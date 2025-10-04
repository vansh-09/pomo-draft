import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/session_db.dart';
import '../models/session.dart';
import 'dart:math';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int totalSessions = 0;
  double averageDurationMinutes = 0.0;
  int totalFocusMinutes = 0;
  int bestDaySessions = 0;
  int longestStreak = 0;
  double consistencyScore = 0.0;

  List<Session> sessions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      sessions = await SessionDB.instance.fetchSessions();

      if (sessions.isNotEmpty) {
        double totalDurationMinutes = sessions.fold(
            0.0, (sum, session) => sum + session.duration.inMinutes.toDouble());

        // Group by day
        Map<DateTime, List<Session>> groupedByDay = {};
        for (var s in sessions) {
          DateTime day = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
          groupedByDay.putIfAbsent(day, () => []).add(s);
        }

        // Best day (max sessions)
        bestDaySessions = groupedByDay.values.map((list) => list.length).fold(0, max);

        // Longest streak
        List<DateTime> sortedDays = groupedByDay.keys.toList()..sort();
        int currentStreak = 1;
        int maxStreak = 1;
        for (int i = 1; i < sortedDays.length; i++) {
          if (sortedDays[i].difference(sortedDays[i - 1]).inDays == 1) {
            currentStreak++;
            maxStreak = max(maxStreak, currentStreak);
          } else {
            currentStreak = 1;
          }
        }
        longestStreak = maxStreak;

        // Consistency score: % of days with >=4 sessions
        int consistentDays = groupedByDay.values.where((list) => list.length >= 4).length;
        consistencyScore = (consistentDays / groupedByDay.length) * 100;

        setState(() {
          totalSessions = sessions.length;
          averageDurationMinutes = totalDurationMinutes / totalSessions;
          totalFocusMinutes = totalDurationMinutes.toInt();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (totalSessions == 0)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.bar_chart,
                          size: 80,
                          color: Colors.white30,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'No Sessions Yet',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Complete some pomodoro sessions to see your stats',
                          style: TextStyle(
                            color: Colors.white54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: [
                      _buildStatCard('Total Sessions', totalSessions.toString(), Icons.play_circle_fill),
                      const SizedBox(height: 16),
                      _buildStatCard('Average Duration', '${averageDurationMinutes.toStringAsFixed(1)} min', Icons.timer),
                      const SizedBox(height: 16),
                      _buildStatCard('Total Focus Time', '${totalFocusMinutes} min', Icons.access_time),
                      const SizedBox(height: 16),
                      _buildStatCard('Best Day Sessions', bestDaySessions.toString(), Icons.star),
                      const SizedBox(height: 16),
                      _buildStatCard('Longest Streak', '$longestStreak days', Icons.local_fire_department),
                      const SizedBox(height: 16),
                      _buildStatCard('Consistency Score', '${consistencyScore.toStringAsFixed(1)}%', Icons.check_circle),

                      const SizedBox(height: 30),
                      const Text(
                        "Weekly Activity",
                        style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 200, child: _WeeklyBarChart()),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF9B4CFF).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF9B4CFF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF9B4CFF),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = [4, 6, 3, 7, 5, 2, 8]; // TODO: hook real weekly data

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 10,
        barGroups: data.asMap().entries.map((entry) {
          int index = entry.key;
          int value = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(toY: value.toDouble(), color: Colors.blue)
            ],
          );
        }).toList(),
      ),
    );
  }
}