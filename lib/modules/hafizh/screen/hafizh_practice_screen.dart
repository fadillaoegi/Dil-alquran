import 'package:dilalquran/modules/hafizh/controller/hafizh_practice_controller.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HafizhPracticeScreen extends GetView<HafizhPracticeController> {
  const HafizhPracticeScreen({super.key});

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
          "Latihan Susun Ayat",
          style: primary700.copyWith(fontSize: 18.0, color: ColorApp.white),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: ColorApp.primary),
          );
        }

        if (controller.totalRounds == 0) {
          return _EmptyState(
            isJuz: controller.isJuz,
            hasCustomRange: controller.hasCustomRange,
          );
        }

        if (controller.finished.value) {
          return _buildSummary();
        }

        return _buildGame();
      }),
    );
  }

  Widget _buildGame() {
    return Column(
      children: [
        _buildProgressStrip(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(),
                const SizedBox(height: 16.0),
                _SectionCard(
                  title: "Susunan Jawaban",
                  subtitle: "Ketuk kata untuk menyusun urutan ayat yang benar.",
                  icon: Icons.dashboard_customize_rounded,
                  child: _buildAnswerArea(),
                ),
                const SizedBox(height: 14.0),
                _SectionCard(
                  title: "Bank Kata",
                  subtitle: "Pilih kata satu per satu dari kumpulan di bawah.",
                  icon: Icons.auto_awesome_motion_rounded,
                  child: _buildWordBank(),
                ),
              ],
            ),
          ),
        ),
        _buildActionBar(),
      ],
    );
  }

  Widget _buildProgressStrip() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 14.0),
      decoration: BoxDecoration(
        color: ColorApp.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.track_changes_rounded,
                      size: 15.0,
                      color: ColorApp.primary,
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      "Soal ${controller.roundIndex.value + 1} dari ${controller.totalRounds}",
                      style: primary600.copyWith(fontSize: 12.5),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999.0),
                  child: LinearProgressIndicator(
                    value: (controller.roundIndex.value + 1) /
                        controller.totalRounds,
                    minHeight: 8.0,
                    backgroundColor: ColorApp.primary.withValues(alpha: 0.12),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(ColorApp.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14.0),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: const Color(0xffFFF7E8),
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 18.0),
                const SizedBox(width: 5.0),
                Text(
                  "${controller.score.value}",
                  style: black600.copyWith(fontSize: 13.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    final label = controller.isJuz
        ? "${controller.currentSurahName} • Ayat ${controller.currentAyatNumber}"
        : "Ayat ${controller.currentAyatNumber}";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff0d4e34), ColorApp.primary, Color(0xff19a968)],
        ),
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: ColorApp.primary.withValues(alpha: 0.28),
            blurRadius: 16.0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: ColorApp.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 14.0,
                      color: ColorApp.white.withValues(alpha: 0.92),
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      "Fokus Latihan",
                      style: white600.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                "${controller.roundIndex.value + 1}/${controller.totalRounds}",
                style: white600.copyWith(fontSize: 12.0),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          Text(
            label,
            style: white700.copyWith(fontSize: 28.0),
          ),
          const SizedBox(height: 6.0),
          Text(
            "Susun potongan kata Arab hingga membentuk ayat yang tepat.",
            style: white400.copyWith(
              fontSize: 13.0,
              height: 1.5,
              color: ColorApp.white.withValues(alpha: 0.9),
            ),
          ),
          if (controller.hasCustomRange) ...[
            const SizedBox(height: 16.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: ColorApp.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: ColorApp.white.withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_alt_rounded,
                    color: ColorApp.white,
                    size: 18.0,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      "Mode rentang ayat aktif",
                      style: white600.copyWith(fontSize: 12.0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerArea() {
    final checked = controller.result.value;
    final borderColor = checked == null
        ? ColorApp.primary.withValues(alpha: 0.2)
        : (checked ? ColorApp.primary : Colors.redAccent);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 122.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: checked == null
            ? ColorApp.secondary
            : (checked
                    ? ColorApp.primary
                    : Colors.redAccent)
                .withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: borderColor, width: 1.4),
      ),
      child: controller.answer.isEmpty
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 28.0,
                  color: ColorApp.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 10.0),
                Text(
                  "Ketuk kata dari bank di bawah untuk mulai menyusun ayat.",
                  textAlign: TextAlign.center,
                  style: black400.copyWith(
                    fontSize: 12.5,
                    height: 1.5,
                    color: ColorApp.black.withValues(alpha: 0.55),
                  ),
                ),
              ],
            )
          : Wrap(
              textDirection: TextDirection.rtl,
              spacing: 8.0,
              runSpacing: 8.0,
              children: controller.answer
                  .map(
                    (word) => _wordChip(
                      word.text,
                      filled: true,
                      onTap: () => controller.unpick(word),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildWordBank() {
    if (controller.shuffled.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ColorApp.secondary,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Text(
          "Semua kata sudah dipakai. Tinggal periksa jawabannya.",
          textAlign: TextAlign.center,
          style: black400.copyWith(
            fontSize: 12.5,
            color: ColorApp.black.withValues(alpha: 0.55),
          ),
        ),
      );
    }

    return Wrap(
      textDirection: TextDirection.rtl,
      spacing: 8.0,
      runSpacing: 8.0,
      children: controller.shuffled
          .map(
            (word) => _wordChip(
              word.text,
              filled: false,
              onTap: () => controller.pick(word),
            ),
          )
          .toList(),
    );
  }

  Widget _wordChip(
    String text, {
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.0),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 11.0),
          decoration: BoxDecoration(
            gradient: filled
                ? const LinearGradient(
                    colors: [Color(0xff0d4e34), ColorApp.primary],
                  )
                : null,
            color: filled ? null : ColorApp.white,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(
              color: filled
                  ? Colors.transparent
                  : ColorApp.primary.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: filled ? 0.12 : 0.04),
                blurRadius: filled ? 10.0 : 6.0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            text,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 20.0,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: filled ? ColorApp.white : ColorApp.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    final checked = controller.result.value;

    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 20.0),
      decoration: BoxDecoration(
        color: ColorApp.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (checked != null) _buildResultBanner(checked),
          Row(
            children: [
              if (checked == null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        controller.answer.isEmpty ? null : controller.resetRound,
                    icon: const Icon(Icons.refresh_rounded, size: 18.0),
                    label: const Text("Acak Ulang"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorApp.primary,
                      side: BorderSide(
                        color: ColorApp.primary.withValues(alpha: 0.35),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.canCheck ? controller.check : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorApp.primary,
                      disabledBackgroundColor:
                          ColorApp.primary.withValues(alpha: 0.3),
                      foregroundColor: ColorApp.white,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                    ),
                    child:
                        Text("Periksa", style: white700.copyWith(fontSize: 15.0)),
                  ),
                ),
              ] else
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.next,
                    icon: Icon(
                      controller.roundIndex.value >= controller.totalRounds - 1
                          ? Icons.emoji_events_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorApp.primary,
                      foregroundColor: ColorApp.white,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                    ),
                    label: Text(
                      controller.roundIndex.value >= controller.totalRounds - 1
                          ? "Selesaikan"
                          : "Lanjut",
                      style: white700.copyWith(fontSize: 15.0),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultBanner(bool correct) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: (correct ? ColorApp.primary : Colors.redAccent)
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: (correct ? ColorApp.primary : Colors.redAccent)
              .withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: (correct ? ColorApp.primary : Colors.redAccent)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(
              correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: correct ? ColorApp.primary : Colors.redAccent,
              size: 20.0,
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  correct ? "Benar, lanjutkan." : "Urutannya belum tepat.",
                  style: black600.copyWith(
                    fontSize: 13.5,
                    color: correct ? ColorApp.primary : Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  correct
                      ? "MasyaAllah, susunan ayatmu sudah benar."
                      : "Jawaban yang benar ditampilkan di bawah supaya lebih mudah muraja'ah.",
                  style: black400.copyWith(
                    fontSize: 12.0,
                    height: 1.5,
                    color: ColorApp.black.withValues(alpha: 0.6),
                  ),
                ),
                if (!correct) ...[
                  const SizedBox(height: 10.0),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: ColorApp.white,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      controller.correctAnswer,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: black700.copyWith(fontSize: 18.0, height: 1.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final total = controller.totalRounds;
    final score = controller.score.value;
    final percent = total == 0 ? 0 : (score / total * 100).round();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: ColorApp.white,
            borderRadius: BorderRadius.circular(28.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18.0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff0d4e34), ColorApp.primary],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: ColorApp.primary.withValues(alpha: 0.2),
                      blurRadius: 18.0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  percent >= 80
                      ? Icons.emoji_events_rounded
                      : Icons.military_tech_rounded,
                  color: ColorApp.white,
                  size: 56.0,
                ),
              ),
              const SizedBox(height: 20.0),
              Text(
                "Latihan Selesai",
                style: black700.copyWith(fontSize: 22.0),
              ),
              const SizedBox(height: 8.0),
              Text(
                "Kamu menjawab benar $score dari $total ayat.",
                textAlign: TextAlign.center,
                style: black400.copyWith(fontSize: 14.0, height: 1.5),
              ),
              const SizedBox(height: 18.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: ColorApp.secondary,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Column(
                  children: [
                    Text(
                      "$percent%",
                      style: primary700.copyWith(fontSize: 34.0),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      percent >= 80
                          ? "Luar biasa, hafalanmu kuat."
                          : percent >= 50
                              ? "Bagus, tinggal sedikit lagi dirapikan."
                              : "Tidak apa-apa, ulangi lagi sampai makin lancar.",
                      textAlign: TextAlign.center,
                      style: black400.copyWith(
                        fontSize: 12.5,
                        height: 1.5,
                        color: ColorApp.black.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.restart,
                  icon: const Icon(Icons.replay_rounded),
                  label: Text("Ulangi Lagi", style: white700.copyWith(fontSize: 15.0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorApp.primary,
                    foregroundColor: ColorApp.white,
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12.0),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorApp.primary,
                    side: BorderSide(
                      color: ColorApp.primary.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                  ),
                  child: const Text("Kembali"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: ColorApp.white,
        borderRadius: BorderRadius.circular(22.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: ColorApp.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14.0),
                ),
                child: Icon(icon, color: ColorApp.primary, size: 18.0),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: black600.copyWith(fontSize: 14.5)),
                    const SizedBox(height: 2.0),
                    Text(
                      subtitle,
                      style: black400.copyWith(
                        fontSize: 12.0,
                        color: ColorApp.black.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          child,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isJuz,
    required this.hasCustomRange,
  });

  final bool isJuz;
  final bool hasCustomRange;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22.0),
              decoration: BoxDecoration(
                color: ColorApp.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.layers_clear_rounded,
                size: 40.0,
                color: ColorApp.primary,
              ),
            ),
            const SizedBox(height: 18.0),
            Text(
              "Belum Ada Materi Latihan",
              style: black700.copyWith(fontSize: 19.0),
            ),
            const SizedBox(height: 8.0),
            Text(
              hasCustomRange
                  ? "Rentang ayat yang dipilih belum punya data yang bisa dilatih."
                  : isJuz
                      ? "Belum ada ayat pada juz ini yang siap dipakai untuk latihan."
                      : "Belum ada ayat yang bisa dilatih untuk surah ini.",
              textAlign: TextAlign.center,
              style: black400.copyWith(
                fontSize: 13.5,
                height: 1.5,
                color: ColorApp.black.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
