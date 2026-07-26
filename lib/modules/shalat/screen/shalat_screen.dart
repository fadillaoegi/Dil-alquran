import 'dart:async';

import 'package:dilalquran/modules/shalat/controller/shalat_controller.dart';
import 'package:dilalquran/modules/shalat/model/shalat_model.dart';
import 'package:dilalquran/routes/route.dart';
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
          // Deteksi ulang lokasi sesuai posisi HP.
          Obx(() {
            if (controller.isDetectingLocation.value) {
              return const Padding(
                padding: EdgeInsets.all(14.0),
                child: SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.0, color: ColorApp.white),
                ),
              );
            }
            return IconButton(
              tooltip: "Gunakan lokasi HP",
              icon: const Icon(Icons.my_location_rounded, color: ColorApp.white),
              onPressed: controller.useCurrentLocation,
            );
          }),
          IconButton(
            tooltip: "Notifikasi & Adzan",
            icon: const Icon(Icons.notifications_none_rounded,
                color: ColorApp.white),
            onPressed: () => Get.toNamed(RouteScreen.shalatNotif),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLocationCard(),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingJadwal.value) {
                return const Center(
                  child: CircularProgressIndicator(color: ColorApp.primary),
                );
              }

              if (controller.listJadwal.isEmpty) {
                return RefreshIndicator(
                  color: ColorApp.primary,
                  onRefresh: controller.refreshJadwal,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 100),
                      _buildEmptyState(),
                    ],
                  ),
                );
              }

              final now = DateTime.now();
              final todayStr =
                  "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

              var startIndex = controller.listJadwal
                  .indexWhere((j) => j.tanggalLengkap == todayStr);
              if (startIndex == -1) startIndex = 0;

              final dayCount = controller.listJadwal.length - startIndex;

              return RefreshIndicator(
                color: ColorApp.primary,
                onRefresh: controller.refreshJadwal,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
                  itemCount: dayCount + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) return const _NextPrayerCard();
                    if (index == 1) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 12.0),
                        child: Text(
                          "Jadwal Berikutnya",
                          style: primary700.copyWith(fontSize: 16.0),
                        ),
                      );
                    }
                    final jadwal =
                        controller.listJadwal[startIndex + index - 2];
                    return _buildDayCard(jadwal, todayStr);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_rounded,
                size: 56.0, color: ColorApp.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 12.0),
            Text(
              "Pilih lokasi untuk melihat jadwal sholat.",
              textAlign: TextAlign.center,
              style: primary400.copyWith(fontSize: 14.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: ColorApp.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: ColorApp.primary, size: 20.0),
              const SizedBox(width: 6.0),
              Text("Lokasi Anda", style: primary700.copyWith(fontSize: 16.0)),
            ],
          ),
          const SizedBox(height: 12.0),
          Obx(() {
            if (controller.isLoadingProvinsi.value) {
              return const LinearProgressIndicator();
            }
            return _InlineSearchSelect(
              fieldKey: ValueKey("prov_${controller.selectedProvinsi.value}"),
              hintText: "Pilih Provinsi",
              selectedValue: controller.selectedProvinsi.value,
              items: controller.listProvinsi.toList(),
              onSelected: controller.fetchKabKota,
              emptyText: "Provinsi tidak ditemukan",
            );
          }),
          const SizedBox(height: 12.0),
          Obx(() {
            if (controller.isLoadingKabKota.value) {
              return const LinearProgressIndicator();
            }
            return _InlineSearchSelect(
              fieldKey: ValueKey("kota_${controller.selectedKabKota.value}"),
              hintText: "Pilih Kabupaten/Kota",
              selectedValue: controller.selectedKabKota.value,
              items: controller.listKabKota.toList(),
              enabled: controller.listKabKota.isNotEmpty,
              onSelected: controller.onKabKotaSelected,
              emptyText: controller.selectedProvinsi.value.isEmpty
                  ? "Pilih provinsi terlebih dahulu"
                  : "Kabupaten/Kota tidak ditemukan",
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDayCard(ShalatModel jadwal, String todayStr) {
    final isToday = jadwal.tanggalLengkap == todayStr;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: ColorApp.white,
        borderRadius: BorderRadius.circular(16.0),
        border: isToday
            ? Border.all(color: ColorApp.primary, width: 1.5)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isToday ? 0.08 : 0.03),
            blurRadius: isToday ? 10.0 : 6.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: isToday
              ? LinearGradient(
                  colors: [
                    ColorApp.primary.withValues(alpha: 0.12),
                    ColorApp.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "${jadwal.hari}, ${jadwal.tanggalLengkap}",
                      style: primary700.copyWith(
                        fontSize: 15.0,
                        color: isToday ? ColorApp.primary : ColorApp.black,
                      ),
                    ),
                  ),
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: ColorApp.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "HARI INI",
                        style: primary600.copyWith(
                            fontSize: 10, color: ColorApp.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: ColorApp.secondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  children: [
                    _buildTimeRow(
                        "Imsak", jadwal.imsak ?? "-", Icons.nights_stay_outlined),
                    const Divider(height: 16, thickness: 0.5),
                    _buildTimeRow("Subuh", jadwal.subuh ?? "-", Icons.wb_twilight),
                    const Divider(height: 16, thickness: 0.5),
                    _buildTimeRow(
                        "Dhuha", jadwal.dhuha ?? "-", Icons.wb_sunny_outlined),
                    const Divider(height: 16, thickness: 0.5),
                    _buildTimeRow("Dzuhur", jadwal.dzuhur ?? "-", Icons.sunny),
                    const Divider(height: 16, thickness: 0.5),
                    _buildTimeRow("Ashar", jadwal.ashar ?? "-", Icons.cloud_outlined),
                    const Divider(height: 16, thickness: 0.5),
                    _buildTimeRow(
                        "Maghrib", jadwal.maghrib ?? "-", Icons.brightness_3),
                    const Divider(height: 16, thickness: 0.5),
                    _buildTimeRow("Isya", jadwal.isya ?? "-", Icons.nights_stay),
                  ],
                ),
              ),
            ],
          ),
        ),
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

