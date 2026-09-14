import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class StylizedChatmelierQr extends StatelessWidget {
  final String sessionId;
  final String? customUrl;
  final double size;
  final String title;
  final IconData icon;
  final String? shareMessage;
  final String? shareSubject;

  const StylizedChatmelierQr({
    super.key,
    required this.sessionId,
    this.customUrl,
    this.size = 250,
    this.title = 'BLIND BATTLE CHATMELIER',
    this.icon = Icons.sports_esports_rounded,
    this.shareMessage,
    this.shareSubject,
  });

  String get targetUrl =>
      customUrl ?? 'https://chatmelier.github.io/blind?session=$sessionId';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.2,
          colors: [
            Color(0xFF2C1930),
            Color(0xFF140F1A),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B1E3F).withValues(alpha: 0.35),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête avec badge doré
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B1E3F), Color(0xFF5B1028)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD4AF37), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: const Color(0xFFD4AF37), size: 16),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cadre QR Code élargi & haute lisibilité
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: QrImageView(
              data: targetUrl,
              version: QrVersions.auto,
              size: size,
              gapless: true,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF5A0E23),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF1E1A24),
              ),
              embeddedImage: targetUrl.length < 280
                  ? const AssetImage('assets/images/logo_transparent_128.png')
                  : null,
              embeddedImageStyle: const QrEmbeddedImageStyle(
                size: Size(28, 28),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Code de session pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A24),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Code de table : ',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
                Text(
                  sessionId,
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: sessionId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF8B1E3F),
                        content: Text('Code $sessionId copié !'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Share link button
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD4AF37),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            icon: const Icon(Icons.share_rounded, size: 16),
            label: const Text('Partager le lien aux convives'),
            onPressed: () {
              final msg = shareMessage ??
                  'Rejoins ma dégustation à l\'aveugle Chatmelier ! Entre le code $sessionId ou clique ici : $targetUrl';
              final subj = shareSubject ?? 'Blind Battle Chatmelier - Code $sessionId';
              Share.share(msg, subject: subj);
            },
          ),
        ],
      ),
    );
  }
}
