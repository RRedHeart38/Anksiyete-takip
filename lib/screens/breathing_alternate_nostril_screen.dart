// lib/screens/breathing_alternate_nostril_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';

class BreathingAlternateNostrilScreen extends StatefulWidget {
  const BreathingAlternateNostrilScreen({super.key});

  @override
  State<BreathingAlternateNostrilScreen> createState() => _BreathingAlternateNostrilScreenState();
}

class _BreathingAlternateNostrilScreenState extends State<BreathingAlternateNostrilScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  String _guidingText = 'Başlamak için dokun';
  bool _isExercising = false;
  int _countdown = 0;

  final List<Map<String, dynamic>> _phases = [
    {'text': 'Sol Burun Deliğinden Nefes Al', 'duration': 4},
    {'text': 'Tut (iki burun deliği kapalı)', 'duration': 4},
    {'text': 'Sağ Burun Deliğinden Nefes Ver', 'duration': 6},
    {'text': 'Sağ Burun Deliğinden Nefes Al', 'duration': 4},
    {'text': 'Tut (iki burun deliği kapalı)', 'duration': 4},
    {'text': 'Sol Burun Deliğinden Nefes Ver', 'duration': 6},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000), // Başlangıç animasyon süresi
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _startExercise() {
    if (_isExercising) return;
    _isExercising = true;
    _startPhase(0);
  }

  void _stopExercise() {
    _isExercising = false;
    _controller.stop();
    setState(() {
      _guidingText = 'Durduruldu';
      _countdown = 0;
    });
  }

  void _startPhase(int phaseIndex) {
    if (!_isExercising) return;

    if (phaseIndex >= _phases.length) {
      _startPhase(0); // Döngü
      return;
    }

    final phase = _phases[phaseIndex];
    setState(() {
      _guidingText = phase['text'];
      _countdown = phase['duration'];
    });

    _controller.repeat(reverse: true);

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isExercising) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
      });

      if (_countdown <= 0) {
        timer.cancel();
        _controller.reset();
        _startPhase(phaseIndex + 1);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Alternatif Burun Nefesi'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        iconTheme: theme.appBarTheme.iconTheme,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _guidingText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _isExercising ? _stopExercise : _startExercise,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.5),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: _scaleAnimation.value * 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _isExercising ? _countdown.toString() : 'Başla',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}