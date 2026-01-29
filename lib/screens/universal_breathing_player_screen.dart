import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/breathing_pattern.dart';
import '../providers/goal_provider.dart';
import '../providers/achievement_provider.dart';

class UniversalBreathingPlayerScreen extends StatefulWidget {
  final BreathingPattern pattern;

  const UniversalBreathingPlayerScreen({super.key, required this.pattern});

  @override
  State<UniversalBreathingPlayerScreen> createState() => _UniversalBreathingPlayerScreenState();
}

class _UniversalBreathingPlayerScreenState extends State<UniversalBreathingPlayerScreen> with TickerProviderStateMixin {
  bool _hasStarted = false;
  bool _isPlaying = false;
  
  // Exercise State
  int _currentPhaseIndex = 0;
  int _phaseRemainingSeconds = 0;
  int _totalCyclesCompleted = 0;
  
  Timer? _timer;
  late AnimationController _visualController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _visualController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Placeholder, updated dynamically
    );
     _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(_visualController);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _visualController.dispose();
    super.dispose();
  }

  void _startExercise() {
    setState(() {
      _hasStarted = true;
      _isPlaying = true;
      _currentPhaseIndex = 0;
      _totalCyclesCompleted = 0;
    });
    _startPhase(0);
  }

  void _startPhase(int index) {
    if (!mounted || !_isPlaying) return;

    final phase = widget.pattern.phases[index];
    
    // Setup animation based on phase type
    _visualController.duration = Duration(seconds: phase.duration);
    
    double begin = 1.0;
    double end = 1.0;
    
    // Scale logic: Inhale -> Expand, Exhale -> Contract, Hold -> Stay
    if (phase.label.toLowerCase().contains('al')) {
      begin = 1.0;
      end = 1.5;
    } else if (phase.label.toLowerCase().contains('ver')) {
      begin = 1.5;
      end = 1.0;
    } else {
      // HOLD: keep previous scale
      begin = _scaleAnimation.value;
      end = _scaleAnimation.value;
    }

    // Update animation
    _scaleAnimation = Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _visualController, curve: Curves.easeInOut),
    );

    _visualController.forward(from: 0.0);
    HapticFeedback.mediumImpact();

    setState(() {
      _currentPhaseIndex = index;
      _phaseRemainingSeconds = phase.duration;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        _phaseRemainingSeconds--;
      });

      if (_phaseRemainingSeconds <= 0) {
        timer.cancel();
        // Move to next phase
        int nextIndex = _currentPhaseIndex + 1;
        if (nextIndex >= widget.pattern.phases.length) {
          nextIndex = 0;
          _totalCyclesCompleted++;
          
          // Optional: Auto-stop after some cycles? Or just infinite loop.
          // Let's do infinite for now until user stops.
        }
        _startPhase(nextIndex);
      }
    });
  }

  void _stopExercise() {
    _timer?.cancel();
    _visualController.stop();
    setState(() {
      _isPlaying = false;
    });
  }
  
  void _resumeExercise() {
    setState(() {
      _isPlaying = true;
    });
    // Restart current phase logic somewhat? 
    // Ideally we pause the animation and timer, but for simplicity let's restart phase
    _startPhase(_currentPhaseIndex);
  }

  Future<void> _finishSession() async {
    _stopExercise();
    if (_totalCyclesCompleted > 0) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('breathing_exercises')
            .add({
              'exercise_type': widget.pattern.title,
              'cycles': _totalCyclesCompleted,
              'tarih': Timestamp.now(),
            });
            
          if (mounted) {
            context.read<AchievementProvider>().checkAchievements();
            context.read<GoalProvider>().updateProgressByCategory('breathing', 1);
          }
        } catch(e) {
          print("Error saving breathing: $e");
        }
      }
      _showCompletionDialog();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Oturum Tamamlandı'),
        content: Text('Tebrikler! $_totalCyclesCompleted döngü tamamladın.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasStarted) {
      return _buildIntro(context);
    }
    return _buildPlayer(context);
  }

  Widget _buildIntro(BuildContext context) {
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.pattern.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(FlutterRemix.lungs_line, size: 48, color: widget.pattern.color),
              ).animate().scale(),
              const SizedBox(height: 24),
              Text(
                widget.pattern.title,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ).animate().fadeIn().slideX(),
              const SizedBox(height: 16),
              Text(
                widget.pattern.detailedDescription,
                style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.5),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 32),
              const Text(" Nasıl Yapılır?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              ...widget.pattern.phases.map((phase) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: widget.pattern.color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text("${phase.duration}s", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: widget.pattern.color)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text("${phase.label}: ${phase.instruction}", style: const TextStyle(fontSize: 15))),
                  ],
                ),
              )).toList(),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.pattern.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Başla", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer(BuildContext context) {
    final currentPhase = widget.pattern.phases[_currentPhaseIndex];
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _finishSession,
                      ),
                      Text("Döngü: $_totalCyclesCompleted", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 48), // Balance
                    ],
                  ),
                ),
                const Spacer(),
                
                // Visualizer
                AnimatedBuilder(
                  animation: _visualController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                            color: widget.pattern.color.withOpacity(0.3),
                            shape: BoxShape.circle,
                            boxShadow: [
                                BoxShadow(
                                color: widget.pattern.color.withOpacity(0.2),
                                blurRadius: 40,
                                spreadRadius: 20,
                                )
                            ]
                        ),
                        child:  Center(
                          child: Text(
                             "${_phaseRemainingSeconds}s",
                             style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 60),
                
                Text(
                  currentPhase.label, 
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ).animate(key: ValueKey(currentPhase.label)).fadeIn().slideY(begin: 0.1, end: 0),
                const SizedBox(height: 12),
                Text(
                  currentPhase.instruction,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                ),

                const Spacer(),
                
                Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          color: widget.pattern.color,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _isPlaying ? _stopExercise : _resumeExercise,
                          icon: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow, 
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
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
}
