import 'package:dilalquran/themes/colors.dart';
import 'package:flutter/material.dart';

// Messenger global agar snackbar bisa ditampilkan dari mana saja (termasuk
// controller/di luar konteks widget) tanpa bergantung pada resolusi Overlay
// milik GetX yang tidak stabil pada sebagian versi Flutter.
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void showAppSnackbar(
  String title,
  String message, {
  bool isError = false,
}) {
  final messenger = appMessengerKey.currentState;
  if (messenger == null) return;

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: ColorApp.white,
                fontWeight: FontWeight.w700,
                fontSize: 14.0,
              ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 2.0),
              Text(
                message,
                style: TextStyle(
                  color: ColorApp.white.withValues(alpha: 0.9),
                  fontSize: 12.5,
                ),
              ),
            ],
          ],
        ),
        backgroundColor: isError ? ColorApp.black : ColorApp.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16.0),
        duration: const Duration(seconds: 3),
      ),
    );
}
