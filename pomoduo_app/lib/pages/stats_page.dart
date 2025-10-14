import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/session_db.dart';
import '../db/quiz_result_db.dart';
import '../models/quiz_result.dart';
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
  Map<String, double> minutesBySubject = {};
  Map<String, double> minutesByTopic = {};
  List<double> weeklyDurations = List.filled(7, 0.0);
  double averageQuizScorePct = 0.0;
  Map<String, double> avgQuizByTopic = {};

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

        // Aggregate minutes by subject/topic
        final Map<String, double> subjectAgg = {};
        final Map<String, double> topicAgg = {};
        for (final s in sessions) {
          final subjectKey = (s.subject == null || s.subject!.trim().isEmpty) ? 'MSE' : s.subject!.trim();
          final topicKey = (s.topic == null || s.topic!.trim().isEmpty) ? 'MSE' : s.topic!.trim();
          subjectAgg[subjectKey] = (subjectAgg[subjectKey] ?? 0) + s.duration.inMinutes.toDouble();
          if (topicKey != 'MSE') {
            topicAgg[topicKey] = (topicAgg[topicKey] ?? 0) + s.duration.inMinutes.toDouble();
          }
        }

        // Weekly durations for last 7 days (Mon..Sun alignment by DateTime.weekday)
        final List<double> week = List.filled(7, 0.0);
        final DateTime now = DateTime.now();
        final DateTime startOfWeek = now.subtract(Duration(days: now.weekday % 7));
        for (final s in sessions) {
          final date = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
          if (date.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
            final int idx = (date.weekday % 7); // 0 = Sunday, 6 = Saturday
            week[idx] += s.duration.inMinutes.toDouble();
          }
        }

        // Load quiz results and compute averages
        final List<QuizResult> results = await QuizResultDB.instance.fetchResults();
        double avgPct = 0.0;
        final Map<String, List<double>> topicScores = {};
        if (results.isNotEmpty) {
          avgPct = results
                  .map((r) => r.total == 0 ? 0.0 : (r.score / r.total * 100.0))
                  .fold<double>(0.0, (a, b) => a + b) /
              results.length;
          for (final r in results) {
            final key = (r.topic.isEmpty) ? 'MSE' : r.topic;
            final pct = r.total == 0 ? 0.0 : (r.score / r.total * 100.0);
            if (key != 'MSE') {
              (topicScores[key] = (topicScores[key] ?? [])).add(pct);
            }
          }
        }
        final Map<String, double> topicAvg = {
          for (final e in topicScores.entries)
            e.key: e.value.fold<double>(0.0, (a, b) => a + b) / e.value.length
        };

        setState(() {
          totalSessions = sessions.length;
          averageDurationMinutes = totalDurationMinutes / totalSessions;
          totalFocusMinutes = totalDurationMinutes.toInt();
          isLoading = false;
          minutesBySubject = subjectAgg;
          minutesByTopic = topicAgg;
          weeklyDurations = week;
          averageQuizScorePct = avgPct;
          avgQuizByTopic = topicAvg;
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
                    const SizedBox(height: 16),
                    _buildStatCard('Avg Quiz Score', '${averageQuizScorePct.toStringAsFixed(1)}%', Icons.quiz_outlined),

                      const SizedBox(height: 30),
                    const Text(
                      "Weekly Focus (minutes)",
                      style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 200, child: _WeeklyBarChart(data: weeklyDurations)),

                    const SizedBox(height: 30),
                    const Text(
                      "By Subject",
                      style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(
                      height: 220,
                      child: _DonutPieChart(values: minutesBySubject),
                    ),

                    const SizedBox(height: 30),
                    const Text(
                      "By Topic",
                      style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(
                      height: 220,
                      child: _DonutPieChart(values: minutesByTopic),
                    ),

                    const SizedBox(height: 30),
                    const Text(
                      "Avg Quiz by Topic",
                      style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(
                      height: 220,
                      child: _DonutPieChart(values: avgQuizByTopic),
                    ),
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
  final List<double> data; // index 0..6, 0=Sun, 6=Sat
  const _WeeklyBarChart({Key? key, required this.data}) : super(key: key);

  static const List<String> _labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final double maxY = (data.isEmpty ? 0.0 : data.reduce((a, b) => a > b ? a : b)) * 1.2 + 10;
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final int idx = value.toInt();
                if (idx < 0 || idx >= _labels.length) return const SizedBox.shrink();
                return Text(_labels[idx], style: const TextStyle(color: Colors.white70));
              },
            ),
          ),
        ),
        maxY: maxY <= 0 ? 10 : maxY,
        barGroups: data.asMap().entries.map((entry) {
          final int index = entry.key;
          final double value = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(toY: value, color: const Color(0xFF9B4CFF), width: 14, borderRadius: BorderRadius.circular(4)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DonutPieChart extends StatelessWidget {
  final Map<String, double> values;
  const _DonutPieChart({Key? key, required this.values}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Center(
        child: Text('No data yet', style: TextStyle(color: Colors.white54)),
      );
    }
    final total = values.values.fold<double>(0, (a, b) => a + b);
    final colors = _generateColors(values.length);
    int idx = 0;
    final sections = values.entries.map((e) {
      final color = colors[idx++ % colors.length];
      final percent = total == 0 ? 0 : (e.value / total * 100);
      return PieChartSectionData(
        color: color,
        value: e.value,
        title: '${e.key} \n${percent.toStringAsFixed(0)}%',
        radius: 70,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 10),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: sections,
      ),
    );
  }

  List<Color> _generateColors(int count) {
    const base = [
      Color(0xFF9B4CFF),
      Color(0xFF4CC9F0),
      Color(0xFFF72585),
      Color(0xFF4361EE),
      Color(0xFF3A0CA3),
      Color(0xFF7209B7),
      Color(0xFF4895EF),
      Color(0xFF560BAD),
    ];
    if (count <= base.length) return base.sublist(0, count);
    return List<Color>.generate(count, (i) => base[i % base.length]);
  }
}