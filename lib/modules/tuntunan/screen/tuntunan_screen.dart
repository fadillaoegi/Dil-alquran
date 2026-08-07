import 'dart:async';

import 'package:dilalquran/modules/tuntunan/model/tuntunan_model.dart';
import 'package:dilalquran/modules/tuntunan/widget/prayer_pose_animation.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

const Color _shadowDeep = Color(0xff0c3f2a);
const Color _cardBorder = Color(0xff0d4e34);

class TuntunanScreen extends StatefulWidget {
  const TuntunanScreen({super.key});

  @override
  State<TuntunanScreen> createState() => _TuntunanScreenState();
}

class _TuntunanScreenState extends State<TuntunanScreen> {
  final PageController _pageController = PageController();

  int _sectionIndex = 0;
  int _stepIndex = 0;

  // Pemutaran otomatis antar langkah.
  Timer? _autoPlay;
  bool get _isPlaying => _autoPlay != null;

  List<TuntunanStep> get _steps => tuntunanSections[_sectionIndex].steps;

  @override
  void dispose() {
    _autoPlay?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _selectSection(int index) {
    if (_sectionIndex == index) return;
    _stopAutoPlay();
    setState(() {
      _sectionIndex = index;
      _stepIndex = 0;
    });
    _pageController.jumpToPage(0);
    HapticFeedback.selectionClick();
  }

  void _goTo(int index) {
    if (index < 0 || index >= _steps.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleAutoPlay() {
    if (_isPlaying) {
      _stopAutoPlay();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _autoPlay = Timer.periodic(const Duration(seconds: 5), (_) {
        if (_stepIndex >= _steps.length - 1) {
          _stopAutoPlay();
          return;
        }
        _goTo(_stepIndex + 1);
      });
    });
  }

  void _stopAutoPlay() {
    if (_autoPlay == null) return;
    _autoPlay?.cancel();
    setState(() => _autoPlay = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.secondary,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: ColorApp.primary,
        iconTheme: const IconThemeData(color: ColorApp.white),
        title: Text(
          "Tuntunan Sholat",
          style: primary700.copyWith(fontSize: 20.0, color: ColorApp.white),
        ),
        actions: [
          IconButton(
            tooltip: _isPlaying ? "Hentikan otomatis" : "Putar otomatis",
            onPressed: _toggleAutoPlay,
            icon: Icon(
              _isPlaying ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
              color: ColorApp.white,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSectionTabs(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _steps.length,
              onPageChanged: (i) {
                setState(() => _stepIndex = i);
                HapticFeedback.selectionClick();
              },
              itemBuilder: (context, index) => _buildStepPage(_steps[index]),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // Pemilih tahap: Wudhu / Shalat.
  Widget _buildSectionTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 6.0),
      child: Row(
        children: List.generate(tuntunanSections.length, (i) {
          final active = i == _sectionIndex;
          final section = tuntunanSections[i];
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == 0 ? 10.0 : 0.0),
              child: GestureDetector(
                onTap: () => _selectSection(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  decoration: BoxDecoration(
                    gradient: active
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xff11623f), Color(0xff2f9e69)],
                          )
                        : null,
                    color: active ? null : ColorApp.white,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: active
                          ? _cardBorder
                          : ColorApp.primary.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: active
                            ? _shadowDeep
                            : ColorApp.primary.withValues(alpha: 0.18),
                        offset: const Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        i == 0
                            ? Icons.water_drop_rounded
                            : Icons.self_improvement_rounded,
                        size: 17.0,
                        color: active ? ColorApp.white : ColorApp.primary,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        section.name,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: active ? ColorApp.white : ColorApp.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepPage(TuntunanStep step) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStage(step),
          const SizedBox(height: 18.0),
          _buildTitleCard(step),
          if (step.hasReading) ...[
            const SizedBox(height: 14.0),
            _buildReadingCard(step),
          ],
        ],
      ),
    );
  }

  // Panggung animasi figur.
  Widget _buildStage(TuntunanStep step) {
    return Container(
      width: double.infinity,
      height: 268.0,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xffe8f4ed), Color(0xfff4f9f6)],
        ),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: _cardBorder, width: 2.0),
        boxShadow: const [
          BoxShadow(color: _shadowDeep, offset: Offset(0, 7), blurRadius: 0),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.0),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 10.0),
                child: PrayerPoseAnimation(pose: step.pose),
              ),
            ),
            // Nomor langkah.
            Positioned(
              top: 12.0,
              left: 12.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: ColorApp.white,
                  borderRadius: BorderRadius.circular(999.0),
                  border: Border.all(
                    color: ColorApp.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  "Langkah ${_stepIndex + 1}/${_steps.length}",
                  style: primary700.copyWith(fontSize: 11.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleCard(TuntunanStep step) {
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
          Row(
            children: [
              Container(
                width: 34.0,
                height: 34.0,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff11623f), Color(0xff2f9e69)],
                  ),
                  borderRadius: BorderRadius.circular(11.0),
                ),
                child: Text(
                  "${_stepIndex + 1}",
                  style: white700.copyWith(fontSize: 14.0),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  step.title,
                  style: primary700.copyWith(
                    fontSize: 17.0,
                    color: ColorApp.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            step.description,
            style: black400.copyWith(
              fontSize: 13.5,
              height: 1.55,
              color: ColorApp.black.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingCard(TuntunanStep step) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7.0),
                decoration: BoxDecoration(
                  color: ColorApp.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 16.0,
                  color: ColorApp.primary,
                ),
              ),
              const SizedBox(width: 10.0),
              Text("Bacaan", style: primary700.copyWith(fontSize: 14.0)),
            ],
          ),
          const SizedBox(height: 16.0),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              step.arabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 24.0,
                height: 2.0,
                fontWeight: FontWeight.w700,
                color: ColorApp.black,
              ),
            ),
          ),
          if (step.latin.isNotEmpty) ...[
            const SizedBox(height: 16.0),
            Text(
              step.latin,
              style: const TextStyle(
                color: ColorApp.primary,
                fontSize: 14.0,
                fontStyle: FontStyle.italic,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (step.translation.isNotEmpty) ...[
            const SizedBox(height: 14.0),
            const Divider(height: 1.0),
            const SizedBox(height: 14.0),
            Text(
              step.translation,
              style: black400.copyWith(
                fontSize: 13.5,
                height: 1.6,
                color: ColorApp.black.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isFirst = _stepIndex == 0;
    final isLast = _stepIndex == _steps.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 18.0),
      decoration: BoxDecoration(
        color: ColorApp.white,
        border: Border(
          top: BorderSide(
            color: ColorApp.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indikator progres.
          Row(
            children: List.generate(_steps.length, (i) {
              final done = i <= _stepIndex;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  height: 6.0,
                  margin: EdgeInsets.only(
                    right: i == _steps.length - 1 ? 0.0 : 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: done
                        ? ColorApp.primary
                        : ColorApp.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999.0),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14.0),
          Row(
            children: [
              _navButton(
                icon: Icons.arrow_back_rounded,
                label: "Sebelumnya",
                enabled: !isFirst,
                primary: false,
                onTap: () => _goTo(_stepIndex - 1),
              ),
              const SizedBox(width: 12.0),
              _navButton(
                icon: isLast
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_rounded,
                label: isLast ? "Selesai" : "Berikutnya",
                enabled: true,
                primary: true,
                onTap: () {
                  if (isLast) {
                    if (_sectionIndex == 0) {
                      // Lanjut dari tahap wudhu ke tahap shalat.
                      _selectSection(1);
                    } else {
                      Get.back();
                    }
                  } else {
                    _goTo(_stepIndex + 1);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required bool primary,
    required VoidCallback onTap,
  }) {
    final fg = primary
        ? ColorApp.white
        : (enabled ? ColorApp.primary : ColorApp.black.withValues(alpha: 0.3));
    return Expanded(
      child: Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            decoration: BoxDecoration(
              gradient: primary
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xff11623f), Color(0xff2f9e69)],
                    )
                  : null,
              color: primary ? null : ColorApp.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: primary
                    ? _cardBorder
                    : ColorApp.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary
                      ? _shadowDeep
                      : ColorApp.primary.withValues(alpha: 0.18),
                  offset: const Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!primary) ...[
                  Icon(icon, size: 17.0, color: fg),
                  const SizedBox(width: 7.0),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
                if (primary) ...[
                  const SizedBox(width: 7.0),
                  Icon(icon, size: 17.0, color: fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
