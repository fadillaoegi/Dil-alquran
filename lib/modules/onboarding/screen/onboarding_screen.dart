import 'dart:math';

import 'package:dilalquran/modules/onboarding/controller/onboarding_controller.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:dilalquran/themes/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

// Palet chunky 3D (kreate.gg): permukaan putih dengan hard offset shadow
// (blurRadius 0), border tegas, dan sudut membulat.
const Color _chunkyShadow = Color(0xffbcd9cb); // bayangan blok hijau muda
const Color _chunkyShadowDeep = Color(0xff0a3d29); // bayangan blok hijau tua
const Color _chunkyBorder = Color(0xffd3e4da);

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

  // Status tekan tombol CTA untuk efek chunky (blok turun & bayangan mengecil).
  bool _ctaPressed = false;

  void _setCtaPressed(bool value) {
    if (!mounted) return;
    if (_ctaPressed != value) setState(() => _ctaPressed = value);
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.secondary,
      body: Stack(
        children: [
          // Latar terang bergradasi lembut agar tetap punya kedalaman.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [ColorApp.white, ColorApp.secondary],
              ),
            ),
            child: SizedBox.expand(),
          ),
          // Bentuk dekoratif chunky melayang halus di latar.
          _buildFloatingBlocks(),
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
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                        child: _SkipChip(
                          onTap: controller.isLastPage ? null : controller.finish,
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

  Widget _buildFloatingBlocks() {
    return AnimatedBuilder(
      animation: _ambient,
      builder: (context, _) {
        final t = _ambient.value * 2 * pi;
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                top: 90 + sin(t) * 14,
                right: -30 + cos(t) * 10,
                child: _decoBlock(120, 26, 0.06),
              ),
              Positioned(
                bottom: 140 + cos(t) * 16,
                left: -34 + sin(t) * 12,
                child: _decoBlock(150, 32, 0.05),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _decoBlock(double size, double radius, double opacity) {
    return Transform.rotate(
      angle: 0.15,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: ColorApp.primary.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(radius),
        ),
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
                    const SizedBox(height: 52.0),
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
                              style: black700.copyWith(
                                fontSize: data.useLottie ? 30.0 : 26.0,
                                height: 1.2,
                                color: ColorApp.black,
                              ),
                            ),
                            const SizedBox(height: 14.0),
                            Text(
                              data.subtitle,
                              textAlign: TextAlign.center,
                              style: black400.copyWith(
                                fontSize: 15.0,
                                height: 1.5,
                                color: ColorApp.black.withValues(alpha: 0.6),
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
    final side = (context.screenWidth - 72.0).clamp(220.0, 280.0);
    return Transform.translate(
      // Ilustrasi bergerak lebih jauh -> efek parallax berlapis.
      offset: Offset(-delta * 80.0, 0),
      child: Transform.scale(
        scale: 0.78 + 0.22 * centered,
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
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Kartu chunky utama: blok putih dengan hard offset shadow.
                    Transform.translate(
                      offset: Offset(0, sin(t) * 4),
                      child: Container(
                        width: 208.0,
                        height: 208.0,
                        decoration: BoxDecoration(
                          color: ColorApp.white,
                          borderRadius: BorderRadius.circular(40.0),
                          border: Border.all(color: _chunkyBorder, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: _chunkyShadow,
                              offset: Offset(0, 12),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: data.useLottie
                              ? Lottie.asset(
                                  "assets/lotties/animationReadQuran.json",
                                  width: 150.0,
                                  height: 150.0,
                                  fit: BoxFit.contain,
                                )
                              : Container(
                                  padding: const EdgeInsets.all(26.0),
                                  decoration: BoxDecoration(
                                    color:
                                        ColorApp.primary.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(28.0),
                                  ),
                                  child: Icon(
                                    data.icon,
                                    size: 76.0,
                                    color: ColorApp.primary,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    // Chip ikon kecil chunky yang melayang naik-turun.
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
        color: ColorApp.white,
        shape: BoxShape.circle,
        border: Border.all(color: _chunkyBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: _chunkyShadow,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Icon(icon, color: ColorApp.primary, size: 22.0),
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
                  height: 9.0,
                  width: active ? 28.0 : 9.0,
                  decoration: BoxDecoration(
                    color: active
                        ? ColorApp.primary
                        : ColorApp.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(5.0),
                    border: Border.all(
                      color: active
                          ? ColorApp.primary
                          : ColorApp.primary.withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 28.0),
          // Tombol CTA chunky yang labelnya bermorf di halaman terakhir.
          Listener(
            onPointerDown: (_) => _setCtaPressed(true),
            onPointerUp: (_) => _setCtaPressed(false),
            onPointerCancel: (_) => _setCtaPressed(false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              width: double.infinity,
              height: 58.0,
              transform:
                  Matrix4.translationValues(0, _ctaPressed ? 4.0 : 0.0, 0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [ColorApp.accent, ColorApp.primary],
                ),
                borderRadius: BorderRadius.circular(20.0),
                // Hard offset shadow — chunky 3D; mengempis saat ditekan.
                boxShadow: [
                  BoxShadow(
                    color: _chunkyShadowDeep,
                    offset: Offset(0, _ctaPressed ? 2.0 : 7.0),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20.0),
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

// Chip "Lewati" bergaya chunky mini.
class _SkipChip extends StatelessWidget {
  const _SkipChip({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999.0),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: ColorApp.white,
            borderRadius: BorderRadius.circular(999.0),
            border: Border.all(color: _chunkyBorder, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: _chunkyShadow,
                offset: Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Text(
            "Lewati",
            style: black500.copyWith(
              fontSize: 13.0,
              color: ColorApp.black.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

// Anchor posisi ikon melayang mengelilingi kartu ilustrasi.
const List<Alignment> _floatAlignments = [
  Alignment(1.02, -0.72),
  Alignment(-1.02, 0.78),
  Alignment(0.95, 0.9),
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
