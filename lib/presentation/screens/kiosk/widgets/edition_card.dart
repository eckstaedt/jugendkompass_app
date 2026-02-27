import 'package:flutter/material.dart';
import 'package:jugendkompass_app/data/models/edition_model.dart';
import 'package:jugendkompass_app/presentation/screens/kiosk/edition_detail_screen.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:jugendkompass_app/core/config/app_theme.dart';

class EditionCard extends StatelessWidget {
  final EditionModel edition;

  const EditionCard({
    super.key,
    required this.edition,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditionDetailScreen(edition: edition),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image with rounded corners
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: edition.coverImageUrl != null
                  ? CorsNetworkImage(
                      imageUrl: edition.coverImageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.shade400,
                              Colors.purple.shade600,
                            ],
                          ),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                      errorWidget: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.shade400,
                              Colors.purple.shade600,
                            ],
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.library_books, size: 48, color: Colors.white),
                            SizedBox(height: 8),
                            Text(
                              'Cover nicht verfügbar',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade400,
                            Colors.purple.shade600,
                          ],
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.library_books, size: 48, color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            'Cover nicht verfügbar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            edition.displayTitle,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
