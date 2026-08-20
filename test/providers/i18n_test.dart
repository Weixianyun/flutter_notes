import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_notes/l10n/app_localizations.dart';
import 'package:flutter_notes/services/service_providers.dart';
import 'package:flutter_notes/features/settings/providers/settings_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('AppLocalizations provides both English and Chinese', () {
    expect(AppLocalizations.supportedLocales, contains(const Locale('en')));
    expect(AppLocalizations.supportedLocales, contains(const Locale('zh')));
  });

  testWidgets('English locale renders English strings', (tester) async {
    SharedPreferences.setMockInitialValues({'locale_code': 'en'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Scaffold(body: Text(l10n.settingsTitle));
            },
          ),
        ),
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Chinese locale renders Chinese strings', (tester) async {
    SharedPreferences.setMockInitialValues({'locale_code': 'zh'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Scaffold(body: Text(l10n.settingsTitle));
            },
          ),
        ),
      ),
    );

    expect(find.text('设置'), findsOneWidget);
  });

  test('appLocaleProvider reads locale from SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({'locale_code': 'zh'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);

    final locale = container.read(appLocaleProvider);
    expect(locale, const Locale('zh'));
  });

  test('appLocaleProvider returns null when not set (follow system)',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);

    final locale = container.read(appLocaleProvider);
    expect(locale, isNull);
  });

  test('AppLocaleNotifier.setLocale persists to SharedPreferences', () async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
    addTearDown(container.dispose);

    await container.read(appLocaleProvider.notifier).setLocale(const Locale('en'));
    expect(container.read(appLocaleProvider), const Locale('en'));
    expect(prefs.getString('locale_code'), 'en');

    await container.read(appLocaleProvider.notifier).setLocale(null);
    expect(container.read(appLocaleProvider), isNull);
    expect(prefs.getString('locale_code'), isNull);
  });
}
