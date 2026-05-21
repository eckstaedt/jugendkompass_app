import 'package:flutter/material.dart';
import 'package:jugendkompass_app/data/models/verse_model.dart';
import 'package:google_fonts/google_fonts.dart';

/// A self-contained widget that is rendered off-screen (or hidden) and
/// captured as an image for sharing.  It intentionally uses a plain white
/// background and black text so the output looks clean regardless of the
/// app's current theme.
class VerseShareCard extends StatelessWidget {
  final VerseModel verse;

  const VerseShareCard({super.key, required this.verse});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080 / 3, // 360 logical pixels → 1080 px @ pixelRatio 3×
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── App label ──────────────────────────────────────────────
          Text(
            'JUGENDKOMPASS',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFD94040),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'VERS DES TAGES',
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // ── Divider ────────────────────────────────────────────────
          Container(height: 2, width: 40, color: const Color(0xFFD94040)),
          const SizedBox(height: 24),

          // ── Verse text ─────────────────────────────────────────────
          Text(
            '"${verse.verse}"',
            style: GoogleFonts.merriweather(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),

          // ── Reference ──────────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— ${verse.reference}',
              style: GoogleFonts.merriweather(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── Footer ─────────────────────────────────────────────────
          Container(
            height: 1,
            color: Colors.black12,
          ),
          const SizedBox(height: 12),
          Text(
            'jugendkompass.de',
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: Colors.black38,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
