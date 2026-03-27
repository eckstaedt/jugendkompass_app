import 'package:flutter/material.dart';
import 'package:jugendkompass_app/data/models/message_model.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/presentation/widgets/common/cors_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MessageDetailScreen extends StatelessWidget {
  final MessageModel message;

  const MessageDetailScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final dateFormat = DateFormat('dd. MMMM yyyy, HH:mm', 'de_DE');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kurznachricht',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(DesignTokens.paddingHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image if available
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
                child: CorsNetworkImage(
                  imageUrl: message.imageUrl!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Date
            Text(
              dateFormat.format(message.createdAt),
              style: GoogleFonts.poppins(
                textStyle: theme.textTheme.bodySmall?.copyWith(
                  color: DesignTokens.getTextSecondary(brightness),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Message body
            Text(
              message.message,
              style: GoogleFonts.poppins(
                textStyle: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: DesignTokens.getTextPrimary(brightness),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
