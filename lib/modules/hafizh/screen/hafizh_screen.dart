import 'package:dilalquran/modules/hafizh/controller/hafizh_controller.dart';
import 'package:dilalquran/routes/route.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const _hafizhCardBorderColor = Color(0xFFD3D3D3);
const _hafizhCardBaseShadowColor = Color(0xFFCFCFCF);

class HafizhScreen extends GetView<HafizhController> {
  const HafizhScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.secondary,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: ColorApp.primary,
        title: Text(
          "Hafizh Qur'an",
          style: primary700.copyWith(fontSize: 20.0, color: ColorApp.white),
        ),
        iconTheme: const IconThemeData(color: ColorApp.white),
        actions: [
          Obx(
            () => IconButton(
              tooltip: "Pengingat muraja'ah",
              icon: Icon(
                controller.reminderEnabled.value
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                color: ColorApp.white,
              ),
              onPressed: () => _openReminderSheet(context),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: ColorApp.primary),
          );
        }

        final isJuz = controller.activeTab.value == 1;
        final listLength =
            isJuz ? controller.juzList.length : controller.surahList.length;

        return RefreshIndicator(
          color: ColorApp.primary,
          onRefresh: controller.refreshData,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
            itemCount: listLength + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    _buildProgressHeader(),
                    _buildTabSelector(),
                  ],
                );
              }

              if (isJuz) {
                final juz = controller.juzList[index - 1];
                return _JuzProgressTile(
                  number: juz.number,
                  startSurahName: juz.startSurahName,
                  endSurahName: juz.endSurahName,
                  totalAyat: controller.totalAyatForJuz(juz.number),
                  onTap: () => Get.toNamed(
                    RouteScreen.hafizhDetail,
                    arguments: {"category": "juz", "number": juz.number},
                  ),
                  onRangeTap: () => _openJuzAyatRangeSheet(
                    context: context,
                    juzNumber: juz.number,
                    startSurahName: juz.startSurahName,
                    endSurahName: juz.endSurahName,
                    totalAyat: controller.totalAyatForJuz(juz.number),
                  ),
                );
              }

              final surah = controller.surahList[index - 1];
              return _SurahProgressTile(
                nomor: surah.nomor ?? 0,
                namaLatin: surah.namaLatin ?? "-",
                arti: surah.arti ?? "",
                jumlahAyat: surah.jumlahAyat ?? 0,
                onTap: () => Get.toNamed(
                  RouteScreen.hafizhDetail,
                  arguments: {"category": "surah", "number": surah.nomor},
                ),
                onRangeTap: () => _openAyatRangeSheet(
                  context: context,
                  surahNumber: surah.nomor ?? 0,
                  surahName: surah.namaLatin ?? "-",
                  jumlahAyat: surah.jumlahAyat ?? 0,
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildProgressHeader() {
    return Obx(() {
      final progress = controller.overallProgress;
      final percent = (progress * 100).toStringAsFixed(1);

      return Container(
        margin: const EdgeInsets.only(bottom: 20.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff10553a), Color(0xff34b57e)],
          ),
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
              color: ColorApp.primary.withValues(alpha: 0.3),
              blurRadius: 16.0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Progress Hafalan", style: white600.copyWith(fontSize: 14.0)),
            const SizedBox(height: 8.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("$percent%", style: white700.copyWith(fontSize: 34.0)),
                const SizedBox(width: 8.0),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Text(
                    "dari Al-Quran",
                    style: white400.copyWith(
                      fontSize: 12.0,
                      color: ColorApp.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8.0,
                backgroundColor: ColorApp.white.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(ColorApp.white),
              ),
            ),
            const SizedBox(height: 16.0),
            _buildStreakBanner(),
            const SizedBox(height: 12.0),
            Row(
              children: [
                _statBox(
                  "${controller.totalMemorized}",
                  "Ayat dihafal",
                  Icons.check_circle_rounded,
                ),
                const SizedBox(width: 12.0),
                _statBox(
                  "${controller.completedSurahCount}",
                  "Surah selesai",
                  Icons.menu_book_rounded,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _statBox(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: ColorApp.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14.0),
        ),
        child: Row(
          children: [
            Icon(icon, color: ColorApp.white, size: 22.0),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: white700.copyWith(fontSize: 18.0)),
                  Text(
                    label,
                    style: white400.copyWith(
                      fontSize: 11.0,
                      color: ColorApp.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakBanner() {
    final streak = controller.currentStreak;
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: ColorApp.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: ColorApp.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: ColorApp.white,
              size: 22.0,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streak > 0
                      ? "$streak hari beruntun"
                      : "Mulai streak-mu hari ini",
                  style: white700.copyWith(fontSize: 15.0),
                ),
                const SizedBox(height: 2.0),
                Text(
                  "Terpanjang ${controller.longestStreak} hari · ${controller.totalActiveDays} hari aktif",
                  style: white400.copyWith(
                    fontSize: 11.0,
                    color: ColorApp.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Obx(() {
      final tab = controller.activeTab.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          children: [
            _tabChip("Surah", Icons.menu_book_rounded, tab == 0,
                () => controller.setTab(0)),
            const SizedBox(width: 10.0),
            _tabChip("Juz", Icons.grid_view_rounded, tab == 1,
                () => controller.setTab(1)),
          ],
        ),
      );
    });
  }

  Widget _tabChip(
      String label, IconData icon, bool selected, VoidCallback onTap) {
    const borderColor = Color(0xFFD3D3D3);
    const baseShadowColor = Color(0xFFCFCFCF);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (!selected)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 8,
                  bottom: -8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: baseShadowColor,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                decoration: BoxDecoration(
                  color: selected ? ColorApp.primary : ColorApp.white,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                    color: selected ? ColorApp.primary : borderColor,
                    width: 1.2,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: ColorApp.primary.withValues(alpha: 0.18),
                            offset: const Offset(0, 6),
                            blurRadius: 14,
                            spreadRadius: -4,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: ColorApp.primary.withValues(alpha: 0.03),
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                            spreadRadius: -2,
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 18.0,
                      color: selected ? ColorApp.white : ColorApp.primary,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      label,
                      style: TextStyle(
                        color: selected ? ColorApp.white : ColorApp.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openReminderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorApp.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (_) => _ReminderSheet(controller: controller),
    );
  }

  void _openAyatRangeSheet({
    required BuildContext context,
    required int surahNumber,
    required String surahName,
    required int jumlahAyat,
  }) {
    if (surahNumber <= 0 || jumlahAyat <= 0) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: ColorApp.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (_) => _AyatRangeSheet(
        surahNumber: surahNumber,
        surahName: surahName,
        jumlahAyat: jumlahAyat,
      ),
    );
  }

  void _openJuzAyatRangeSheet({
    required BuildContext context,
    required int juzNumber,
    required String startSurahName,
    required String endSurahName,
    required int totalAyat,
  }) {
    if (totalAyat <= 0) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ColorApp.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (_) => _JuzAyatRangeSheet(
        juzNumber: juzNumber,
        startSurahName: startSurahName,
        endSurahName: endSurahName,
        totalAyat: totalAyat,
      ),
    );
  }
}

// Panel pengaturan pengingat dengan wheel picker inline (tanpa pop-up
// bertingkat). StatefulWidget agar putaran roda tidak memicu rebuild
// berlebihan; waktu final di-commit sekali saat panel ditutup.
class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet({required this.controller});

  final HafizhController controller;

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  late bool _enabled;
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _enabled = widget.controller.reminderEnabled.value;
    _hour = widget.controller.reminderHour.value;
    _minute = widget.controller.reminderMinute.value;
  }

  @override
  void dispose() {
    // Simpan waktu terpilih sekali saja saat panel ditutup.
    if (_enabled) {
      widget.controller.setReminderTime(_hour, _minute);
    }
    super.dispose();
  }

  String get _timeLabel =>
      "${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.0,
              height: 4.0,
              margin: const EdgeInsets.only(bottom: 20.0),
              decoration: BoxDecoration(
                color: ColorApp.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.notifications_active_rounded,
                  color: ColorApp.primary),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  "Pengingat Muraja'ah Harian",
                  style: black600.copyWith(fontSize: 15.0),
                ),
              ),
              Switch(
                value: _enabled,
                activeThumbColor: ColorApp.white,
                activeTrackColor: ColorApp.primary,
                onChanged: (value) {
                  setState(() => _enabled = value);
                  widget.controller.toggleReminder(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            "Dapatkan pengingat harian untuk mengulang hafalanmu agar tetap terjaga.",
            style: black400.copyWith(
              fontSize: 12.5,
              height: 1.5,
              color: ColorApp.black.withValues(alpha: 0.6),
            ),
          ),
          if (_enabled) ...[
            const SizedBox(height: 12.0),
            Row(
              children: [
                const Icon(Icons.access_time_filled_rounded,
                    color: ColorApp.primary, size: 20.0),
                const SizedBox(width: 8.0),
                Text("Waktu pengingat",
                    style: black500.copyWith(fontSize: 13.5)),
                const Spacer(),
                Text(_timeLabel, style: primary700.copyWith(fontSize: 18.0)),
              ],
            ),
            SizedBox(
              height: 170.0,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: DateTime(2020, 1, 1, _hour, _minute),
                onDateTimeChanged: (value) {
                  setState(() {
                    _hour = value.hour;
                    _minute = value.minute;
                  });
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SurahProgressTile extends StatelessWidget {
  const _SurahProgressTile({
    required this.nomor,
    required this.namaLatin,
    required this.arti,
    required this.jumlahAyat,
    required this.onTap,
    required this.onRangeTap,
  });

  final int nomor;
  final String namaLatin;
  final String arti;
  final int jumlahAyat;
  final VoidCallback onTap;
  final VoidCallback onRangeTap;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HafizhController>();

    return Container(
      margin: const EdgeInsets.only(bottom: 18.0),
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
                color: _hafizhCardBaseShadowColor,
                borderRadius: BorderRadius.circular(18.0),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16.0),
              onTap: onTap,
              child: Ink(
                decoration: BoxDecoration(
                  color: ColorApp.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: _hafizhCardBorderColor,
                    width: 1.25,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ColorApp.primary.withValues(alpha: 0.04),
                      blurRadius: 10.0,
                      offset: const Offset(0, 2),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      Container(
                        width: 42.0,
                        height: 42.0,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ColorApp.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          "$nomor",
                          style: primary700.copyWith(fontSize: 15.0),
                        ),
                      ),
                      const SizedBox(width: 14.0),
                      Expanded(
                        child: Obx(() {
                          final done = controller.memorizedCountForSurah(nomor);
                          final progress =
                              jumlahAyat == 0 ? 0.0 : done / jumlahAyat;
                          final complete = jumlahAyat > 0 && done >= jumlahAyat;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      namaLatin,
                                      style: black600.copyWith(fontSize: 15.0),
                                    ),
                                  ),
                                  if (complete)
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: ColorApp.primary,
                                      size: 18.0,
                                    ),
                                  const SizedBox(width: 6.0),
                                  GestureDetector(
                                    onTap: onRangeTap,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 5.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ColorApp.primary
                                            .withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(999.0),
                                      ),
                                      child: Text(
                                        "Pilih ayat",
                                        style:
                                            primary600.copyWith(fontSize: 10.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                arti,
                                style: black400.copyWith(
                                  fontSize: 12.0,
                                  color: ColorApp.black.withValues(alpha: 0.55),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6.0),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 6.0,
                                        backgroundColor: ColorApp.primary
                                            .withValues(alpha: 0.12),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                          ColorApp.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10.0),
                                  Text(
                                    "$done/$jumlahAyat",
                                    style: primary600.copyWith(fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
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

class _AyatRangeSheet extends StatefulWidget {
  const _AyatRangeSheet({
    required this.surahNumber,
    required this.surahName,
    required this.jumlahAyat,
  });

  final int surahNumber;
  final String surahName;
  final int jumlahAyat;

  @override
  State<_AyatRangeSheet> createState() => _AyatRangeSheetState();
}

class _AyatRangeSheetState extends State<_AyatRangeSheet> {
  late int _startAyat;
  late int _endAyat;

  @override
  void initState() {
    super.initState();
    _startAyat = 1;
    _endAyat = widget.jumlahAyat;
  }

  @override
  Widget build(BuildContext context) {
    final ayatOptions = List<int>.generate(widget.jumlahAyat, (i) => i + 1);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20.0,
        16.0,
        20.0,
        MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: ColorApp.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999.0),
              ),
            ),
          ),
          const SizedBox(height: 18.0),
          Text(
            "Atur Rentang Hafalan",
            style: black600.copyWith(fontSize: 16.0),
          ),
          const SizedBox(height: 4.0),
          Text(
            "${widget.surahName} · ${widget.jumlahAyat} ayat",
            style: black400.copyWith(
              fontSize: 12.5,
              color: ColorApp.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: _AyatDropdown(
                  label: "Dari ayat",
                  value: _startAyat,
                  options: ayatOptions,
                  onChanged: (value) {
                    setState(() {
                      _startAyat = value;
                      if (_endAyat < _startAyat) {
                        _endAyat = _startAyat;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _AyatDropdown(
                  label: "Sampai ayat",
                  value: _endAyat,
                  options:
                      ayatOptions.where((item) => item >= _startAyat).toList(),
                  onChanged: (value) => setState(() => _endAyat = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: ColorApp.secondary,
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: Text(
              "Rentang terpilih: ayat $_startAyat - $_endAyat",
              style: primary600.copyWith(fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 18.0),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorApp.primary,
                    side: BorderSide(
                      color: ColorApp.primary.withValues(alpha: 0.28),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                  ),
                  child: const Text("Batal"),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Get.toNamed(
                      RouteScreen.hafizhDetail,
                      arguments: {
                        "category": "surah",
                        "number": widget.surahNumber,
                        "startAyat": _startAyat,
                        "endAyat": _endAyat,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorApp.primary,
                    foregroundColor: ColorApp.white,
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                  ),
                  child: const Text("Mulai Hafalan"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AyatDropdown extends StatelessWidget {
  const _AyatDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: black500.copyWith(fontSize: 12.5)),
        const SizedBox(height: 8.0),
        DropdownButtonFormField<int>(
          initialValue: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: ColorApp.secondary,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 12.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: BorderSide.none,
            ),
          ),
          items: options
              .map(
                (item) => DropdownMenuItem<int>(
                  value: item,
                  child: Text("Ayat $item"),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}

class _JuzProgressTile extends StatelessWidget {
  const _JuzProgressTile({
    required this.number,
    required this.startSurahName,
    required this.endSurahName,
    required this.totalAyat,
    required this.onTap,
    required this.onRangeTap,
  });

  final int number;
  final String startSurahName;
  final String endSurahName;
  final int totalAyat;
  final VoidCallback onTap;
  final VoidCallback onRangeTap;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HafizhController>();

    return Container(
      margin: const EdgeInsets.only(bottom: 18.0),
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
                color: _hafizhCardBaseShadowColor,
                borderRadius: BorderRadius.circular(18.0),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16.0),
              onTap: onTap,
              child: Ink(
                decoration: BoxDecoration(
                  color: ColorApp.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: _hafizhCardBorderColor,
                    width: 1.25,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ColorApp.primary.withValues(alpha: 0.04),
                      blurRadius: 10.0,
                      offset: const Offset(0, 2),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      Container(
                        width: 42.0,
                        height: 42.0,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ColorApp.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          "$number",
                          style: primary700.copyWith(fontSize: 15.0),
                        ),
                      ),
                      const SizedBox(width: 14.0),
                      Expanded(
                        child: Obx(() {
                          final done = controller.memorizedCountForJuz(number);
                          final progress =
                              totalAyat == 0 ? 0.0 : done / totalAyat;
                          final complete = totalAyat > 0 && done >= totalAyat;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Juz $number",
                                      style: black600.copyWith(fontSize: 15.0),
                                    ),
                                  ),
                                  if (complete)
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: ColorApp.primary,
                                      size: 18.0,
                                    ),
                                  const SizedBox(width: 6.0),
                                  GestureDetector(
                                    onTap: onRangeTap,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 5.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ColorApp.primary
                                            .withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(999.0),
                                      ),
                                      child: Text(
                                        "Pilih ayat",
                                        style:
                                            primary600.copyWith(fontSize: 10.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                "$startSurahName – $endSurahName",
                                style: black400.copyWith(
                                  fontSize: 12.0,
                                  color: ColorApp.black.withValues(alpha: 0.55),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6.0),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 6.0,
                                        backgroundColor: ColorApp.primary
                                            .withValues(alpha: 0.12),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                          ColorApp.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10.0),
                                  Text(
                                    "$done/$totalAyat",
                                    style: primary600.copyWith(fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
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

class _JuzAyatRangeSheet extends StatefulWidget {
  const _JuzAyatRangeSheet({
    required this.juzNumber,
    required this.startSurahName,
    required this.endSurahName,
    required this.totalAyat,
  });

  final int juzNumber;
  final String startSurahName;
  final String endSurahName;
  final int totalAyat;

  @override
  State<_JuzAyatRangeSheet> createState() => _JuzAyatRangeSheetState();
}

class _JuzAyatRangeSheetState extends State<_JuzAyatRangeSheet> {
  late int _startAyat;
  late int _endAyat;

  @override
  void initState() {
    super.initState();
    _startAyat = 1;
    _endAyat = widget.totalAyat;
  }

  @override
  Widget build(BuildContext context) {
    final ayatOptions = List<int>.generate(widget.totalAyat, (i) => i + 1);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20.0,
        16.0,
        20.0,
        MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: ColorApp.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999.0),
              ),
            ),
          ),
          const SizedBox(height: 18.0),
          Text(
            "Atur Rentang Hafalan Juz",
            style: black600.copyWith(fontSize: 16.0),
          ),
          const SizedBox(height: 4.0),
          Text(
            "Juz ${widget.juzNumber} · ${widget.startSurahName} - ${widget.endSurahName}",
            style: black400.copyWith(
              fontSize: 12.5,
              color: ColorApp.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Expanded(
                child: _AyatDropdown(
                  label: "Dari ayat",
                  value: _startAyat,
                  options: ayatOptions,
                  onChanged: (value) {
                    setState(() {
                      _startAyat = value;
                      if (_endAyat < _startAyat) {
                        _endAyat = _startAyat;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _AyatDropdown(
                  label: "Sampai ayat",
                  value: _endAyat,
                  options:
                      ayatOptions.where((item) => item >= _startAyat).toList(),
                  onChanged: (value) => setState(() => _endAyat = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: ColorApp.secondary,
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: Text(
              "Rentang terpilih: ayat juz $_startAyat - $_endAyat",
              style: primary600.copyWith(fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 18.0),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorApp.primary,
                    side: BorderSide(
                      color: ColorApp.primary.withValues(alpha: 0.28),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                  ),
                  child: const Text("Batal"),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Get.toNamed(
                      RouteScreen.hafizhDetail,
                      arguments: {
                        "category": "juz",
                        "number": widget.juzNumber,
                        "startAyat": _startAyat,
                        "endAyat": _endAyat,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorApp.primary,
                    foregroundColor: ColorApp.white,
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                  ),
                  child: const Text("Mulai Hafalan"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
