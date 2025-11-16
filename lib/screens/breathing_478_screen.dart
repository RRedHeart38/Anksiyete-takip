// lib/screens/breathing_478_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';

class Breathing478Screen extends StatefulWidget {
  const Breathing478Screen({super.key});

  @override
  State<Breathing478Screen> createState() => _Breathing478ScreenState();
}

class _Breathing478ScreenState extends State<Breathing478Screen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  String _guidingText = 'Başlamak için dokun';
  bool _isExercising = false;
  int _countdown = 0;

  final List<Map<String, dynamic>> _phases = [
    {'text': 'Nefes Al', 'duration': 4},
    {'text': 'Tut', 'duration': 7},
    {'text': 'Nefes Ver', 'duration': 8},
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
        title: const Text('4-7-8 Tekniği'),
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
            ElevatedButton.icon(
              onPressed: _isExercising ? _stopExercise : _startExercise,
              icon: Icon(_isExercising ? Icons.stop : Icons.play_arrow),
              label: Text(_isExercising ? 'Durdur' : 'Başlat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isExercising ? Colors.red : primaryColor,
                foregroundColor: _isExercising ? Colors.white : theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}