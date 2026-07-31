import 'package:dilalquran/routes/route.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:dilalquran/widgets/card_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  String? _shalatLocationLabel;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _loadShalatLocation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadShalatLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final kota = (prefs.getString('saved_kabkota') ?? "").trim();
    final provinsi = (prefs.getString('saved_provinsi') ?? "").trim();

    String? label;
    if (kota.isNotEmpty && provinsi.isNotEmpty) {
      label = "$kota, $provinsi";
    } else if (kota.isNotEmpty) {
      label = kota;
    } else if (provinsi.isNotEmpty) {
      label = provinsi;
    }

    if (!mounted) return;
    setState(() => _shalatLocationLabel = label);
  }

  Animation<double> _interval(double begin, double end) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: Curves.easeOut),
    );
  }

  String get _todayLabel {
    const days = [
      "Senin",
      "Selasa",
      "Rabu",
      "Kamis",
      "Jumat",
      "Sabtu",
      "Minggu",
    ];
    const months = [
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember",
    ];
    final now = DateTime.now();
    return "${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.secondary,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12.0),
            _FadeSlideIn(
              animation: _interval(0.2, 0.65),
              child: CardMenu(
                title: "Al-Quran",
                subtitle: "Baca Al-Quran dan terjemahan",
                icon: Icons.menu_book_rounded,
                gradientColors: const [
                  Color(0xff0d4e34),
                  ColorApp.primary,
                  Color(0xff8ccf72),
                ],
                onTap: () {
                  Get.toNamed(RouteScreen.home);
                },
              ),
            ),
            _FadeSlideIn(
              animation: _interval(0.32, 0.77),
              child: CardMenu(
                title: "Hafizh Qur'an",
                subtitle: "Hafalan & muraja'ah",
                icon: Icons.psychology_rounded,
                gradientColors: const [
                  Color(0xff10553a),
                  Color(0xff34b57e),
                ],
                onTap: () {
                  Get.toNamed(RouteScreen.hafizh);
                },
              ),
            ),
            _FadeSlideIn(
              animation: _interval(0.44, 0.89),
              child: CardMenu(
                title: "Doa Umum",
                subtitle: "Kumpulan doa sehari-hari",
                icon: Icons.pan_tool_rounded,
                gradientColors: const [
                  Color(0xff143a2a),
                  ColorApp.primary,
                ],
                onTap: () {
                  Get.toNamed(RouteScreen.doa);
                },
              ),
            ),
            _FadeSlideIn(
              animation: _interval(0.56, 0.93),
              child: CardMenu(
                title: "Dzikir",
                subtitle: "Dzikir harian & setelah ibadah",
                icon: Icons.brightness_5_rounded,
                gradientColors: const [
                  Color(0xff0f4630),
                  ColorApp.primary,
                  Color(0xff6bc58f),
                ],
                onTap: () {
                  Get.toNamed(RouteScreen.dzikir);
                },
              ),
            ),
            _FadeSlideIn(
              animation: _interval(0.68, 1.0),
              child: CardMenu(
                title: "Jadwal Sholat",
                subtitle: "Waktu sholat akurat",
                infoLabel: _shalatLocationLabel == null
                    ? "Lokasi belum diatur"
                    : "Lokasi: $_shalatLocationLabel",
                icon: Icons.access_time_filled_rounded,
                gradientColors: const [
                  Color(0xff0c3f2a),
                  ColorApp.primary,
                ],
                onTap: () async {
                  // Muat ulang label lokasi setelah kembali, agar ikut berubah
                  // bila lokasi diganti di halaman Jadwal Sholat.
                  await Get.toNamed(RouteScreen.shalat);
                  _loadShalatLocation();
                },
              ),
            ),
            _FadeSlideIn(
              animation: _interval(0.78, 1.0),
              child: CardMenu(
                title: "Arah Kiblat",
                subtitle: "Kompas penunjuk arah kiblat",
                icon: Icons.explore_rounded,
                gradientColors: const [
                  Color(0xff0d4e34),
                  ColorApp.primary,
                  Color(0xff6bc58f),
                ],
                onTap: () {
                  Get.toNamed(RouteScreen.qibla);
                },
              ),
            ),
            const SizedBox(height: 28.0),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final topPadding = MediaQuery.paddingOf(context).top;
    return _FadeSlideIn(
      animation: _interval(0.0, 0.5),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(24.0, topPadding + 24.0, 24.0, 30.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff0d4e34), ColorApp.primary],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32.0),
            bottomRight: Radius.circular(32.0),
          ),
          boxShadow: [
            BoxShadow(
              color: ColorApp.primary.withValues(alpha: 0.3),
              blurRadius: 16.0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12.0,
              top: -8.0,
              child: Icon(
                Icons.mosque_rounded,
                size: 96.0,
                color: ColorApp.white.withValues(alpha: 0.12),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14.0,
                      color: ColorApp.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      _todayLabel,
                      style: white400.copyWith(
                        fontSize: 12.5,
                        color: ColorApp.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14.0),
                Text(
                  "Assalamualaikum",
                  style: white700.copyWith(fontSize: 26.0),
                ),
                const SizedBox(height: 6.0),
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 15.0,
                      color: ColorApp.white.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      "Mau ibadah apa hari ini?",
                      style: white400.copyWith(
                        fontSize: 14.0,
                        color: ColorApp.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - animation.value) * 24.0),
          child: child,
        ),
        child: child,
      ),
    );
  }
}
