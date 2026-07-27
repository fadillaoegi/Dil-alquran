import 'dart:io';

import 'package:dilalquran/modules/shalat/controller/shalat_controller.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';
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
          Obx(() {
            if (!controller.isNotificationEnabled.value) {
              return _buildDisabledInfo();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                _buildPrayerChips(),
                const SizedBox(height: 24.0),
                Text("Nada Dering", style: primary700.copyWith(fontSize: 15.0)),
                const SizedBox(height: 12.0),
                _buildSoundOptions(),
                const SizedBox(height: 24.0),
                _buildTestButton(),
              ],
            );
          }),
        ],
      ),
    );
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
              onChanged: (value) => controller.toggleNotification(value, context),
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

  Widget _buildPrayerChips() {
    return Obx(
      () => Wrap(
        spacing: 10.0,
        runSpacing: 10.0,
        children: ShalatController.prayerNames.map((prayer) {
          final selected = controller.enabledPrayers[prayer] ?? true;
          final fg = selected ? ColorApp.white : ColorApp.primary;
          return GestureDetector(
            onTap: () => controller.togglePrayer(prayer, !selected),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: selected ? ColorApp.primary : ColorApp.white,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(
                  color: selected
                      ? ColorApp.primary
                      : ColorApp.primary.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                // Chunky hard shadow saat terpilih.
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Color(0xff0c3f2a),
                          offset: Offset(0, 3),
                          blurRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _prayerIcons[prayer] ?? Icons.schedule_rounded,
                    size: 16.0,
                    color: fg,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    prayer,
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  // Centang muncul halus saat terpilih.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: selected
                        ? const Padding(
                            padding: EdgeInsets.only(left: 6.0),
                            child: Icon(Icons.check_rounded,
                                size: 15.0, color: ColorApp.white),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSoundOptions() {
    return Obx(
      () => Column(
        children: [
          _soundOption(
            title: "Adzan",
            subtitle: "Kumandang adzan penuh saat waktu sholat tiba",
            value: "adzan",
            icon: Icons.campaign_rounded,
          ),
          const SizedBox(height: 10.0),
          _soundOption(
            title: "Suara Sistem",
            subtitle: "Nada notifikasi bawaan perangkat",
            value: "device",
            icon: Icons.notifications_rounded,
          ),
          // Pilih ringtone/MP3 dari HP — hanya Android.
          if (Platform.isAndroid) ...[
            const SizedBox(height: 10.0),
            _soundOption(
              title: "Suara dari HP",
              subtitle: controller.notificationSound.value == 'custom' &&
                      controller.customSoundTitle.value.isNotEmpty
                  ? controller.customSoundTitle.value
                  : "Pilih ringtone atau suara di perangkat",
              value: "custom",
              icon: Icons.library_music_rounded,
              onTap: controller.pickCustomSound,
            ),
          ],
        ],
      ),
    );
  }

  Widget _soundOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final selected = controller.notificationSound.value == value;
    return GestureDetector(
      onTap: onTap ?? () => controller.changeNotificationSound(value),
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: ColorApp.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: selected
                ? ColorApp.primary
                : ColorApp.primary.withValues(alpha: 0.12),
            width: 1.5,
          ),
          // Hard offset shadow — chunky 3D (kreate.gg).
          boxShadow: [
            BoxShadow(
              color: ColorApp.primary.withValues(alpha: selected ? 0.22 : 0.12),
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
                color: ColorApp.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(icon, color: ColorApp.primary, size: 22.0),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: black600.copyWith(fontSize: 14.0)),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: black400.copyWith(
                      fontSize: 12.0,
                      color: ColorApp.black.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? ColorApp.primary
                  : ColorApp.black.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ColorApp.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: ColorApp.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
        // Hard offset shadow — tombol chunky (kreate.gg).
        boxShadow: [
          BoxShadow(
            color: ColorApp.primary.withValues(alpha: 0.16),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.0),
          onTap: controller.testNotificationSound,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.volume_up_rounded,
                    size: 18.0, color: ColorApp.primary),
                const SizedBox(width: 8.0),
                Text(
                  "Coba Notifikasi Sekarang",
                  style: primary700.copyWith(fontSize: 14.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
