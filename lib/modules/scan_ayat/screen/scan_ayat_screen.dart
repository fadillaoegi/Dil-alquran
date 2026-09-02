import 'package:dilalquran/modules/audio/audio_controller.dart';
import 'package:dilalquran/modules/data/models/surah_detail_model.dart';
import 'package:dilalquran/modules/scan_ayat/controller/scan_ayat_controller.dart';
import 'package:dilalquran/modules/scan_ayat/model/ayat_chat_model.dart';
import 'package:dilalquran/modules/scan_ayat/model/ayat_recognition_model.dart';
import 'package:dilalquran/modules/scan_ayat/widget/ayat_chat_section.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ScanAyatScreen extends StatelessWidget {
  const ScanAyatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ScanAyatController>();

    return Scaffold(
      backgroundColor: ColorApp.secondary,
      body: Column(
        children: [
          _Header(controller: controller),
          Expanded(
            child: Obx(() {
              switch (controller.stage.value) {
                case ScanStage.idle:
                  return _IdleView(controller: controller);
                case ScanStage.recognizing:
                  return const _LoadingView(
                    title: "Membaca foto...",
                    subtitle:
                        "Mencocokkan halaman dengan surah dan nomor ayatnya.",
                  );
                case ScanStage.choosing:
                  return _CandidateView(controller: controller);
                case ScanStage.resolving:
                  return const _LoadingView(
                    title: "Mengambil teks ayat...",
                    subtitle: "Teks diambil dari sumber resmi equran.id.",
                  );
                case ScanStage.result:
                  return _ResultView(controller: controller);
              }
            }),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final ScanAyatController controller;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.0, topPadding + 12.0, 16.0, 22.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff0d4e34), ColorApp.primary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.0),
          bottomRight: Radius.circular(28.0),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: ColorApp.white,
            ),
            tooltip: "Kembali",
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Scan Ayat", style: white700.copyWith(fontSize: 20.0)),
                const SizedBox(height: 2.0),
                Text(
                  "Foto halaman Al-Qur'an, lihat arti & tafsirnya",
                  style: white400.copyWith(
                    fontSize: 12.0,
                    color: ColorApp.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            if (controller.stage.value == ScanStage.idle) {
              return const SizedBox(width: 8.0);
            }
            return IconButton(
              onPressed: controller.isBusy ? null : controller.reset,
              icon: const Icon(
                Icons.refresh_rounded,
                color: ColorApp.white,
              ),
              tooltip: "Pindai ulang",
            );
          }),
        ],
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({required this.controller});

  final ScanAyatController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28.0),
            decoration: BoxDecoration(
              color: ColorApp.white,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: const Color(0xFFE3EDE7)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18.0),
                  decoration: const BoxDecoration(
                    color: ColorApp.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    size: 44.0,
                    color: ColorApp.primary,
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  "Arahkan kamera ke halaman mushaf",
                  style: black700.copyWith(fontSize: 15.0),
                ),
                const SizedBox(height: 6.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Text(
                    "Aplikasi akan mengenali surah dan nomor ayatnya, lalu "
                    "menampilkan teks resmi beserta artinya.",
                    textAlign: TextAlign.center,
                    style: black400.copyWith(fontSize: 12.5, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          Obx(() {
            final message = controller.errorMessage.value;
            if (message.isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: const Color(0xFFF3D9B0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18.0,
                    color: Color(0xFFB37400),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      message,
                      style: black400.copyWith(fontSize: 12.5, height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          }),
          Obx(
            () => _PrimaryButton(
              label: "Buka Kamera",
              icon: Icons.photo_camera_rounded,
              enabled: !controller.isBusy,
              onTap: controller.captureFromCamera,
            ),
          ),
          const SizedBox(height: 10.0),
          Obx(
            () => _SecondaryButton(
              label: "Pilih dari Galeri",
              icon: Icons.photo_library_rounded,
              enabled: !controller.isBusy,
              onTap: controller.pickFromGallery,
            ),
          ),
          const SizedBox(height: 20.0),
          const _TipsCard(),
          const SizedBox(height: 14.0),
          Text(
            "Teks ayat, terjemahan, dan tafsir selalu diambil dari sumber "
            "resmi equran.id — bukan dibuat oleh AI. AI hanya membantu "
            "menebak nomor surah dan ayat dari foto Anda.",
            textAlign: TextAlign.center,
            style: black400.copyWith(
              fontSize: 11.0,
              height: 1.6,
              color: ColorApp.black.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  static const List<String> _tips = [
    "Pastikan cahaya cukup dan tulisan tidak buram.",
    "Foto satu halaman penuh, jangan miring.",
    "Untuk hasil terbaik, dekatkan ke ayat yang ingin dipahami.",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: ColorApp.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE3EDE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tips_and_updates_rounded,
                size: 17.0,
                color: ColorApp.primary,
              ),
              const SizedBox(width: 8.0),
              Text("Tips memfoto", style: black700.copyWith(fontSize: 13.5)),
            ],
          ),
          const SizedBox(height: 10.0),
          for (final tip in _tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0, right: 8.0),
                    child: Container(
                      width: 5.0,
                      height: 5.0,
                      decoration: const BoxDecoration(
                        color: ColorApp.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tip,
                      style: black400.copyWith(fontSize: 12.0, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: ColorApp.primary),
            const SizedBox(height: 22.0),
            Text(title, style: black700.copyWith(fontSize: 15.0)),
            const SizedBox(height: 8.0),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: black400.copyWith(fontSize: 12.5, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateView extends StatelessWidget {
  const _CandidateView({required this.controller});

  final ScanAyatController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Ayat mana yang Anda maksud?",
            style: black700.copyWith(fontSize: 16.0),
          ),
          const SizedBox(height: 6.0),
          Text(
            "Foto ini punya beberapa kemungkinan. Pilih salah satu untuk "
            "melihat teks resmi dan artinya.",
            style: black400.copyWith(fontSize: 12.5, height: 1.5),
          ),
          const SizedBox(height: 18.0),
          Obx(
            () => Column(
              children: [
                for (final candidate in controller.candidates)
                  _CandidateCard(
                    candidate: candidate,
                    onTap: () => controller.selectCandidate(candidate),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          Obx(() {
            final message = controller.errorMessage.value;
            if (message.isEmpty) return const SizedBox.shrink();
            return Text(
              message,
              style: black400.copyWith(fontSize: 12.0, color: ColorApp.black),
            );
          }),
          const SizedBox(height: 12.0),
          _SecondaryButton(
            label: "Foto Ulang",
            icon: Icons.replay_rounded,
            enabled: true,
            onTap: controller.reset,
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate, required this.onTap});

  final AyatCandidate candidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = (candidate.confidence * 100).round();
    final name = candidate.surahNameGuess.isEmpty
        ? "Surah ${candidate.surahNumber}"
        : candidate.surahNameGuess;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: ColorApp.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE3EDE7)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: ColorApp.secondary,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  candidate.label,
                  style: primary700.copyWith(fontSize: 13.0),
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: black600.copyWith(fontSize: 14.0)),
                    const SizedBox(height: 3.0),
                    Text(
                      candidate.isRange
                          ? "${candidate.ayatCount} ayat · keyakinan $percent%"
                          : "Keyakinan $percent%",
                      style: black400.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: ColorApp.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.controller});

  final ScanAyatController controller;

  void _playAudio(ResolvedAyat resolved) {
    final urls = resolved.audioUrls;
    if (urls.isEmpty) return;

    final keys = [
      for (final ayat in resolved.ayatList)
        "${resolved.surahNumber}:${ayat.nomorAyat ?? 0}",
    ];

    Get.find<AudioController>().playPlaylist(
      urls: urls,
      keys: keys,
      type: "surah",
      parentNumber: resolved.surahNumber,
      album: resolved.surahNameLatin,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final resolved = controller.resolved.value;
      if (resolved == null || resolved.isEmpty) {
        return const _LoadingView(
          title: "Menyiapkan hasil...",
          subtitle: "Sebentar lagi selesai.",
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.only(top: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSurahBadge(resolved),
            const SizedBox(height: 14.0),
            for (final ayat in resolved.ayatList) _buildAyatCard(ayat),
            _buildActions(resolved),
            if (resolved.tafsir.trim().isNotEmpty)
              _buildTafsir(context, resolved),
            AyatChatSection(controller: controller),
          ],
        ),
      );
    });
  }

  Widget _buildSurahBadge(ResolvedAyat resolved) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff0d4e34), ColorApp.primary],
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolved.rangeLabel,
                    style: white700.copyWith(fontSize: 16.0),
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    "Sumber teks: equran.id",
                    style: white400.copyWith(
                      fontSize: 11.0,
                      color: ColorApp.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (resolved.surahNameArab.isNotEmpty)
              Text(
                resolved.surahNameArab,
                style: arabicTitle.copyWith(fontSize: 20.0),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAyatCard(Ayat ayat) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: ColorApp.white,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: const Color(0xFFE3EDE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 4.0,
            ),
            decoration: BoxDecoration(
              color: ColorApp.secondary,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              "Ayat ${ayat.nomorAyat ?? '-'}",
              style: primary600.copyWith(fontSize: 11.5),
            ),
          ),
          const SizedBox(height: 14.0),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              ayat.teksArab ?? "",
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: arabicQuran,
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            ayat.teksLatin ?? "",
            style: primary400.copyWith(
              fontSize: 12.5,
              height: 1.7,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10.0),
          Text(
            ayat.teksIndonesia ?? "",
            style: black400.copyWith(fontSize: 13.5, height: 1.7),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ResolvedAyat resolved) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 16.0),
      child: Row(
        children: [
          if (resolved.audioUrls.isNotEmpty)
            Expanded(
              child: _PrimaryButton(
                label: "Putar Murottal",
                icon: Icons.play_arrow_rounded,
                enabled: true,
                onTap: () => _playAudio(resolved),
              ),
            ),
          if (resolved.audioUrls.isNotEmpty) const SizedBox(width: 10.0),
          Expanded(
            child: _SecondaryButton(
              label: "Bukan ini?",
              icon: Icons.swap_horiz_rounded,
              enabled: true,
              onTap: controller.backToCandidates,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTafsir(BuildContext context, ResolvedAyat resolved) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 14.0),
      decoration: BoxDecoration(
        color: ColorApp.white,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: const Color(0xFFE3EDE7)),
      ),
      child: Theme(
        // Hilangkan garis pembatas bawaan ExpansionTile.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
          childrenPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: const Icon(
            Icons.menu_book_rounded,
            color: ColorApp.primary,
            size: 20.0,
          ),
          title: Text(
            "Tafsir Ayat ${resolved.firstAyatNumber}",
            style: black700.copyWith(fontSize: 14.0),
          ),
          subtitle: Text(
            "Tafsir Kemenag via equran.id",
            style: black400.copyWith(fontSize: 11.0),
          ),
          children: [
            Text(
              resolved.tafsir.trim(),
              textAlign: TextAlign.justify,
              style: black400.copyWith(fontSize: 13.0, height: 1.75),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? ColorApp.primary : const Color(0xFFB9CFC2),
      borderRadius: BorderRadius.circular(16.0),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: ColorApp.white, size: 20.0),
              const SizedBox(width: 8.0),
              Text(label, style: white600.copyWith(fontSize: 14.0)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorApp.white,
      borderRadius: BorderRadius.circular(16.0),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: ColorApp.primary.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: ColorApp.primary, size: 19.0),
              const SizedBox(width: 8.0),
              Text(label, style: primary600.copyWith(fontSize: 13.5)),
            ],
          ),
        ),
      ),
    );
  }
}
