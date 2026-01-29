// music_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:url_launcher/url_launcher.dart';

class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

  // Spotify'ı açan asenkron fonksiyon
  Future<void> _launchSpotifyUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    // Kategorilere göre müzik listesi
    final Map<String, List<Map<String, dynamic>>> musicCategories = {
      'Sakinleştirici Müzikler': [
        {
          'title': 'Weightless',
          'artist': 'Marconi Union',
          'description': 'Bilimsel olarak en rahatlatıcı müzik',
          'url': 'https://open.spotify.com/track/2b1v7b1t5QAQutKZYc8Z6X',
          'icon': FlutterRemix.music_2_line,
          'color': Colors.blue,
        },
        {
          'title': 'Clair de Lune',
          'artist': 'Claude Debussy',
          'description': 'Klasik müzik ile huzur bul',
          'url': 'https://open.spotify.com/track/1EeN9eYzNKv5d7nL4UgUGo',
          'icon': FlutterRemix.music_2_line,
          'color': Colors.purple,
        },
        {
          'title': 'Gymnopédie No. 1',
          'artist': 'Erik Satie',
          'description': 'Yumuşak ve sakinleştirici',
          'url': 'https://open.spotify.com/track/6X0RbFzF1iGPiZyT8GgB6Z',
          'icon': FlutterRemix.music_2_line,
          'color': Colors.indigo,
        },
      ],
      'Doğa Sesleri': [
        {
          'title': 'Yağmur Sesleri',
          'artist': 'Nature Sounds',
          'description': 'Rahatlatıcı yağmur sesleri',
          'url': 'https://open.spotify.com/playlist/37i9dQZF1DX4sWSpwq3LiO',
          'icon': FlutterRemix.cloud_line,
          'color': Colors.cyan,
        },
        {
          'title': 'Orman Sesleri',
          'artist': 'Forest Ambience',
          'description': 'Doğanın huzur veren sesleri',
          'url': 'https://open.spotify.com/playlist/37i9dQZF1DX4sWSpwq3LiO',
          'icon': FlutterRemix.leaf_line,
          'color': Colors.green,
        },
        {
          'title': 'Okyanus Dalgaları',
          'artist': 'Ocean Waves',
          'description': 'Sakinleştirici okyanus sesleri',
          'url': 'https://open.spotify.com/playlist/37i9dQZF1DX4sWSpwq3LiO',
          'icon': FlutterRemix.water_flash_line,
          'color': Colors.blue,
        },
      ],
      'Meditasyon Müzikleri': [
        {
          'title': 'Meditation Music',
          'artist': 'Zen Music',
          'description': 'Derin meditasyon için',
          'url': 'https://open.spotify.com/playlist/37i9dQZF1DX4sWSpwq3LiO',
          'icon': FlutterRemix.mental_health_line,
          'color': Colors.purple,
        },
        {
          'title': 'Binaural Beats',
          'artist': 'Focus Music',
          'description': 'Odaklanma ve rahatlama',
          'url': 'https://open.spotify.com/playlist/37i9dQZF1DX4sWSpwq3LiO',
          'icon': FlutterRemix.focus_3_line,
          'color': Colors.deepPurple,
        },
        {
          'title': 'Chakra Healing',
          'artist': 'Healing Sounds',
          'description': 'Enerji dengeleme müzikleri',
          'url': 'https://open.spotify.com/playlist/37i9dQZF1DX4sWSpwq3LiO',
          'icon': FlutterRemix.heart_line,
          'color': Colors.pink,
        },
      ],
      'Uyku Müzikleri': [
        {
          'title': 'Deep Sleep',
          'artist': 'Sleep Music',
          'description': 'Derin uyku için',
          'url': 'https://open.spotify.com/playlist/37i9dQZF1DX4sWSpwq3LiO',
          'icon': FlutterRemix.moon_clear_line,
          'color': Colors.indigo,
        },
        {
          'title': 'Sleep Stories',
          'artist': 'Calm Stories',
          'description': 'Uyku hikayeleri',
          'url': 'https://open.spotify.com/playlist/37i9dQZF1DX4sWSpwq3LiO',
          'icon': FlutterRemix.book_open_line,
          'color': Colors.blueGrey,
        },
      ],
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sakinleştirici Müzikler'),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Başlık ve açıklama
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.1),
                  primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FlutterRemix.sound_module_line, color: primaryColor, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      'Müzikle Rahatla',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Sakinleştirici müzikler ve doğa sesleri ile stresini azalt ve zihnini rahatlat.',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Kategoriler
          ...musicCategories.entries.map((category) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    category.key,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                ...category.value.map((track) => _buildMusicCard(
                      context,
                      track: track,
                      onTap: () => _launchSpotifyUrl(track['url'] as String),
                    )),
                const SizedBox(height: 24),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMusicCard(
    BuildContext context, {
    required Map<String, dynamic> track,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final icon = track['icon'] as IconData;
    final color = track['color'] as Color;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track['artist'] as String,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track['description'] as String,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  FlutterRemix.play_circle_fill,
                  color: theme.primaryColor,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
