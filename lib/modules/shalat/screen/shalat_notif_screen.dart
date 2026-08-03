import 'package:dilalquran/modules/shalat/controller/shalat_controller.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ShalatNotifScreen extends GetView<ShalatController> {
  const ShalatNotifScreen({super.key});

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
          "Notifikasi & Adzan",
          style: primary700.copyWith(fontSize: 18.0, color: ColorApp.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 28.0),
        children: [
          _buildMasterToggle(context),
          const SizedBox(height: 20.0),
          _buildNotificationSupportCard(),
          Obx(() {
            if (!controller.isNotificationEnabled.value) {
              return _buildDisabledInfo();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackgroundCard(context),
                const SizedBox(height: 20.0),
                Row(
                  children: [
                    Expanded(
                      child: Text("Waktu Sholat yang Diingatkan",
                          style: primary700.copyWith(fontSize: 15.0)),
                    ),
                    Obx(() {
                      final all = controller.allPrayersEnabled;
                      return GestureDetector(
                        onTap: () => controller.setAllPrayers(!all),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              all
                                  ? Icons.remove_done_rounded
                                  : Icons.done_all_rounded,
                              size: 15.0,
                              color: ColorApp.primary,
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              all ? "Kosongkan" : "Pilih semua",
                              style: primary600.copyWith(fontSize: 12.0),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 4.0),
                Obx(
                  () => Text(
                    "${controller.enabledPrayerCount} dari ${ShalatController.prayerNames.length} waktu dipilih.",
                    style: black400.copyWith(
                      fontSize: 12.5,
                      color: ColorApp.black.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                _buildPrayerSettings(context),
                const SizedBox(height: 24.0),
                _buildTestScheduleButton(),
              ],
            );
          }),
        ],
      ),
    );
  }

  // Tombol diagnosa chunky: jadwalkan notifikasi tes 1 menit lagi untuk
  // memastikan notifikasi terjadwal benar-benar muncul di perangkat.
  Widget _buildTestScheduleButton() {
    return GestureDetector(
      onTap: controller.scheduleTestNotificationSoon,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15.0),
        decoration: BoxDecoration(
          color: ColorApp.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: ColorApp.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorApp.primary.withValues(alpha: 0.18),
              offset: const Offset(0, 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.timer_outlined,
              color: ColorApp.primary,
              size: 20.0,
            ),
            const SizedBox(width: 10.0),
            Text(
              "Tes Notifikasi Terjadwal (1 menit)",
              style: primary700.copyWith(fontSize: 14.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSupportCard() {
    return Obx(() {
      final notifOk = controller.isNotificationPermissionGranted.value;
      final exactOk = controller.isExactAlarmPermissionGranted.value;
      final fullyReady = notifOk && exactOk;
      final accent = fullyReady ? ColorApp.primary : const Color(0xffd98a1f);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: fullyReady
              ? ColorApp.primary.withValues(alpha: 0.06)
              : const Color(0xfffdf3e2),
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.18),
              offset: const Offset(0, 4),
              blurRadius: 0,
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
                    color: accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    fullyReady
                        ? Icons.notifications_active_rounded
                        : Icons.notification_important_rounded,
                    color: accent,
                    size: 22.0,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Cek Dukungan Notifikasi",
                        style: primary700.copyWith(
                          fontSize: 14.5,
                          color: ColorApp.black,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        fullyReady
                            ? "Izin notifikasi dan alarm presisi sudah siap."
                            : "Jika tes 1 menit atau adzan tidak bunyi di rilis, cek pengaturan sistem ini dulu.",
                        style: black400.copyWith(
                          fontSize: 12.0,
                          color: ColorApp.black.withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14.0),
            _supportStatusRow(
              label: "Izin notifikasi",
              ok: notifOk,
              actionLabel: "Buka Izin",
              onTap: controller.openNotificationSettings,
            ),
            const SizedBox(height: 10.0),
            _supportStatusRow(
              label: "Alarm presisi 1 menit",
              ok: exactOk,
              actionLabel: "Buka Alarm",
              onTap: controller.openExactAlarmSettings,
            ),
            const SizedBox(height: 10.0),
            _supportActionRow(
              label: "Suara channel adzan",
              subtitle:
                  "Buka channel agar bisa cek sound, importance, dan apakah user sempat mengubahnya ke silent.",
              actionLabel: "Buka Channel Adzan",
              onTap: controller.openAdzanChannelSettings,
            ),
          ],
        ),
      );
    });
  }

  Widget _supportStatusRow({
    required String label,
    required bool ok,
    required String actionLabel,
    required Future<void> Function() onTap,
  }) {
    final color = ok ? ColorApp.primary : const Color(0xffd98a1f);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: primary700.copyWith(fontSize: 13.0)),
              const SizedBox(height: 3.0),
              Row(
                children: [
                  Container(
                    width: 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    ok ? "Siap" : "Perlu dicek",
                    style: primary600.copyWith(fontSize: 12.5, color: color),
                  ),
                ],
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () async => onTap(),
          child: Text(actionLabel, style: primary700.copyWith(fontSize: 12.5)),
        ),
      ],
    );
  }

  Widget _supportActionRow({
    required String label,
    required String subtitle,
    required String actionLabel,
    required Future<void> Function() onTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: primary700.copyWith(fontSize: 13.0)),
              const SizedBox(height: 3.0),
              Text(
                subtitle,
                style: black400.copyWith(
                  fontSize: 12.0,
                  color: ColorApp.black.withValues(alpha: 0.6),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10.0),
        TextButton(
          onPressed: () async => onTap(),
          child: Text(actionLabel, style: primary700.copyWith(fontSize: 12.5)),
        ),
      ],
    );
  }

  // Kartu status "berjalan di latar belakang" (pengecualian optimasi baterai).
  // Memastikan notifikasi tetap muncul saat aplikasi ditutup.
  Widget _buildBackgroundCard(BuildContext context) {
    return Obx(() {
      final ok = controller.isIgnoringBatteryOptimization.value;
      final accent = ok ? ColorApp.primary : const Color(0xffd98a1f);
      final bg = ok
          ? ColorApp.primary.withValues(alpha: 0.06)
          : const Color(0xfffdf3e2);
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.18),
              offset: const Offset(0, 4),
              blurRadius: 0,
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
                    color: accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    ok ? Icons.verified_rounded : Icons.battery_alert_rounded,
                    color: accent,
                    size: 22.0,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Berjalan di Latar Belakang",
                        style: primary700.copyWith(
                          fontSize: 14.5,
                          color: ColorApp.black,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        ok
                            ? "Aktif — notifikasi tetap berbunyi walau aplikasi ditutup."
                            : "Belum aktif — OS bisa mematikan alarm saat aplikasi ditutup.",
                        style: black400.copyWith(
                          fontSize: 12.0,
                          color: ColorApp.black.withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!ok) ...[
              const SizedBox(height: 14.0),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14.0),
                    onTap: controller.requestBackgroundPermission,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(14.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xff9c5f10),
                            offset: Offset(0, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_circle_fill_rounded,
                            color: ColorApp.white,
                            size: 18.0,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            "Izinkan Berjalan di Latar Belakang",
                            style: white700.copyWith(fontSize: 13.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildMasterToggle(BuildContext context) {
    return Obx(() {
      final enabled = controller.isNotificationEnabled.value;
      return Container(
        padding: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color: enabled ? null : ColorApp.white,
          gradient: enabled
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff11623f), Color(0xff2f9e69)],
                )
              : null,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: enabled
                ? Colors.transparent
                : ColorApp.primary.withValues(alpha: 0.12),
            width: 1.5,
          ),
          // Hard offset shadow — chunky 3D (kreate.gg).
          boxShadow: [
            BoxShadow(
              color: enabled
                  ? const Color(0xff0a3d29)
                  : ColorApp.primary.withValues(alpha: 0.16),
              offset: const Offset(0, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: enabled
                    ? ColorApp.white.withValues(alpha: 0.2)
                    : ColorApp.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                enabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                color: enabled ? ColorApp.white : ColorApp.primary,
                size: 26.0,
              ),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pengingat Waktu Sholat",
                    style: (enabled ? white700 : black600).copyWith(
                      fontSize: 15.0,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    enabled ? "Aktif" : "Nonaktif",
                    style: (enabled ? white400 : black400).copyWith(
                      fontSize: 12.5,
                      color: enabled
                          ? ColorApp.white.withValues(alpha: 0.85)
                          : ColorApp.black.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              activeThumbColor: ColorApp.white,
              activeTrackColor: ColorApp.accent,
              onChanged: (value) =>
                  controller.toggleNotification(value, context),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDisabledInfo() {
    return Padding(
      padding: const EdgeInsets.only(top: 28.0),
      child: Column(
        children: [
          Icon(
            Icons.notifications_paused_rounded,
            size: 64.0,
            color: ColorApp.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12.0),
          Text(
            "Pengingat sholat nonaktif",
            style: black600.copyWith(fontSize: 14.0),
          ),
          const SizedBox(height: 4.0),
          Text(
            "Aktifkan untuk memilih waktu sholat dan nada dering adzan.",
            textAlign: TextAlign.center,
            style: black400.copyWith(
              fontSize: 12.5,
              color: ColorApp.black.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  static const Map<String, IconData> _prayerIcons = {
    "Subuh": Icons.wb_twilight_rounded,
    "Dzuhur": Icons.wb_sunny_rounded,
    "Ashar": Icons.cloud_rounded,
    "Maghrib": Icons.brightness_3_rounded,
    "Isya": Icons.nightlight_round,
  };

  Widget _buildPrayerSettings(BuildContext context) {
    return Obx(
      () => Column(
        children: ShalatController.prayerNames.map((prayer) {
          final enabled = controller.isPrayerEnabled(prayer);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GestureDetector(
              onTap: () => _showPrayerModeDialog(context, prayer),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: ColorApp.white,
                  borderRadius: BorderRadius.circular(18.0),
                  border: Border.all(
                    color: enabled
                        ? ColorApp.primary
                        : ColorApp.primary.withValues(alpha: 0.14),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: enabled
                          ? ColorApp.primary.withValues(alpha: 0.18)
                          : ColorApp.primary.withValues(alpha: 0.1),
                      offset: const Offset(0, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: enabled
                            ? ColorApp.primary.withValues(alpha: 0.12)
                            : ColorApp.secondary,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Icon(
                        _prayerIcons[prayer] ?? Icons.schedule_rounded,
                        size: 20.0,
                        color: ColorApp.primary,
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(prayer,
                              style: black600.copyWith(fontSize: 14.0)),
                          const SizedBox(height: 3.0),
                          Text(
                            controller.prayerModeLabel(prayer),
                            style: black400.copyWith(
                              fontSize: 12.5,
                              color: enabled
                                  ? ColorApp.primary
                                  : ColorApp.black.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      enabled
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: enabled
                          ? ColorApp.primary
                          : ColorApp.black.withValues(alpha: 0.25),
                    ),
                    const SizedBox(width: 8.0),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: ColorApp.black.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showPrayerModeDialog(
    BuildContext context,
    String prayer,
  ) async {
    final options = <Map<String, String>>[
      {
        'value': ShalatController.notificationModeAdzan,
        'label': 'Suara adzan',
      },
      {
        'value': ShalatController.notificationModeDevice,
        'label': 'Suara ringtone sistem',
      },
      {
        'value': ShalatController.notificationModeSilent,
        'label': 'Tanpa suara (notif saja)',
      },
      {
        'value': ShalatController.notificationModeOff,
        'label': 'Nonaktif',
      },
    ];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Obx(() {
          final selectedMode = controller.prayerNotificationModes[prayer] ??
              ShalatController.notificationModeAdzan;
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: ColorApp.white,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: const Color(0xff0d4e34), width: 2.0),
                // Hard offset shadow — chunky 3D.
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xff0c3f2a),
                    offset: Offset(0, 8),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: ColorApp.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: ColorApp.primary,
                          size: 20.0,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Text(
                          "Atur Notifikasi $prayer",
                          style: primary700.copyWith(
                            fontSize: 16.0,
                            color: ColorApp.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18.0),
                  ...options.map((option) {
                    final value = option['value']!;
                    final label = option['label']!;
                    final selected = selectedMode == value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          await controller.setPrayerNotificationMode(
                              prayer, value);
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14.0, vertical: 12.0),
                          decoration: BoxDecoration(
                            gradient: selected
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xff11623f),
                                      Color(0xff2f9e69),
                                    ],
                                  )
                                : null,
                            color: selected ? null : ColorApp.white,
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: selected
                                  ? Colors.transparent
                                  : ColorApp.primary.withValues(alpha: 0.18),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: selected
                                    ? const Color(0xff0a3d29)
                                    : ColorApp.primary.withValues(alpha: 0.14),
                                offset: const Offset(0, 4),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Indikator pilih chunky.
                              Container(
                                width: 24.0,
                                height: 24.0,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? ColorApp.white
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? ColorApp.white
                                        : ColorApp.black.withValues(alpha: 0.3),
                                    width: 2.0,
                                  ),
                                ),
                                child: selected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 16.0,
                                        color: ColorApp.primary,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14.0),
                              Expanded(
                                child: Text(
                                  label,
                                  style: black500.copyWith(
                                    fontSize: 13.5,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? ColorApp.white
                                        : ColorApp.black,
                                  ),
                                ),
                              ),
                              if (value != ShalatController.notificationModeOff)
                                _dialogPlayButton(
                                  selected: selected,
                                  isPlaying: controller
                                          .currentlyPlayingPreview.value ==
                                      value,
                                  onTap: () async {
                                    await controller
                                        .previewPrayerNotificationMode(
                                      prayer,
                                      value,
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 4.0),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _DialogCancelButton(
                      onTap: () => Navigator.of(dialogContext).pop(),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // Tombol preview ("Coba") chunky di dalam dialog. Menyesuaikan warna saat
  // opsi terpilih (kartu hijau) vs belum (kartu putih).
  Widget _dialogPlayButton({
    required bool selected,
    required bool isPlaying,
    required VoidCallback onTap,
  }) {
    // Material + InkWell: memberi efek ripple (jelas bisa diklik), tooltip,
    // dan haptic. Sebagai widget interaktif, tap-nya andal menang atas area
    // baris di belakangnya (tidak ikut memilih & menutup dialog).
    return Tooltip(
      message: isPlaying ? "Hentikan suara" : "Tes suara notifikasi",
      child: Material(
        color: selected
            ? ColorApp.white.withValues(alpha: 0.22)
            : ColorApp.primary.withValues(alpha: 0.10),
        shape: CircleBorder(
          side: BorderSide(
            color: selected
                ? ColorApp.white.withValues(alpha: 0.55)
                : ColorApp.primary.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          splashColor: selected
              ? ColorApp.white.withValues(alpha: 0.35)
              : ColorApp.primary.withValues(alpha: 0.25),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(
            width: 42.0,
            height: 42.0,
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 22.0,
              color: selected ? ColorApp.white : ColorApp.primary,
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildTestButton() — dihapus
}

class _DialogCancelButton extends StatefulWidget {
  const _DialogCancelButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_DialogCancelButton> createState() => _DialogCancelButtonState();
}

class _DialogCancelButtonState extends State<_DialogCancelButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _pressed
              ? ColorApp.primary.withValues(alpha: 0.06)
              : ColorApp.white,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: ColorApp.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorApp.primary.withValues(alpha: 0.18),
              offset: Offset(0, _pressed ? 2 : 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14.0),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (value) {
              if (!mounted) return;
              setState(() => _pressed = value);
            },
            splashColor: ColorApp.primary.withValues(alpha: 0.14),
            highlightColor: ColorApp.primary.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 22.0,
                vertical: 10.0,
              ),
              child: Text(
                "Batal",
                style: primary700.copyWith(fontSize: 13.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