class _InlineSearchSelect extends StatefulWidget {
  const _InlineSearchSelect({
    required this.fieldKey,
    required this.hintText,
    required this.selectedValue,
    required this.items,
    required this.onSelected,
    required this.emptyText,
    this.enabled = true,
  });

  final Key fieldKey;
  final String hintText;
  final String selectedValue;
  final List<String> items;
  final ValueChanged<String> onSelected;
  final String emptyText;
  final bool enabled;

  @override
  State<_InlineSearchSelect> createState() => _InlineSearchSelectState();
}

class _InlineSearchSelectState extends State<_InlineSearchSelect> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.selectedValue);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _InlineSearchSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValue != oldWidget.selectedValue &&
        widget.selectedValue != _textController.text) {
      _textController.text = widget.selectedValue;
    }

    if (!widget.enabled && _expanded) {
      setState(() => _expanded = false);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && mounted) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted || _focusNode.hasFocus) return;
        setState(() {
          _expanded = false;
          _textController.text = widget.selectedValue;
        });
      });
    }
  }

  List<String> get _filteredItems {
    final query = _textController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.items;
    return widget.items
        .where((item) => item.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    final showPanel = _expanded && widget.enabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: widget.fieldKey,
          controller: _textController,
          focusNode: _focusNode,
          enabled: widget.enabled,
          onTap: () {
            if (widget.enabled) {
              setState(() => _expanded = true);
            }
          },
          onChanged: (_) {
            if (!_expanded && widget.enabled) {
              setState(() => _expanded = true);
            } else {
              setState(() {});
            }
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            filled: true,
            fillColor: widget.enabled
                ? ColorApp.secondary
                : ColorApp.secondary.withValues(alpha: 0.55),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: ColorApp.primary,
              size: 20.0,
            ),
            suffixIcon: widget.enabled
                ? IconButton(
                    tooltip: _expanded ? "Tutup daftar" : "Buka daftar",
                    onPressed: () {
                      if (_expanded) {
                        _focusNode.unfocus();
                        setState(() {
                          _expanded = false;
                          _textController.text = widget.selectedValue;
                        });
                      } else {
                        _focusNode.requestFocus();
                        setState(() => _expanded = true);
                      }
                    },
                    icon: Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: ColorApp.primary,
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: ColorApp.primary,
                width: 1.2,
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: showPanel
              ? Container(
                  margin: const EdgeInsets.only(top: 8.0),
                  constraints: const BoxConstraints(maxHeight: 220.0),
                  decoration: BoxDecoration(
                    color: ColorApp.white,
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(
                      color: ColorApp.primary.withValues(alpha: 0.14),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: items.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Text(
                            widget.emptyText,
                            style: black400.copyWith(
                              fontSize: 12.5,
                              color: ColorApp.black.withValues(alpha: 0.6),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 14.0,
                            endIndent: 14.0,
                            color: ColorApp.black.withValues(alpha: 0.06),
                          ),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final selected = item == widget.selectedValue;
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _textController.text = item;
                                  _focusNode.unfocus();
                                  setState(() => _expanded = false);
                                  widget.onSelected(item);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14.0,
                                    vertical: 12.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item,
                                          style: (selected
                                                  ? primary600
                                                  : black500)
                                              .copyWith(fontSize: 13.5),
                                        ),
                                      ),
                                      if (selected)
                                        const Icon(
                                          Icons.check_rounded,
                                          size: 18.0,
                                          color: ColorApp.primary,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// Kartu waktu sholat berikutnya + hitung mundur yang berdetak tiap detik.
class _NextPrayerCard extends StatefulWidget {
  const _NextPrayerCard();

  @override
  State<_NextPrayerCard> createState() => _NextPrayerCardState();
}

class _NextPrayerCardState extends State<_NextPrayerCard> {
  final ShalatController controller = Get.find<ShalatController>();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCountdown(Duration d) {
    final total = d.isNegative ? Duration.zero : d;
    final h = total.inHours.toString().padLeft(2, '0');
    final m = (total.inMinutes % 60).toString().padLeft(2, '0');
    final s = (total.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final next = controller.nextPrayer;
      final today = controller.todaySchedule;
      if (next == null) return const SizedBox.shrink();

      final remaining = next.time.difference(DateTime.now());

      return Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff0d4e34), ColorApp.primary],
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
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 14.0,
                            color: ColorApp.white.withValues(alpha: 0.85)),
                        const SizedBox(width: 6.0),
                        Text(
                          "Menuju waktu sholat",
                          style: white400.copyWith(
                            fontSize: 12.0,
                            color: ColorApp.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    Text(next.name, style: white700.copyWith(fontSize: 28.0)),
                    Text(
                      _formatTime(next.time),
                      style: white400.copyWith(
                        fontSize: 13.0,
                        color: ColorApp.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: ColorApp.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999.0),
                        border: Border.all(
                          color: ColorApp.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 13.0,
                            color: ColorApp.white.withValues(alpha: 0.92),
                          ),
                          const SizedBox(width: 5.0),
                          Text(
                            controller.locationLabel,
                            style: white400.copyWith(
                              fontSize: 11.5,
                              color: ColorApp.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Hitung mundur",
                      style: white400.copyWith(
                        fontSize: 11.0,
                        color: ColorApp.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      _formatCountdown(remaining),
                      style: white700.copyWith(
                        fontSize: 24.0,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (today != null) ...[
              const SizedBox(height: 18.0),
              _buildTodayPills(today, next.name),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildTodayPills(ShalatModel today, String nextName) {
    final pills = <List<dynamic>>[
      ["Subuh", today.subuh, Icons.wb_twilight],
      ["Dzuhur", today.dzuhur, Icons.sunny],
      ["Ashar", today.ashar, Icons.cloud_outlined],
      ["Maghrib", today.maghrib, Icons.brightness_3],
      ["Isya", today.isya, Icons.nights_stay],
    ];

    return Row(
      children: pills.map((p) {
        final name = p[0] as String;
        final time = p[1] as String?;
        final icon = p[2] as IconData;
        final highlight = name == nextName;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3.0),
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
            decoration: BoxDecoration(
              color: highlight
                  ? ColorApp.white
                  : ColorApp.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 16.0,
                  color: highlight ? ColorApp.primary : ColorApp.white,
                ),
                const SizedBox(height: 4.0),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w500,
                    color: highlight
                        ? ColorApp.primary
                        : ColorApp.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  time ?? "-",
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: highlight ? ColorApp.primary : ColorApp.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
