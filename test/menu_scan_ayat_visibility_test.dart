import 'package:dilalquran/config/ai_config.dart';
import 'package:dilalquran/modules/menu/screen/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kartu "Scan Ayat" hanya boleh tampil bila build membawa konfigurasi AI
/// (`--dart-define=AI_PROXY_URL=...` atau `GEMINI_API_KEY=...`). Tanpa itu
/// fitur selalu gagal saat dibuka, jadi pengguna rilis Play Store tidak boleh
/// melihat menunya.
///
/// Tes ini berlaku dua arah:
///   flutter test <file>                                  -> kartu harus hilang
///   flutter test <file> --dart-define=GEMINI_API_KEY=x   -> kartu harus ada
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'kartu Scan Ayat mengikuti status konfigurasi AI',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MenuScreen()));
      await tester.pump(const Duration(seconds: 1));

      // Menu lain tetap ada, memastikan layar benar-benar terender.
      expect(find.text("Al-Quran"), findsOneWidget);

      expect(
        find.text("Scan Ayat"),
        AiConfig.isConfigured ? findsOneWidget : findsNothing,
        reason: "AiConfig.isConfigured = ${AiConfig.isConfigured}",
      );
    },
  );
}
