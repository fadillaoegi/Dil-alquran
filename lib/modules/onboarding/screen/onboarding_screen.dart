import 'dart:math';

import 'package:dilalquran/modules/onboarding/controller/onboarding_controller.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:dilalquran/themes/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final OnboardingController controller = Get.find<OnboardingController>();

  // Controller animasi ambient (halo berdenyut + ikon melayang), berulang.
  late final AnimationController _ambient;

  @override
  void initState() {
    super.initState();
    controller.totalPages = _pages.length;
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  // Posisi scroll terkini PageView (0.0 .. totalPages-1), aman sebelum layout.
  double get _page {
    if (controller.pageController.hasClients &&
        controller.pageController.position.haveDimensions) {
      return controller.pageController.page ?? 0.0;
    }
    return 0.0;
  }

  Color _lerpColor(List<Color> colors, double t) {
    final clamped = t.clamp(0.0, (colors.length - 1).toDouble());
    final i = clamped.floor();
    final next = (i + 1).clamp(0, colors.length - 1);
    return Color.lerp(colors[i], colors[next], clamped - i)!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient yang bergeser warna mengikuti geseran halaman.
          AnimatedBuilder(
            animation: controller.pageController,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _lerpColor(_topColors, _page),
                      _lerpColor(_bottomColors, _page),
                    ],
                  ),
                ),
              );
            },
          ),
          // Orb dekoratif melayang halus di latar.
          _buildFloatingOrbs(),
          SafeArea(
            child: Column(
              children: [
                // Tombol Lewati (memudar di halaman terakhir).
                Align(
                  alignment: Alignment.topRight,
                  child: Obx(
                    () => AnimatedOpacity(
                      opacity: controller.isLastPage ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 250),
                      child: TextButton(
                        onPressed:
                            controller.isLastPage ? null : controller.finish,
                        child: Text(
                          "Lewati",
                          style: white500.copyWith(
                            fontSize: 14.0,
                            color: ColorApp.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: controller.pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      controller.onPageChanged(index);
                      HapticFeedback.selectionClick();
                    },
                    itemBuilder: (context, index) =>
                        _buildPage(_pages[index], index),
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingOrbs() {
    return AnimatedBuilder(
      animation: _ambient,
      builder: (context, _) {
        final t = _ambient.value * 2 * pi;
        return Stack(
          children: [
            Positioned(
              top: 80 + sin(t) * 14,
              right: -40 + cos(t) * 10,
              child: _orb(160, 0.06),
            ),
            Positioned(
              bottom: 120 + cos(t) * 16,
              left: -50 + sin(t) * 12,
              child: _orb(200, 0.05),
            ),
          ],
        );
      },
    );
  }

  Widget _orb(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorApp.white.withValues(alpha: opacity),
      ),
    );
  }

  Widget _buildPage(_OnbData data, int index) {
    return AnimatedBuilder(
      animation: controller.pageController,
      builder: (context, _) {
        final delta = _page - index;
        final centered = (1 - delta.abs()).clamp(0.0, 1.0);

        // Konten dipusatkan, namun bisa di-scroll bila layar terlalu pendek
        // sehingga tidak pernah overflow.
        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIllustration(data, delta, centered),
                    const SizedBox(height: 48.0),
              // Teks bergerak dengan parallax lebih lembut dari ilustrasi.
              Transform.translate(
                offset: Offset(-delta * 40.0, 0),
                child: Opacity(
                  opacity: centered,
                  child: Column(
                    children: [
                      Text(
                        data.title,
                        textAlign: TextAlign.center,
                        style: (data.useLottie ? dancing700 : white700).copyWith(
                          fontSize: data.useLottie ? 34.0 : 26.0,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        data.subtitle,
                        textAlign: TextAlign.center,
                        style: white400.copyWith(
                          fontSize: 15.0,
                          height: 1.5,
                          color: ColorApp.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIllustration(_OnbData data, double delta, double centered) {
    // Ukuran ilustrasi mengikuti lebar layar agar tidak overflow di ponsel kecil.
    final side = (context.screenWidth - 72.0).clamp(200.0, 260.0);
    return Transform.translate(
      // Ilustrasi bergerak lebih jauh -> efek parallax berlapis.
      offset: Offset(-delta * 80.0, 0),
      child: Transform.scale(
        scale: 0.75 + 0.25 * centered,
        child: Opacity(
          opacity: centered,
          child: SizedBox(
            width: side,
            height: side,
            child: AnimatedBuilder(
              animation: _ambient,
              builder: (context, _) {
                final t = _ambient.value * 2 * pi;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Cincin luar berdenyut.
                    Transform.scale(
                      scale: 1 + 0.06 * sin(t),
                      child: Container(
                        width: 240.0,
                        height: 240.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ColorApp.white.withValues(alpha: 0.12),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    // Halo cahaya di belakang ikon.
                    Container(
                      width: 190.0,
                      height: 190.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            ColorApp.white.withValues(alpha: 0.30),
                            ColorApp.white.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                      child: Center(
                        child: data.useLottie
                            ? Lottie.asset(
                                "assets/lotties/animationReadQuran.json",
                                width: 150.0,
                                height: 150.0,
                                fit: BoxFit.contain,
                              )
                            : Icon(
                                data.icon,
                                size: 88.0,
                                color: ColorApp.white,
                              ),
                      ),
                    ),
                    // Ikon-ikon kecil melayang naik-turun.
                    ...List.generate(data.floatingIcons.length, (i) {
                      final bob = sin(t + i * pi) * 10.0;
                      return Align(
                        alignment: _floatAlignments[i % _floatAlignments.length],
                        child: Transform.translate(
                          offset: Offset(0, bob),
                          child: _floatChip(data.floatingIcons[i]),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _floatChip(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: ColorApp.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: ColorApp.white.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, color: ColorApp.white, size: 22.0),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 40.0),
      child: Column(
        children: [
          // Indikator halaman animatif.
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(controller.totalPages, (i) {
                final active = controller.currentPage.value == i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  height: 8.0,
                  width: active ? 26.0 : 8.0,
                  decoration: BoxDecoration(
                    color: active
                        ? ColorApp.white
                        : ColorApp.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 28.0),
          // Tombol CTA yang labelnya bermorf di halaman terakhir.
          SizedBox(
            width: double.infinity,
            height: 56.0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ColorApp.accent, ColorApp.primary],
                ),
                borderRadius: BorderRadius.circular(18.0),
                boxShadow: [
                  BoxShadow(
                    color: ColorApp.accent.withValues(alpha: 0.4),
                    blurRadius: 18.0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18.0),
                  onTap: controller.next,
                  child: Center(
                    child: Obx(
                      () => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: Row(
                          key: ValueKey(controller.isLastPage),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              controller.isLastPage
                                  ? "Mulai Sekarang"
                                  : "Lanjut",
                              style: white700.copyWith(fontSize: 16.0),
                            ),
                            const SizedBox(width: 8.0),
                            Icon(
                              controller.isLastPage
                                  ? Icons.rocket_launch_rounded
                                  : Icons.arrow_forward_rounded,
                              color: ColorApp.white,
                              size: 20.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Anchor posisi ikon melayang mengelilingi halo.
const List<Alignment> _floatAlignments = [
  Alignment(0.95, -0.75),
  Alignment(-0.95, 0.8),
  Alignment(0.9, 0.85),
];

// Warna gradient latar per halaman (di-lerp saat digeser).
const List<Color> _topColors = [
  ColorApp.primary,
  Color(0xff0d4e34),
  ColorApp.primary,
  Color(0xff0c3f2a),
];

const List<Color> _bottomColors = [
  ColorApp.black,
  ColorApp.accent,
  Color(0xff0a3d29),
  ColorApp.accent,
];

class _OnbData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<IconData> floatingIcons;
  final bool useLottie;

  const _OnbData({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.floatingIcons = const [],
    this.useLottie = false,
  });
}

const List<_OnbData> _pages = [
  _OnbData(
    title: "Selamat Datang di\nDil ~ AlQuran",
    subtitle:
        "Sahabat ibadah harianmu — baca, dengarkan, dan tepat waktu dalam satu aplikasi.",
    icon: Icons.auto_stories_rounded,
    floatingIcons: [Icons.star_rounded, Icons.brightness_2_rounded],
    useLottie: true,
  ),
  _OnbData(
    title: "Baca & Dengar Al-Quran",
    subtitle:
        "Jelajahi per Surah atau Juz, lengkap dengan terjemahan dan murottal audio dari qari.",
    icon: Icons.menu_book_rounded,
    floatingIcons: [Icons.headphones_rounded, Icons.graphic_eq_rounded],
  ),
  _OnbData(
    title: "Kumpulan Doa Harian",
    subtitle:
        "Doa sehari-hari lengkap dengan tulisan Arab, latin, dan artinya — mudah dicari.",
    icon: Icons.pan_tool_rounded,
    floatingIcons: [Icons.favorite_rounded, Icons.auto_awesome_rounded],
  ),
  _OnbData(
    title: "Jadwal Sholat & Adzan",
    subtitle:
        "Waktu sholat akurat sesuai lokasimu, dengan pengingat adzan agar tak terlewat.",
    icon: Icons.access_time_filled_rounded,
    floatingIcons: [Icons.notifications_active_rounded, Icons.location_on_rounded],
  ),
];
