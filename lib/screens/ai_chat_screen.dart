import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'breathing_exercise_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/meditation.dart';
import 'meditation_player_screen.dart';

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
                  ? _buildShimmerList()
                  : chatProvider.chatMessages.isEmpty
                  ? SingleChildScrollView(child: Column(children: [_buildHeader(context), _buildEmptyState(context)]))
                  : ListView.builder(
                controller: _scrollController,
                reverse: true, // Liste ters
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                // +1 ekliyoruz çünkü en sona (aslında en başa) header koyacağız
                itemCount: chatProvider.chatMessages.length + 1,
                itemBuilder: (context, index) {
                   // index == length ise, bu listenin en son elemanıdır.
                   // reverse: true olduğu için, en son eleman görsel olarak EN ÜSTTE durur.
                   // Yani Header'ı buraya koyacağız.
                   if (index == chatProvider.chatMessages.length) {
                     return Padding(
                       padding: const EdgeInsets.only(bottom: 16.0), // Header ile mesajlar arası boşluk
                       child: _buildHeader(context),
                     );
                   }
                   
                  final message = chatProvider.chatMessages[index];
                  return _buildMessageBubble(context, message)
                      .animate()
                      .fade(duration: 300.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
                },
              ),
            ),
            if (chatProvider.isAnalyzing) 
              const LinearProgressIndicator(minHeight: 2),
            _buildMessageInput(),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            const Color(0xFF818CF8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(FlutterRemix.chat_smile_2_line, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yapay Zeka',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              Text(
                'Kişisel Asistanın',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(FlutterRemix.robot_line, size: 60, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 16),
          const Text('Merhaba! Ben senin yapay zeka asistanınım.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Bana nasıl hissettiğini anlat,\ndertleşelim veya öneri iste.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
  
  Widget _buildMessageInput() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + keyboardInset + 45),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: InputDecoration(
                hintText: 'Buraya yaz...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: IconButton(
              onPressed: _handleSend,
              icon: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, Map<String, dynamic> message) {
    final userData = message['user_data'];
    final aiResponse = message['ai_response'] as String?;
    final source = (message['source'] ?? '').toString();

    final userText = (userData is Map && userData['notlar'] != null)
        ? userData['notlar'].toString().trim()
        : '';

    final showUserBubble = source == 'chat' && userText.isNotEmpty;
    final showAiBubble = aiResponse != null && aiResponse.trim().isNotEmpty;

    if (!showUserBubble && !showAiBubble) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showUserBubble) _buildUserBubble(context, userText),
        if (showAiBubble) _buildAiBubble(context, aiResponse!),
      ],
    );
  }

  Widget _buildUserBubble(BuildContext context, String messageText) {
    final primaryColor = Theme.of(context).primaryColor;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Text(
          messageText,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildAiBubble(BuildContext context, String aiResponse) {
    final exerciseMatch = RegExp(r'\[EGZERSİZ: (.+?)\]').firstMatch(aiResponse);
    final exerciseName = exerciseMatch?.group(1);

    final meditationMatch = RegExp(r'\[MEDİTASYON: (.+?)\]').firstMatch(aiResponse);
    final meditationName = meditationMatch?.group(1);

    String messageDisplay = aiResponse;
    messageDisplay = messageDisplay.replaceAll(RegExp(r'\[EGZERSİZ: .+?\]'), '');
    messageDisplay = messageDisplay.replaceAll(RegExp(r'\[MEDİTASYON: .+?\]'), '');
    messageDisplay = messageDisplay.trim();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              messageDisplay,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (exerciseName != null) ...[
              const SizedBox(height: 12),
              _buildActionButton(context, '"$exerciseName" Egzersizi', FlutterRemix.lungs_line, () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => BreathingExerciseScreen(exerciseType: exerciseName)));
              }),
            ],
            if (meditationName != null) ...[
              const SizedBox(height: 12),
              _buildActionButton(context, '"$meditationName" Başlat', FlutterRemix.mental_health_line, () {
                try {
                  final meditation = Meditation.getMeditations().firstWhere(
                    (m) => m.title == meditationName,
                    orElse: () => Meditation.getMeditations().first,
                  );
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => MeditationPlayerScreen(meditation: meditation)));
                } catch (e) {
                  print("Meditasyon bulunamadı: $e");
                }
              }),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          foregroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}