import 'package:dilalquran/modules/data/models/juz_model.dart';
import 'package:dilalquran/modules/data/models/surah_model.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';

const _surfaceBorderColor = Color(0xFFD3D3D3);
const _surfaceBaseShadowColor = Color(0xFFCFCFCF);

class ListSurahAyat extends StatelessWidget {
  const ListSurahAyat({
    super.key,
    required this.surah,
    required this.onTap,
    this.trailing,
  });

  final Surah surah;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final nameLatin = surah.namaLatin ?? "";
    final meaning = surah.arti ?? "";
    final arabicName = surah.nama ?? "";
    final versesCount = surah.jumlahAyat ?? 0;
    final revelation = surah.tempatTurun ?? "Mekah";

    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 18.0),
      child: _PressableScale(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 10,
              bottom: -10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _surfaceBaseShadowColor,
                  borderRadius: BorderRadius.circular(18.0),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16.0),
                onTap: onTap,
                splashColor: ColorApp.primary.withValues(alpha: 0.05),
                highlightColor: ColorApp.primary.withValues(alpha: 0.02),
                child: Ink(
                  decoration: BoxDecoration(
                    color: ColorApp.white,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: _surfaceBorderColor,
                      width: 1.25,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ColorApp.primary.withValues(alpha: 0.04),
                        offset: const Offset(0, 2),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: ColorApp.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ColorApp.primary.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "${surah.nomor}",
                              style: const TextStyle(
                                color: ColorApp.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nameLatin,
                                style: black700.copyWith(fontSize: 15.0),
                              ),
                              const SizedBox(height: 4.0),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      meaning,
                                      style: black400.copyWith(
                                        fontSize: 11.5,
                                        color: ColorApp.black
                                            .withValues(alpha: 0.6),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 6.0),
                                    width: 3.5,
                                    height: 3.5,
                                    decoration: BoxDecoration(
                                      color:
                                          ColorApp.black.withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Text(
                                    "$versesCount Ayat",
                                    style: primary600.copyWith(
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              arabicName,
                              style: const TextStyle(
                                color: ColorApp.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 22.0,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 3.0,
                              ),
                              decoration: BoxDecoration(
                                color: ColorApp.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Text(
                                revelation,
                                style: const TextStyle(
                                  color: ColorApp.primary,
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: 4.0),
                          trailing!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ListJuzCard extends StatelessWidget {
  const ListJuzCard({
    super.key,
    required this.juz,
    required this.onTap,
    this.trailing,
  });

  final JuzSummary juz;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 18.0),
      child: _PressableScale(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 10,
              bottom: -10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _surfaceBaseShadowColor,
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18.0),
                onTap: onTap,
                child: Ink(
                  decoration: BoxDecoration(
                    color: ColorApp.white,
                    borderRadius: BorderRadius.circular(18.0),
                    border: Border.all(
                      color: _surfaceBorderColor,
                      width: 1.25,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ColorApp.primary.withValues(alpha: 0.04),
                        offset: const Offset(0, 2),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: ColorApp.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14.0),
                            border: Border.all(
                              color: ColorApp.primary.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "${juz.number}",
                              style: primary700.copyWith(fontSize: 18.0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Juz ${juz.number}",
                                style: black700.copyWith(fontSize: 16.0),
                              ),
                              const SizedBox(height: 3.0),
                              Text(
                                "${juz.startSurahName} - ${juz.endSurahName}",
                                style: black500.copyWith(
                                  fontSize: 12.0,
                                  color: ColorApp.black.withValues(alpha: 0.68),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${juz.totalAyat} ayat",
                              style: primary600.copyWith(fontSize: 11.0),
                            ),
                            const SizedBox(height: 6.0),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16.0,
                              color: ColorApp.primary.withValues(alpha: 0.85),
                            ),
                          ],
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: 4.0),
                          trailing!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.child});

  final Widget child;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted) return;
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
