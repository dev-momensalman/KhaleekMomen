// lib/core/services/adhan_player.dart
// ─────────────────────────────────────────────────────────────────
// Standalone Adhan Player
// - يعمل مستقلاً عن AudioService (مش media notification)
// - يشغّل الأذان كـ simple audio — مش كـ background media session
// - مفتاح الصوت يتحكم في صوت الـ media stream العادي
// ─────────────────────────────────────────────────────────────────

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AdhanPlayer {
  AdhanPlayer._();

  // ── Singleton ────────────────────────────────────────────────
  static final AudioPlayer _player = AudioPlayer();
  static VoidCallback? _onComplete;
  static bool _isPlaying = false;

  static bool get isPlaying => _isPlaying;

  // ── Play ─────────────────────────────────────────────────────
  static Future<void> play(
    String assetOrUrl, {
    VoidCallback? onComplete,
  }) async {
    await stop();
    _onComplete = onComplete;
    _isPlaying = true;

    try {
      // ── Resolve source ────────────────────────────────────────
      final uri = Uri.tryParse(assetOrUrl);
      if (uri != null && uri.scheme == 'asset') {
        final path = uri.path.startsWith('/')
            ? uri.path.substring(1)
            : uri.path;
        await _player.setAudioSource(AudioSource.asset(path));
      } else {
        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(assetOrUrl),
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
            },
          ),
        );
      }

      // ── Listen for natural completion ─────────────────────────
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          developer.log(
            'AdhanPlayer: completed naturally',
            name: 'AdhanPlayer',
          );
          _isPlaying = false;
          final cb = _onComplete;
          _onComplete = null;
          cb?.call();
        }
      });

      await _player.play();

      developer.log('AdhanPlayer: started → $assetOrUrl', name: 'AdhanPlayer');
    } catch (e) {
      developer.log('AdhanPlayer.play error: $e', name: 'AdhanPlayer');
      _isPlaying = false;
      final cb = _onComplete;
      _onComplete = null;
      cb?.call(); // ← دايماً بنكمل حتى لو فشل الأذان
    }
  }

  // ── Stop ─────────────────────────────────────────────────────
  static Future<void> stop() async {
    try {
      _onComplete = null;
      _isPlaying = false;
      if (_player.playing) {
        await _player.stop();
      }
    } catch (e) {
      developer.log('AdhanPlayer.stop error: $e', name: 'AdhanPlayer');
    }
  }

  // ── Dispose (عند إغلاق التطبيق) ──────────────────────────────
  static Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}
