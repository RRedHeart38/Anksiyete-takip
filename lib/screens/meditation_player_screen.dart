import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/meditation.dart';
import '../providers/goal_provider.dart';
import '../providers/achievement_provider.dart';

class MeditationPlayerScreen extends StatefulWidget {
  final Meditation meditation;

  const MeditationPlayerScreen({super.key, required this.meditation});

  @override
  State<MeditationPlayerScreen> createState() => _MeditationPlayerScreenState();
}

class _MeditationPlayerScreenState extends State<MeditationPlayerScreen> with TickerProviderStateMixin {
  bool _isPlaying = false;
  bool _hasStarted = false; // To show intro screen first
  int _elapsedSeconds = 0;
  Timer? _timer;
  int _currentStepIndex = 0;
  
  // Animation controllers
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  void _updateStep() {
    // Distribute steps evenly across duration
    if (widget.meditation.steps.isEmpty) return;
    
    final totalSeconds = widget.meditation.duration * 60;
    final stepDuration = totalSeconds / widget.meditation.steps.length;
    
    final newStepIndex = (_elapsedSeconds / stepDuration).floor().clamp(0, widget.meditation.steps.length - 1);
    
    if (newStepIndex != _currentStepIndex) {
      setState(() {
        _currentStepIndex = newStepIndex;
      });
    }
  }

  void _startMeditation() {
    setState(() {
      _hasStarted = true;
      _isPlaying = true;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
          _updateStep();
          
          if (_elapsedSeconds >= widget.meditation.duration * 60) {
            _stopTimer();
            _showCompletionDialog();
          }
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _breathingController.repeat(reverse: true);
        _startTimer();
      } else {
        _breathingController.stop();
        _stopTimer();
      }
    });
  }

  void _reset() {
    setState(() {
      _elapsedSeconds = 0;
      _currentStepIndex = 0;
      _isPlaying = false;
      _stopTimer();
    });
  }

  Future<void> _recordMeditation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('meditation_completions')
          .add({
        'meditation_id': widget.meditation.id,
        'meditation_title': widget.meditation.title,
        'duration': widget.meditation.duration,
        'type': widget.meditation.type,
        'completed_at': Timestamp.now(),
      });
      
      if (mounted) {
        await context.read<GoalProvider>().updateProgressByCategory('meditation', 1);
        context.read<AchievementProvider>().checkAchievements();
      }
    } catch (e) {
      print('Meditasyon kaydedilirken hata: $e');
    }
  }

  void _showCompletionDialog() {
    _recordMeditation();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(FlutterRemix.checkbox_circle_line, color: Colors.green),
            SizedBox(width: 10),
            Text('Tebrikler! 🎉'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.meditation.title} tamamlandı.'),
            const SizedBox(height: 10),
            const Text('Kendine ayırdığın bu zaman için teşekkür et.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dialog
              Navigator.of(context).pop(); // Screen
            },
            child: const Text('Tamamla', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasStarted) {
      return _buildIntroScreen(context);
    }
    return _buildPlayerScreen(context);
  }

  Widget _buildIntroScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'meditation_icon_${widget.meditation.id}',
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.meditation.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    FlutterRemix.mental_health_line,
                    size: 48,
                    color: widget.meditation.color,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.meditation.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ).animate().fadeIn().slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 16),
              Text(
                widget.meditation.detailedDescription,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 32),
              const Text(
                "Faydaları",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 12),
              
              ...widget.meditation.benefits.map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: widget.meditation.color, size: 20),
                    const SizedBox(width: 12),
                    Text(benefit, style: const TextStyle(fontSize: 15)),
                  ],
                ),
              )).toList().animate(interval: 100.ms).fadeIn(delay: 500.ms).slideX(begin: 0.1, end: 0),

              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startMeditation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.meditation.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Başla",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.5, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerScreen(BuildContext context) {
    final remainingSeconds = (widget.meditation.duration * 60) - _elapsedSeconds;
    final progress = _elapsedSeconds / (widget.meditation.duration * 60);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Gradient Animation (Simplified visual loop)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _breathingController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8 + (_breathingController.value * 0.4), // Breathe effect
                      colors: [
                        widget.meditation.color.withOpacity(0.05 + (_breathingController.value * 0.1)),
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 16, color: Theme.of(context).iconTheme.color?.withOpacity(0.6)),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(remainingSeconds),
                              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_outlined), // Placeholder for volume
                        onPressed: () {}, 
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Main Visual Content
                SizedBox(
                  height: 300,
                  width: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress Ring
                      SizedBox(
                        width: 280,
                        height: 280,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2,
                          backgroundColor: Theme.of(context).dividerColor.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(widget.meditation.color),
                        ),
                      ),
                      
                      // Breathing Circle
                      AnimatedBuilder(
                        animation: _breathingController,
                        builder: (context, child) {
                          return Container(
                            width: 200 + (_breathingController.value * 40),
                            height: 200 + (_breathingController.value * 40),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.meditation.color.withOpacity(0.1),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.meditation.color.withOpacity(0.2),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                )
                              ]
                            ),
                          );
                        },
                      ),
                      
                      // Icon
                      Icon(
                        FlutterRemix.mental_health_line,
                        size: 64,
                        color: widget.meditation.color,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Step Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      widget.meditation.steps.isNotEmpty 
                          ? widget.meditation.steps[_currentStepIndex]
                          : "Nefesine odaklan...",
                      key: ValueKey<int>(_currentStepIndex),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _reset,
                        icon: const Icon(Icons.replay_rounded),
                        iconSize: 32,
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                      ),
                      const SizedBox(width: 32),
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: widget.meditation.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.meditation.color.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ]
                        ),
                        child: IconButton(
                          onPressed: _togglePlayPause,
                          icon: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, 
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                       IconButton(
                        onPressed: () {}, // Future feature: settings
                        icon: const Icon(Icons.tune_rounded),
                        iconSize: 32,
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    if (seconds <= 0) return "00:00";
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
