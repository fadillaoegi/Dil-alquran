import 'package:dilalquran/modules/shalat/controller/shalat_controller.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShalatScreen extends GetView<ShalatController> {
  const ShalatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.secondary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ColorApp.primary,
        centerTitle: true,
        title: Text(
          "Jadwal Shalat",
          style: primary700.copyWith(fontSize: 20.0, color: ColorApp.white),
        ),
        iconTheme: const IconThemeData(color: ColorApp.white),
        actions: [
          Obx(() => Switch(
                value: controller.isNotificationEnabled.value,
                onChanged: (val) {
                  controller.toggleNotification(val, context);
                },
                activeThumbColor: ColorApp.white,
                activeTrackColor: ColorApp.primary.withValues(alpha: 0.5),
              )),
        ],
      ),
      body: Column(
        children: [
          // Header / Filter
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: ColorApp.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Pilih Lokasi Anda", style: primary700.copyWith(fontSize: 16)),
                const SizedBox(height: 12),
                // Dropdown Provinsi
                Obx(() {
                  if (controller.isLoadingProvinsi.value) {
                    return const LinearProgressIndicator();
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return DropdownMenu<String>(
                        width: constraints.maxWidth,
                        enableFilter: true,
                        requestFocusOnTap: true,
                        inputDecorationTheme: InputDecorationTheme(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          fillColor: ColorApp.secondary,
                          filled: true,
                        ),
                        hintText: "Pilih Provinsi",
                        initialSelection: controller.selectedProvinsi.value.isEmpty ? null : controller.selectedProvinsi.value,
                        dropdownMenuEntries: controller.listProvinsi.map((prov) {
                          return DropdownMenuEntry<String>(value: prov, label: prov);
                        }).toList(),
                        onSelected: (val) {
                          if (val != null) {
                            controller.fetchKabKota(val);
                          }
                        },
                      );
                    }
                  );
                }),
                const SizedBox(height: 12),
                // Dropdown KabKota
                Obx(() {
                  if (controller.isLoadingKabKota.value) {
                    return const LinearProgressIndicator();
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return DropdownMenu<String>(
                        width: constraints.maxWidth,
                        enableFilter: true,
                        requestFocusOnTap: true,
                        inputDecorationTheme: InputDecorationTheme(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          fillColor: ColorApp.secondary,
                          filled: true,
                        ),
                        hintText: "Pilih Kabupaten/Kota",
                        initialSelection: controller.selectedKabKota.value.isEmpty ? null : controller.selectedKabKota.value,
                        dropdownMenuEntries: controller.listKabKota.map((kota) {
                          return DropdownMenuEntry<String>(value: kota, label: kota);
                        }).toList(),
                        onSelected: (val) {
                          if (val != null) {
                            controller.onKabKotaSelected(val);
                          }
                        },
                      );
                    }
                  );
                }),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Obx(() {
              if (controller.isLoadingJadwal.value) {
                return const Center(child: CircularProgressIndicator(color: ColorApp.primary));
              }

              if (controller.listJadwal.isEmpty) {
                return Center(
                  child: Text(
                    "Pilih lokasi untuk melihat jadwal.",
                    style: primary400.copyWith(fontSize: 16),
                  ),
                );
              }

              // Filter to show from today onwards only
              final now = DateTime.now();
              final String todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

              // Cari index hari ini
              int startIndex = controller.listJadwal.indexWhere((j) => j.tanggalLengkap == todayStr);
              if (startIndex == -1) startIndex = 0; // fallback jika tanggal tidak cocok

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: controller.listJadwal.length - startIndex,
                itemBuilder: (context, index) {
                  final jadwal = controller.listJadwal[startIndex + index];
                  final bool isToday = jadwal.tanggalLengkap == todayStr;

                  return Card(
                    elevation: isToday ? 4 : 1,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: isToday ? const BorderSide(color: ColorApp.primary, width: 1.5) : BorderSide.none,
                    ),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        // Interactive tap effect (Ripple)
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: isToday
                              ? LinearGradient(
                                  colors: [
                                    ColorApp.primary.withValues(alpha: 0.15),
                                    ColorApp.white,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isToday ? null : ColorApp.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${jadwal.hari}, ${jadwal.tanggalLengkap}",
                                    style: primary700.copyWith(fontSize: 16, color: isToday ? ColorApp.primary : ColorApp.black),
                                  ),
                                  if (isToday)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: ColorApp.primary,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: ColorApp.primary.withValues(alpha: 0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      ),
                                      child: Text(
                                        "HARI INI",
                                        style: primary600.copyWith(fontSize: 10, color: ColorApp.white),
                                      ),
                                    )
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: ColorApp.secondary.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    _buildTimeRow("Imsak", jadwal.imsak ?? "-", Icons.nights_stay_outlined),
                                    const Divider(height: 16, thickness: 0.5),
                                    _buildTimeRow("Subuh", jadwal.subuh ?? "-", Icons.wb_twilight),
                                    const Divider(height: 16, thickness: 0.5),
                                    _buildTimeRow("Dhuha", jadwal.dhuha ?? "-", Icons.wb_sunny_outlined),
                                    const Divider(height: 16, thickness: 0.5),
                                    _buildTimeRow("Dzuhur", jadwal.dzuhur ?? "-", Icons.sunny),
                                    const Divider(height: 16, thickness: 0.5),
                                    _buildTimeRow("Ashar", jadwal.ashar ?? "-", Icons.cloud_outlined),
                                    const Divider(height: 16, thickness: 0.5),
                                    _buildTimeRow("Maghrib", jadwal.maghrib ?? "-", Icons.brightness_3),
                                    const Divider(height: 16, thickness: 0.5),
                                    _buildTimeRow("Isya", jadwal.isya ?? "-", Icons.nights_stay),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String name, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: ColorApp.primary, size: 20),
              const SizedBox(width: 12),
              Text(name, style: primary400.copyWith(fontSize: 15)),
            ],
          ),
          Text(time, style: primary600.copyWith(fontSize: 16)),
        ],
      ),
    );
  }
}
