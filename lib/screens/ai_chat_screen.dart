// lib/screens/ai_chat_screen.dart
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'breathing_exercise_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_chatController.text.trim().isNotEmpty) {
      HapticFeedback.lightImpact();
      context.read<ChatProvider>().sendChatMessage(_chatController.text.trim());
      _chatController.clear();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 400), curve: Curves.easeOutQuad);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.chatMessages.isNotEmpty) {
          _scrollToBottom();
        }

        return Column(
          children: [
            Expanded(
              child: chatProvider.isLoadingHistory
                  ? _buildShimmerList() // Yüklenirken Shimmer göster
                  : chatProvider.chatMessages.isEmpty
                  ? const Center(child: Text('Sohbeti başlatmak için bir mesaj gönder.'))
                  : ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(16.0),
                itemCount: chatProvider.chatMessages.length,
                itemBuilder: (context, index) {
                  final message = chatProvider.chatMessages[index];
                  return _buildMessageBubble(context, message)
                      .animate()
                      .fade(duration: 300.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
                },
              ),
            ),
            if (chatProvider.isAnalyzing) const LinearProgressIndicator(),
            _buildMessageInput(),
          ],
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView(
        reverse: true,
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildShimmerBubble(true),
          _buildShimmerBubble(false),
          _buildShimmerBubble(true),
          _buildShimmerBubble(false),
        ],
      ),
    );
  }

  Widget _buildShimmerBubble(bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        height: 60,
        width: MediaQuery.of(context).size.width * 0.6,
        decoration: BoxDecoration(
          color: Colors.white, // Shimmer'ın parlatacağı renk
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 1, blurRadius: 5)],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: InputDecoration(
                hintText: 'Yapay zekaya danış...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: IconButton(
              onPressed: _handleSend,
              icon: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, Map<String, dynamic> message) {
    final userData = message['user_data'];
    final aiResponse = message['ai_response'];
    final primaryColor = Theme.of(context).primaryColor;

    final bool isUserMessage = (aiResponse == null && userData != null);

    if (isUserMessage) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: SelectableText(userData['notlar'] ?? ''),
        ),
      );
    } else {
      final exerciseMatch = RegExp(r'\[EGZERSİZ: (.+?)\]').firstMatch(aiResponse ?? '');
      final exerciseName = exerciseMatch?.group(1);
      final messageWithoutTag = aiResponse?.replaceAll(RegExp(r'\[EGZERSİZ: .+?\]'), '').trim() ?? '';

      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(messageWithoutTag),
              if (exerciseName != null) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => BreathingExerciseScreen(exerciseType: exerciseName))),
                  icon: Icon(FlutterRemix.lungs_line, color: primaryColor),
                  label: Text(
                    '"$exerciseName" Egzersizi',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    foregroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
  }
}