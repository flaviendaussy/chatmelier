import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../domain/badge.dart';

/// Interactive modal dialog playing the cinematic video of Le Chatmelier
/// opening his sommelier waistcoat to reveal his collection of shiny badges.
class ChatmelierBadgeVideoDialog extends StatefulWidget {
  final BadgeProgress? progress;

  const ChatmelierBadgeVideoDialog({
    super.key,
    this.progress,
  });

  static Future<void> show(BuildContext context, {BadgeProgress? progress}) {
    HapticFeedback.mediumImpact();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => ChatmelierBadgeVideoDialog(progress: progress),
    );
  }

  @override
  State<ChatmelierBadgeVideoDialog> createState() => _ChatmelierBadgeVideoDialogState();
}

class _ChatmelierBadgeVideoDialogState extends State<ChatmelierBadgeVideoDialog> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/videos/chatmelier_badge_reveal.mp4');
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.play();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _toggleMute() {
    if (!_isInitialized) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _replay() {
    if (!_isInitialized) return;
    HapticFeedback.mediumImpact();
    _controller.seekTo(Duration.zero);
    _controller.play();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final progress = widget.progress;
    final badgeTitle = progress?.badge.localizedTitle(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF221124),
              Color(0xFF140A17),
              Color(0xFF1B0E1E),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.75),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
              blurRadius: 32,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.9),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.movie_filter_outlined,
                        color: Color(0xFFD4AF37),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFr ? 'Cérémonie du Chatmelier 🎬' : 'Chatmelier Trophy Reveal 🎬',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (badgeTitle != null)
                            Text(
                              badgeTitle,
                              style: TextStyle(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Colors.white12),

              // Video Player Section
              Flexible(
                child: Container(
                  width: double.infinity,
                  color: Colors.black,
                  child: _hasError
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.videocam_off_outlined, color: Colors.white38, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                isFr
                                    ? 'Vidéo momentanément indisponible sur cet appareil'
                                    : 'Video temporarily unavailable on this device',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : !_isInitialized
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 60),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFD4AF37),
                                  strokeWidth: 2.5,
                                ),
                              ),
                            )
                          : Stack(
                              alignment: Alignment.center,
                              children: [
                                GestureDetector(
                                  onTap: _togglePlayPause,
                                  child: AspectRatio(
                                    aspectRatio: _controller.value.aspectRatio,
                                    child: VideoPlayer(_controller),
                                  ),
                                ),

                                // Play / Pause overlay if paused
                                if (!_controller.value.isPlaying)
                                  GestureDetector(
                                    onTap: _togglePlayPause,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.45),
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        size: 48,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),

                                // Bottom floating controls bar
                                Positioned(
                                  bottom: 8,
                                  right: 12,
                                  left: 12,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Replay button
                                      IconButton(
                                        icon: const Icon(Icons.replay, color: Colors.white, size: 20),
                                        onPressed: _replay,
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                                          padding: const EdgeInsets.all(6),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),

                                      // Sound mute toggle
                                      IconButton(
                                        icon: Icon(
                                          _isMuted ? Icons.volume_off : Icons.volume_up,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: _toggleMute,
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                                          padding: const EdgeInsets.all(6),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                ),
              ),

              // Description Footer
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      isFr
                          ? 'Le Chatmelier ouvre son veston de sommelier pour révéler ses distinctions de cave. Admirez le nouvel insigne étincelant !'
                          : 'Le Chatmelier opens his sommelier vest to proudly reveal his cellar accolades and glowing trophy!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          isFr ? 'Superbe !' : 'Splendid !',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
