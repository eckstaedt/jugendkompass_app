import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
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
    final textColor = DesignTokens.getTextPrimary(brightness);
    final textSecondary = DesignTokens.getTextSecondary(brightness);

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
            // Title if available
            if (message.title != null && message.title!.isNotEmpty) ...[
              Text(
                message.title!,
                style: GoogleFonts.poppins(
                  textStyle: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Date
            Text(
              dateFormat.format(message.createdAt),
              style: GoogleFonts.poppins(
                textStyle: theme.textTheme.bodySmall?.copyWith(
                  color: textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Message body rendered as HTML
            Html(
              data: message.message,
              style: {
                "body": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontSize: FontSize(16),
                  lineHeight: LineHeight(1.6),
                  color: textColor,
                ),
                "p": Style(
                  margin: Margins.only(bottom: 12),
                  padding: HtmlPaddings.zero,
                ),
                "a": Style(
                  color: DesignTokens.primaryRed,
                  textDecoration: TextDecoration.underline,
                ),
                "img": Style(
                  margin: Margins.only(top: 16, bottom: 16),
                  display: Display.block,
                  width: Width(60, Unit.percent),
                  alignment: Alignment.center,
                ),
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
