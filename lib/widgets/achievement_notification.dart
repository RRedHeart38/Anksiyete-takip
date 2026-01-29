import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/achievement.dart';

class AchievementNotification extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onDismiss;

  const AchievementNotification({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Icon mapping
    IconData icon;
    switch (achievement.icon) {
      case 'star_line':
        icon = FlutterRemix.star_line;
        break;
      case 'calendar_line':
        icon = FlutterRemix.calendar_line;
        break;
      case 'calendar_fill':
        icon = FlutterRemix.calendar_fill;
        break;
      case 'trophy_line':
        icon = FlutterRemix.trophy_line;
        break;
      case 'lightbulb_line':
        icon = FlutterRemix.lightbulb_line;
        break;
      case 'book_open_line':
        icon = FlutterRemix.book_open_line;
        break;
      case 'lungs_line':
        icon = FlutterRemix.lungs_line;
        break;
      case 'mental_health_line':
        icon = FlutterRemix.mental_health_line;
        break;
      case 'focus_3_line':
        icon = FlutterRemix.focus_3_line;
        break;
      case 'quill_pen_line':
        icon = FlutterRemix.quill_pen_line;
        break;
      case 'book_2_line':
        icon = FlutterRemix.book_2_line;
        break;
      case 'leaf_line':
        icon = FlutterRemix.leaf_line;
        break;
      case 'chat_3_line':
        icon = FlutterRemix.chat_3_line;
        break;
      case 'line_chart_line':
        icon = FlutterRemix.line_chart_line;
        break;
      default:
        icon = FlutterRemix.star_line;
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 12.0, right: 12.0),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    FlutterRemix.trophy_fill,
                    color: Colors.amber,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      achievement.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDismiss,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: -1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  static void show(BuildContext context, Achievement achievement) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => AchievementNotification(
        achievement: achievement,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);

    // 3 saniye sonra otomatik kapat
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

