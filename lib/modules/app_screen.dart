import 'package:dilalquran/modules/audio/audio_controller.dart';
import 'package:dilalquran/modules/download/download_controller.dart';
import 'package:dilalquran/routes/list_get_pages.dart';
import 'package:dilalquran/routes/route.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/responsive.dart';
import 'package:dilalquran/widgets/app_notify.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppScreen extends StatelessWidget {
  const AppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialRoute: RouteScreen.splash,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: appMessengerKey,
      getPages: getPages,
      initialBinding: BindingsBuilder(() {
        Get.put(AudioController(), permanent: true);
        Get.put(DownloadController(), permanent: true);
      }),
      // Lapisan responsive global untuk SEMUA screen.
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final fullWidth = constraints.maxWidth;
            // Batasi lebar konten di layar besar (tablet/desktop/web).
            final contentWidth =
                fullWidth > kMaxContentWidth ? kMaxContentWidth : fullWidth;

            final mediaQuery = MediaQuery.of(context);

            // Batasi penskalaan font sistem agar layout tidak pecah pada
            // pengaturan ukuran teks yang sangat besar/kecil.
            final clampedTextScaler = mediaQuery.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.2,
            );

            return ColoredBox(
              color: ColorApp.black,
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: contentWidth,
                  height: constraints.maxHeight,
                  // Selaraskan MediaQuery.size dengan lebar terbatas agar
                  // widget yang mengandalkan lebar layar tidak overflow.
                  child: MediaQuery(
                    data: mediaQuery.copyWith(
                      size: Size(contentWidth, mediaQuery.size.height),
                      textScaler: clampedTextScaler,
                    ),
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
