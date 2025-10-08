import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/auth_page.dart';
import 'pages/settings_page.dart';
import 'pages/sessions_page.dart';
import 'pages/stats_page.dart';
import 'db/session_db.dart';
import 'models/session.dart';
import 'package:confetti/confetti.dart';
import 'widgets/circular_button.dart';
import 'widgets/circular_timer_painter.dart';

// ---------------- HOME PAGE ----------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController(initialPage: 1);
  int _selectedIndex = 1;

  final List<Widget> _pages = const [SessionsPage(), TimerPage(), StatsPage()];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (mounted) {
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const AuthPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PomoDuo'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout)
        ],
      ),
      body: PageView(
          controller: _pageController,
          children: _pages,
          onPageChanged: (i) => setState(() => _selectedIndex = i)),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF121214),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF9B4CFF),
        unselectedItemColor: Colors.white60,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Sessions'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Timer'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
      ),
    );
  }
}

// ---------------- TIMER PAGE ----------------
class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with TickerProviderStateMixin {
  static const int _initialSeconds = 25 * 60; // 25 minutes
  int _seconds = _initialSeconds;
  Timer? _timer;
  bool _isRunning = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late ConfettiController _confettiController; // 🎉 confetti controller

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _pulseController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        _completeTimer();
      }
    });
  }

  void _pauseTimer() async {
    _timer?.cancel();
    _pulseController.stop();
    setState(() => _isRunning = false);

    // ✅ Log unfinished session
    final now = DateTime.now();
    final session = Session(
      startTime: now.subtract(Duration(seconds: (_initialSeconds - _seconds))),
      endTime: now,
      completed: false,
    );
    await SessionDB.instance.insertSession(session);
  }

  void _resetTimer() async {
    _timer?.cancel();
    _pulseController.reset();

    // ✅ Log unfinished session
    if (_seconds != _initialSeconds) {
      final now = DateTime.now();
      final session = Session(
        startTime:
            now.subtract(Duration(seconds: (_initialSeconds - _seconds))),
        endTime: now,
        completed: false,
      );
      await SessionDB.instance.insertSession(session);
    }

    setState(() {
      _seconds = _initialSeconds;
      _isRunning = false;
    });
  }

  void _completeTimer() async {
    _timer?.cancel();
    _pulseController.stop();
    setState(() => _isRunning = false);

    // ✅ Save session in DB
    await SessionDB.instance.insertSession(Session(
      startTime: DateTime.now().subtract(Duration(seconds: _initialSeconds)),
      endTime: DateTime.now(),
      completed: true,
    ));

    // 🎉 trigger confetti
    _confettiController.play();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pomodoro Complete!'),
        content: const Text('Great job! Time for a break.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetTimer();
            },
            child: const Text('Start New Session'),
          ),
        ],
      ),
    );
  }

  double get _progress => 1.0 - (_seconds / _initialSeconds);

  String get _timeString {
    final minutes = _seconds ~/ 60;
    final seconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _confettiController.dispose(); // 🎉 dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Focus Time',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Circular Timer
                  ScaleTransition(
                    scale: _isRunning
                        ? _pulseAnimation
                        : const AlwaysStoppedAnimation(1.0),
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: CustomPaint(
                        painter: CircularTimerPainter(
                          progress: _progress,
                          isRunning: _isRunning,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _timeString,
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isRunning ? 'Focus Session' : 'Ready to Focus',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),

                  // Control Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Reset Button
                      CircularButton(
                        icon: Icons.refresh,
                        onPressed: _resetTimer,
                        backgroundColor: const Color(0xFF2A2A2E),
                      ),

                      // Play/Pause Button
                      CircularButton(
                        icon: _isRunning ? Icons.pause : Icons.play_arrow,
                        onPressed: _toggleTimer,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        size: 80,
                        iconSize: 40,
                      ),

                      // Settings Button
                      CircularButton(
                        icon: Icons.settings,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsPage(),
                            ),
                          );
                        },
                        backgroundColor: const Color(0xFF2A2A2E),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 🎉 Confetti animation
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.purple,
              Colors.blue,
              Colors.orange,
              Colors.green,
            ],
          ),
        ],
      ),
    );
  }
}
