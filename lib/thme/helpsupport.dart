import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

class Helpsupport extends StatefulWidget {
  final Function(bool) onPrivacyChanged;
  final bool isPrivacyEnabled;

  const Helpsupport({
    super.key,
    required this.onPrivacyChanged,
    required this.isPrivacyEnabled,
  });

  @override
  State<Helpsupport> createState() => _HelpsupportState();
}

class _HelpsupportState extends State<Helpsupport> {
  // Placeholder WhatsApp number (replace with your support number)
  final String _whatsAppNumber = '+923039328209'; // Try updating this to a valid number
  late String _whatsAppMessage;

  @override
  void initState() {
    super.initState();
    // Update WhatsApp message based on privacy status
    _whatsAppMessage = widget.isPrivacyEnabled
        ? 'Hello, I need help with my shopping query (Private Mode).'
        : 'Hello, I need help with my shopping query!';
  }

  // Function to launch WhatsApp with a pre-filled message
  Future<void> _launchWhatsApp() async {
    final Uri whatsAppUri = Uri.parse(
      'https://wa.me/$_whatsAppNumber?text=${Uri.encodeComponent(_whatsAppMessage)}',
    );
    print('Attempting to launch WhatsApp URL: $whatsAppUri'); // Log the URL for debugging
    try {
      if (await canLaunchUrl(whatsAppUri)) {
        await launchUrl(whatsAppUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp is not installed or unavailable')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening WhatsApp: $e. Please check the number or app availability.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get in Touch',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : theme.textTheme.titleLarge?.color,
                ),
              ).animate().fadeIn(duration: 500.ms),
              const SizedBox(height: 16),
              Text(
                'Need assistance? Contact our support team via WhatsApp for quick help with your shopping needs.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : theme.textTheme.bodyMedium?.color,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Private Mode',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  Switch(
                    value: widget.isPrivacyEnabled,
                    onChanged: (value) {
                      widget.onPrivacyChanged(value);
                      setState(() {
                        // Update WhatsApp message based on new privacy status
                        _whatsAppMessage = value
                            ? 'Hello, I need help with my shopping query (Private Mode).'
                            : 'Hello, I need help with my shopping query!';
                      });
                    },
                    activeColor: isDarkMode ? Colors.green[300] : theme.colorScheme.primary,
                    inactiveTrackColor: isDarkMode ? Colors.grey[700] : theme.colorScheme.surface,
                  ),
                ],
              ).animate().fadeIn(delay: 250.ms),
              if (widget.isPrivacyEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Your support interactions are private.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDarkMode ? Colors.red[300] : theme.colorScheme.error,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _launchWhatsApp,
                  icon: Icon(
                    Icons.message,
                    color: isDarkMode ? Colors.white : theme.colorScheme.onPrimary,
                  ),
                  label: Text(
                    'Contact via WhatsApp',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : theme.colorScheme.onPrimary,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.green[700] : Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 5,
                    minimumSize: const Size(200, 50),
                  ),
                ).animate().fadeIn(delay: 350.ms).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.0, 1.0),
                  duration: 400.ms,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}