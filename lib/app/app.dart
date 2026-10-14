import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/theme.dart';
import '../features/settings/application/settings_providers.dart';
import '../l10n/app_localizations.dart';
import 'router/app_router.dart';

class NovellieApp extends ConsumerWidget {
  const NovellieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeColor = ref.watch(themeColorProvider);
    final currentLocale = ref.watch(currentLocaleProvider);

    return MaterialApp.router(
      title: 'Novellie',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: buildTheme(Brightness.light, themeColor),
      darkTheme: buildTheme(Brightness.dark, themeColor),
      themeMode: themeMode,
      locale: currentLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
