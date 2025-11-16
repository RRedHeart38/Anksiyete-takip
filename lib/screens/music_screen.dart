// music_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MusicScreen extends StatelessWidget {
  const MusicScreen({Key? key}) : super(key: key);

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

    // Örnek şarkı listesi. Buraya istediğin şarkıları ekleyebilirsin.
    final List<Map<String, String>> musicList = [
      {
        'title': 'Sakin Sabahlar',
        'artist': 'Relax Music',
        'url': 'https://open.spotify.com/track/4jVv9l62K70E7wW9o2gK8t?si=a2c2864a6e8f46b2', // Örnek Spotify URL'si
      },
      {
        'title': 'Meditasyon Akış',
        'artist': 'Meditation Flow',
        'url': 'https://open.spotify.com/track/6xYqg3B94j3K5L4J97Vj0J?si=e2f83f2a5e9a4f6d',
      },
      {
        'title': 'Doğa Sesleri: Yağmur',
        'artist': 'Nature Sounds',
        'url': 'https://open.spotify.com/track/1a2r1l6l5p0y5a4n9a5d1b?si=e9f73a3a4b6c4e5a',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sakin Müzikler', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        itemCount: musicList.length,
        itemBuilder: (context, index) {
          final track = musicList[index];
          return Card(
            color: theme.cardColor,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            child: ListTile(
              leading: Icon(Icons.music_note, color: theme.colorScheme.primary),
              title: Text(
                track['title']!,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(
                track['artist']!,
                style: theme.textTheme.bodyMedium,
              ),
              trailing: Icon(Icons.play_circle_fill, color: theme.colorScheme.primary),
              onTap: () {
                _launchSpotifyUrl(track['url']!);
              },
            ),
          );
        },
      ),
    );
  }
}