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
                Text("Waktu Sholat yang Diingatkan",
                    style: primary700.copyWith(fontSize: 15.0)),
                const SizedBox(height: 4.0),
                Text(
                  "Pilih waktu sholat yang ingin dibunyikan notifikasinya.",
                  style: black400.copyWith(
                    fontSize: 12.5,
                    color: ColorApp.black.withValues(alpha: 0.6),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: enabled
                ? const [Color(0xff0d4e34), ColorApp.primary]
                : [ColorApp.white, ColorApp.white],
          ),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: enabled
                ? Colors.transparent
                : ColorApp.primary.withValues(alpha: 0.15),
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: ColorApp.primary.withValues(alpha: 0.3),
                    blurRadius: 16.0,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
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

  Widget _buildPrayerChips() {
    return Obx(
      () => Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: ShalatController.prayerNames.map((prayer) {
          final selected = controller.enabledPrayers[prayer] ?? true;
          return FilterChip(
            label: Text(prayer),
            selected: selected,
            showCheckmark: false,
            onSelected: (value) => controller.togglePrayer(prayer, value),
            labelStyle: TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
              color: selected ? ColorApp.white : ColorApp.primary,
            ),
            backgroundColor: ColorApp.white,
            selectedColor: ColorApp.primary,
            side: BorderSide(color: ColorApp.primary.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
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
            width: selected ? 1.5 : 1.0,
          ),
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
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: controller.testNotificationSound,
        icon: const Icon(Icons.volume_up_rounded, size: 18.0),
        label: const Text("Coba Notifikasi Sekarang"),
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorApp.primary,
          side: BorderSide(color: ColorApp.primary.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
    );
  }
}
