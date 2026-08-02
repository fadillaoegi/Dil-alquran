import 'dart:math' as math;

import 'package:dilalquran/modules/qibla/controller/qibla_controller.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

const Color _shadowDeep = Color(0xff0c3f2a);
const Color _cardBorder = Color(0xff0d4e34);

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with SingleTickerProviderStateMixin {
  final QiblaController controller = Get.find<QiblaController>();
  bool _wasAligned = false;

  // Animasi ikon HP menyusuri lintasan angka 8 pada panduan kalibrasi.
  late final AnimationController _calibAnim;

  @override
  void initState() {
    super.initState();
    _calibAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _calibAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.secondary,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: ColorApp.primary,
        title: Text(
          "Arah Kiblat",
          style: primary700.copyWith(fontSize: 20.0, color: ColorApp.white),
        ),
        iconTheme: const IconThemeData(color: ColorApp.white),
        actions: [
          Obx(() {
            if (controller.status.value != QiblaStatus.ready) {
              return const SizedBox.shrink();
            }
            final low = controller.needsCalibration;
            return IconButton(
              tooltip: "Kalibrasi kompas",
              onPressed: controller.startCalibration,
              icon: Icon(
                low
                    ? Icons.warning_amber_rounded
                    : Icons.compass_calibration_rounded,
                color: low ? const Color(0xffffd54f) : ColorApp.white,
              ),
            );
          }),
        ],
      ),
      body: Stack(
        children: [
          Obx(() {
            switch (controller.status.value) {
          case QiblaStatus.loading:
            return const Center(
              child: CircularProgressIndicator(color: ColorApp.primary),
            );
          case QiblaStatus.locationOff:
            return _buildMessage(
              icon: Icons.location_off_rounded,
              title: "Lokasi tidak aktif",
              message:
                  "Aktifkan layanan lokasi (GPS) untuk menghitung arah kiblat.",
              actionLabel: "Buka Pengaturan Lokasi",
              onAction: () async {
                await controller.openLocationSettings();
              },
            );
          case QiblaStatus.permissionDenied:
            return _buildMessage(
              icon: Icons.gpp_maybe_rounded,
              title: "Izin lokasi ditolak",
              message:
                  "Aplikasi butuh izin lokasi untuk menentukan arah kiblat dari posisi Anda.",
              actionLabel: "Buka Pengaturan Aplikasi",
              onAction: () async {
                await controller.openAppSettings();
              },
            );
          case QiblaStatus.noSensor:
            return _buildMessage(
              icon: Icons.explore_off_rounded,
              title: "Kompas tidak tersedia",
              message:
                  "Perangkat ini sepertinya tidak memiliki sensor magnetometer, "
                  "sehingga arah kiblat tidak dapat ditunjukkan secara langsung.\n\n"
                  "Arah kiblat dari lokasi Anda: ${controller.qiblaBearing.value.toStringAsFixed(1)}° dari utara.",
              actionLabel: "Coba Lagi",
              onAction: controller.init,
            );
          case QiblaStatus.error:
            return _buildMessage(
              icon: Icons.error_outline_rounded,
              title: "Terjadi kesalahan",
              message: "Gagal mendapatkan lokasi. Silakan coba lagi.",
              actionLabel: "Coba Lagi",
              onAction: controller.init,
            );
          case QiblaStatus.ready:
            return _buildCompass();
        }
          }),
          // Overlay panduan kalibrasi kompas (figure-8).
          Obx(() => controller.calibrationVisible.value
              ? _buildCalibrationOverlay()
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildCompass() {
    return Obx(() {
      final heading = controller.heading.value;
      final aligned = controller.isAligned;

      // Getar sekali saat baru lurus ke kiblat.
      if (aligned && !_wasAligned) {
        HapticFeedback.mediumImpact();
      }
      _wasAligned = aligned;

      final headingRad = (heading ?? 0) * math.pi / 180.0;
      final qiblaRad = controller.qiblaBearing.value * math.pi / 180.0;

      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 32.0),
        child: Column(
          children: [
            _buildAlignedBanner(aligned),
            const SizedBox(height: 24.0),
            SizedBox(
              width: 300.0,
              height: 300.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Piringan kompas yang berputar mengikuti arah HP.
                  Transform.rotate(
                    angle: -headingRad,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(300.0, 300.0),
                          painter: _CompassRosePainter(),
                        ),
                        // Penanda Ka'bah menempel pada piringan di sudut kiblat.
                        Transform.rotate(
                          angle: qiblaRad,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: _buildKaabaMarker(aligned),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Penunjuk tetap (arah depan HP) di puncak.
                  const Positioned(
                    top: 0,
                    child: Icon(
                      Icons.arrow_drop_up_rounded,
                      size: 44.0,
                      color: ColorApp.primary,
                    ),
                  ),
                  _buildCenterHub(heading),
                ],
              ),
            ),
            const SizedBox(height: 28.0),
            _buildInfoCard(),
          ],
        ),
      );
    });
  }

  Widget _buildAlignedBanner(bool aligned) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: aligned ? ColorApp.primary : ColorApp.white,
        borderRadius: BorderRadius.circular(999.0),
        border: Border.all(color: _cardBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(color: _shadowDeep, offset: Offset(0, 4), blurRadius: 0),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            aligned ? Icons.check_circle_rounded : Icons.screen_rotation_rounded,
            size: 18.0,
            color: aligned ? ColorApp.white : ColorApp.primary,
          ),
          const SizedBox(width: 8.0),
          Flexible(
            child: Text(
              aligned
                  ? "Tepat menghadap kiblat"
                  : "Putar HP hingga penanda Ka'bah di puncak",
              textAlign: TextAlign.center,
              style: (aligned ? white700 : primary700).copyWith(fontSize: 13.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKaabaMarker(bool aligned) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: aligned ? ColorApp.primary : const Color(0xff1c1c1c),
            shape: BoxShape.circle,
            border: Border.all(color: ColorApp.white, width: 2.5),
            boxShadow: const [
              BoxShadow(color: _shadowDeep, offset: Offset(0, 3), blurRadius: 0),
            ],
          ),
          child: const Icon(Icons.mosque_rounded, size: 22.0, color: ColorApp.white),
        ),
        Container(
          width: 3.0,
          height: 26.0,
          color: aligned
              ? ColorApp.primary
              : const Color(0xff1c1c1c).withValues(alpha: 0.55),
        ),
      ],
    );
  }

  Widget _buildCenterHub(double? heading) {
    return Container(
      width: 74.0,
      height: 74.0,
      decoration: BoxDecoration(
        color: ColorApp.white,
        shape: BoxShape.circle,
        border: Border.all(color: _cardBorder, width: 2.0),
        boxShadow: const [
          BoxShadow(color: _shadowDeep, offset: Offset(0, 4), blurRadius: 0),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            heading == null ? "--" : "${heading.round()}°",
            style: primary700.copyWith(fontSize: 18.0, color: ColorApp.black),
          ),
          Text(
            "arah HP",
            style: primary400.copyWith(
              fontSize: 9.0,
              color: ColorApp.black.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: ColorApp.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: _cardBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(color: _shadowDeep, offset: Offset(0, 5), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(
            Icons.explore_rounded,
            "Arah kiblat",
            "${controller.qiblaBearing.value.toStringAsFixed(1)}° dari utara",
          ),
          const Divider(height: 22.0),
          _infoRow(
            Icons.straighten_rounded,
            "Jarak ke Makkah",
            "${controller.distanceKm.value.toStringAsFixed(0)} km",
          ),
          const Divider(height: 22.0),
          _accuracyRow(),
          if (controller.locationLabel.value.isNotEmpty) ...[
            const Divider(height: 22.0),
            _infoRow(
              Icons.location_on_rounded,
              "Lokasi Anda",
              controller.locationLabel.value,
            ),
          ],
        ],
      ),
    );
  }

  // Baris akurasi kompas dengan indikator warna + pintasan kalibrasi.
  Widget _accuracyRow() {
    return Obx(() {
      final level = controller.accuracyLevel;
      final Color c;
      switch (level) {
        case CompassAccuracy.high:
          c = ColorApp.primary;
          break;
        case CompassAccuracy.medium:
          c = const Color(0xffd98a1f);
          break;
        case CompassAccuracy.low:
          c = const Color(0xffc0392b);
          break;
        case CompassAccuracy.unknown:
          c = ColorApp.black.withValues(alpha: 0.45);
          break;
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.adjust_rounded, size: 20.0, color: ColorApp.primary),
          const SizedBox(width: 12.0),
          Expanded(
            child: GestureDetector(
              onTap: controller.startCalibration,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Akurasi kompas",
                    style: primary400.copyWith(
                      fontSize: 13.5,
                      color: ColorApp.black.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 9.0,
                        height: 9.0,
                        decoration:
                            BoxDecoration(color: c, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 7.0),
                      Text(
                        controller.accuracyLabel,
                        style: primary700.copyWith(fontSize: 14.0, color: c),
                      ),
                      if (level == CompassAccuracy.low ||
                          level == CompassAccuracy.medium) ...[
                        const SizedBox(width: 6.0),
                        Icon(
                          Icons.compass_calibration_rounded,
                          size: 16.0,
                          color: c,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  // Overlay panduan kalibrasi: gerakkan HP membentuk angka 8.
  Widget _buildCalibrationOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: ColorApp.white,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: _cardBorder, width: 2.0),
            boxShadow: const [
              BoxShadow(color: _shadowDeep, offset: Offset(0, 8), blurRadius: 0),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Kalibrasi Kompas",
                style: primary700.copyWith(
                  fontSize: 19.0,
                  color: ColorApp.black,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                "Gerakkan ponsel mengikuti pola angka 8 beberapa kali "
                "hingga akurasi meningkat.",
                textAlign: TextAlign.center,
                style: black400.copyWith(
                  fontSize: 13.0,
                  height: 1.5,
                  color: ColorApp.black.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20.0),
              // Animasi ikon HP menyusuri lintasan angka 8.
              SizedBox(
                width: 200.0,
                height: 130.0,
                child: AnimatedBuilder(
                  animation: _calibAnim,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _Figure8Painter(_calibAnim.value),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18.0),
              // Indikator akurasi live.
              Obx(() {
                final level = controller.accuracyLevel;
                final good = level == CompassAccuracy.high;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: (good ? ColorApp.primary : const Color(0xffd98a1f))
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999.0),
                    border: Border.all(
                      color: (good
                              ? ColorApp.primary
                              : const Color(0xffd98a1f))
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    "Akurasi: ${controller.accuracyLabel}",
                    style: primary700.copyWith(
                      fontSize: 12.5,
                      color:
                          good ? ColorApp.primary : const Color(0xffb8730f),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20.0),
              GestureDetector(
                onTap: controller.dismissCalibration,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xff11623f), Color(0xff2f9e69)],
                    ),
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: const [
                      BoxShadow(
                        color: _shadowDeep,
                        offset: Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    "Selesai",
                    style: white700.copyWith(fontSize: 15.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20.0, color: ColorApp.primary),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: primary400.copyWith(
                  fontSize: 13.5,
                  color: ColorApp.black.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                value,
                textAlign: TextAlign.left,
                style: primary700.copyWith(
                  fontSize: 14.0,
                  color: ColorApp.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64.0, color: ColorApp.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: primary700.copyWith(fontSize: 18.0, color: ColorApp.black),
            ),
            const SizedBox(height: 8.0),
            Text(
              message,
              textAlign: TextAlign.center,
              style: primary400.copyWith(
                fontSize: 14.0,
                color: ColorApp.black.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorApp.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.0),
                ),
              ),
              child: Text(
                actionLabel,
                style: white700.copyWith(fontSize: 14.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Piringan kompas: lingkaran, garis skala, dan huruf mata angin.
class _CompassRosePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Lingkaran dasar.
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = ColorApp.white,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _cardBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
    canvas.drawCircle(
      center,
      radius - 26,
      Paint()
        ..color = ColorApp.primary.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Garis skala tiap 15°, lebih tebal tiap 90°.
    for (int deg = 0; deg < 360; deg += 15) {
      final isMajor = deg % 90 == 0;
      final isMid = deg % 45 == 0;
      final angle = (deg - 90) * math.pi / 180.0;
      final outer = radius - 4;
      final inner = radius - (isMajor ? 20 : (isMid ? 15 : 9));
      final p1 = center + Offset(math.cos(angle) * outer, math.sin(angle) * outer);
      final p2 = center + Offset(math.cos(angle) * inner, math.sin(angle) * inner);
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = isMajor
              ? ColorApp.primary
              : ColorApp.primary.withValues(alpha: 0.4)
          ..strokeWidth = isMajor ? 3.0 : 1.5,
      );
    }

    // Huruf mata angin.
    const labels = {0: "N", 90: "E", 180: "S", 270: "W"};
    labels.forEach((deg, text) {
      final angle = (deg - 90) * math.pi / 180.0;
      final r = radius - 40;
      final pos = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: deg == 0 ? const Color(0xffb3261e) : ColorApp.primary,
            fontSize: 20.0,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Lintasan angka 8 + ikon HP bergerak untuk panduan kalibrasi.
class _Figure8Painter extends CustomPainter {
  _Figure8Painter(this.t);

  // Progres animasi 0..1.
  final double t;

  Offset _point(double u, Size size) {
    final a = size.width / 2 - 18;
    final b = size.height / 2 - 18;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final ang = u * 2 * math.pi;
    // Lemniscate Gerono (angka 8 horizontal).
    final x = cx + a * math.sin(ang);
    final y = cy + b * math.sin(ang) * math.cos(ang);
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Lintasan angka 8 samar.
    final path = Path();
    for (int i = 0; i <= 120; i++) {
      final p = _point(i / 120, size);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = ColorApp.primary.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );

    // Penanda HP yang bergerak.
    final pos = _point(t, size);
    canvas.drawCircle(
      pos + const Offset(0, 3),
      16.0,
      Paint()..color = _shadowDeep,
    );
    canvas.drawCircle(pos, 16.0, Paint()..color = ColorApp.primary);

    const icon = Icons.smartphone_rounded;
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: 19.0,
          color: ColorApp.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _Figure8Painter oldDelegate) =>
      oldDelegate.t != t;
}
