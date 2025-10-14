import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'pages/settings_page.dart';
import 'models/subject.dart';
import 'db/subject_db.dart';
import 'db/session_db.dart';
import 'models/session.dart';
import 'widgets/circular_button.dart';
import 'widgets/circular_timer_painter.dart';
import 'pages/quiz_page.dart';
import 'pages/sessions_page.dart';
import 'pages/stats_page.dart';
import 'pages/auth_page.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController(initialPage: 1);
  int _selectedIndex = 1;

  final List<Widget> _pages = [
    const SessionsPage(),
    const TimerPage(),
    const StatsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const AuthPage()));
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
        onPageChanged: (i) => setState(() => _selectedIndex = i),
      ),
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

class _TimerPageState extends State<TimerPage> with TickerProviderStateMixin {
  int _focusMinutes = 25;
  int _seconds = 25 * 60;
  Timer? _timer;
  bool _isRunning = false;
  DateTime? _sessionStartTime;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late ConfettiController _confettiController;

  List<Subject> _subjects = [];
  Subject? _selectedSubject;
  String? _selectedTopic;

  @override
  void initState() {
    super.initState();
    _pulseController =
        AnimationController(duration: const Duration(seconds: 1), vsync: this);
    _pulseAnimation =
        Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _initializeTimerPage();
  }

  Future<void> _initializeTimerPage() async {
    await _loadTimerSettings();
    await _loadSubjects();
  }

  Future<void> _loadTimerSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final focusMinutes = prefs.getInt('focusMinutes') ?? 25;
    setState(() {
      _focusMinutes = focusMinutes;
      _seconds = _focusMinutes * 60;
    });
  }

  Future<void> _loadSubjects() async {
    final subjects = await SubjectDB.instance.getSubjects();
    setState(() => _subjects = subjects);
  }

  String mapTopic(String topic) {
    switch (topic) {
      case 'CP':
        return 'C Programming';
      case 'COA':
        return 'COA';
      case 'DSGT':
        return 'DSGT';
      default:
        return topic;
    }
  }

  void _toggleTimer() {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject first')),
      );
      return;
    }

    if (_selectedTopic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a topic')),
      );
      return;
    }

    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentTopic', _selectedTopic!);

    setState(() => _isRunning = true);
    _pulseController.repeat(reverse: true);

    // Record start time for this session
    _sessionStartTime = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        _completeTimer();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    _pulseController.reset();
    setState(() {
      _seconds = _focusMinutes * 60;
      _isRunning = false;
    });
    _sessionStartTime = null;
  }

  void _completeTimer() async {
    _timer?.cancel();
    _pulseController.stop();
    setState(() => _isRunning = false);
    _confettiController.play();

    final prefs = await SharedPreferences.getInstance();
    final topic = prefs.getString('currentTopic') ?? "N/A";

    // Persist completed session
    final DateTime endTime = DateTime.now();
    final DateTime startTime = _sessionStartTime ?? endTime.subtract(Duration(minutes: _focusMinutes));
    final session = Session(
      startTime: startTime,
      endTime: endTime,
      completed: true,
      subject: _selectedSubject?.name,
      topic: mapTopic(topic),
    );
    try {
      await SessionDB.instance.insertSession(session);
    } catch (_) {
      // swallow insert error to not block UX
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Pomodoro Complete!'),
        content:
            Text('Subject: ${_selectedSubject?.name ?? "N/A"}\nTopic: $topic'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Start Quiz'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizPage(topic: mapTopic(topic), subject: _selectedSubject?.name ?? 'MSE'),
      ),
    );

    _resetTimer();
  }

  double get _progress => 1.0 - (_seconds / (_focusMinutes * 60));

  String get _timeString {
    final minutes = _seconds ~/ 60;
    final seconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _confettiController.dispose();
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
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E22),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFF9B4CFF), width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: const Color(0xFF1E1E22),
                        value: _selectedTopic,
                        hint: const Text(
                          'Select Topic',
                          style: TextStyle(color: Colors.white70),
                        ),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.white70),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                              value: 'CP',
                              child: Text('C Programming',
                                  style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(
                              value: 'COA',
                              child: Text('COA',
                                  style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(
                              value: 'DSGT',
                              child: Text('DSGT',
                                  style: TextStyle(color: Colors.white))),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedTopic = value),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E22),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFF9B4CFF), width: 1),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Subject>(
                        dropdownColor: const Color(0xFF1E1E22),
                        value: (_selectedSubject != null &&
                                _subjects
                                    .any((s) => s.id == _selectedSubject!.id))
                            ? _subjects
                                .firstWhere((s) => s.id == _selectedSubject!.id)
                            : null,
                        hint: const Text(
                          'Select Subject',
                          style: TextStyle(color: Colors.white70),
                        ),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.white70),
                        isExpanded: true,
                        items: _subjects
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                    s.name,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ))
                            .toList(),
                        onChanged: (s) => setState(() => _selectedSubject = s),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

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
                          child: Text(
                            _timeString,
                            style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w300,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CircularButton(
                        icon: Icons.refresh,
                        onPressed: _resetTimer,
                        backgroundColor: const Color(0xFF2A2A2E),
                      ),
                      CircularButton(
                        icon: _isRunning ? Icons.pause : Icons.play_arrow,
                        onPressed: _toggleTimer,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        size: 80,
                        iconSize: 40,
                      ),
                      CircularButton(
                        icon: Icons.settings,
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsPage()),
                          );
                          await _initializeTimerPage();
                        },
                        backgroundColor: const Color(0xFF2A2A2E),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
          ),
        ],
      ),
    );
  }
}