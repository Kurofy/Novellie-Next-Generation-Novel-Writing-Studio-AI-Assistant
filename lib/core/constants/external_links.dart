import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Centralized external links for Novellie
class AppExternalLinks {
  const AppExternalLinks._();

  static const github = 'https://github.com/novellie';
  static const saweria = 'https://saweria.co/kurofy';
  static const sociaBuzz = 'https://sociabuzz.com/kurofy';
  static const buyMeACoffee = 'https://buymeacoffee.com/kurofy';

  /// Launches an external URL in the default browser.
  /// If launching fails, copies the link to clipboard with feedback.
  static Future<void> openUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: urlString));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open browser. Link copied: $urlString'),
            ),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: urlString));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Link copied to clipboard: $urlString'),
          ),
        );
      }
    }
  }
}

/// Official brand SVG strings for clean vector rendering
class AppBrandSvgs {
  const AppBrandSvgs._();

  static const String github =
      '<svg viewBox="0 0 24 24" fill="currentColor">'
      '<path fill-rule="evenodd" clip-rule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.53 1.032 1.53 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"/>'
      '</svg>';


  static const String buyMeACoffee =
      '<svg viewBox="0 0 24 24" fill="currentColor">'
      '<path d="M20.216 6.415l-.132-.666c-.119-.597-.388-1.157-.78-1.618C18.644 3.36 17.72 3 16.634 3H3.662C2.195 3 1 4.195 1 5.662v6.676C1 15.65 3.66 18.3 6.974 18.3h6.69c3.167 0 5.753-2.435 5.96-5.556l.592-3.791c.21-1.348-.002-1.89-.002-2.538zm-2.48 2.455l-.466 2.986c-.12 1.79-1.608 3.19-3.407 3.19H6.974c-1.89 0-3.428-1.538-3.428-3.428V5.662c0-.365.297-.662.662-.662h12.426c.49 0 .88.22 1.068.598.113.227.172.502.217.727l.117.585v.002c-.002.327-.19 1.166-.3 1.958z"/>'
      '</svg>';

  static const String saweria =
      '<svg viewBox="0 0 24 24" fill="currentColor">'
      '<path d="M12 2a10 10 0 1010 10A10.011 10.011 0 0012 2zm1 14.5a1 1 0 01-2 0v-.58a4.004 4.004 0 01-2.92-3.42 1 1 0 011.98-.3 2.003 2.003 0 001.94 1.8 1.94 1.94 0 002-1.92c0-1.2-1-1.74-2.53-2.28C9.55 9.14 8 8.44 8 6.5A3.94 3.94 0 0111 2.6V2a1 1 0 012 0v.6a3.86 3.86 0 012.72 3.15 1 1 0 01-1.98.35 1.87 1.87 0 00-1.74-1.6 1.94 1.94 0 00-2 1.9c0 1.1 1 1.62 2.5 2.15 2 0.7 3.5 1.5 3.5 3.5a3.94 3.94 0 01-3 3.9z"/>'
      '</svg>';

  static const String sociaBuzz =
      '<svg viewBox="0 0 24 24" fill="currentColor">'
      '<path d="M12 2L3 7v10l9 5 9-5V7l-9-5zm0 2.2l6.8 3.8-3.4 1.9-6.8-3.8L12 4.2zm-7 4.9l6 3.3v6.7L5 15.8V9.1zm8 10V12.4l6-3.3v6.7l-6 3.3z"/>'
      '</svg>';
}
