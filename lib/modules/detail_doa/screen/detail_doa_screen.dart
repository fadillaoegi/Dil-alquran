import 'package:dilalquran/modules/detail_doa/controller/detail_doa_controller.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const _detailDoaBorderColor = Color(0xFFD3D3D3);
const _detailDoaBaseShadowColor = Color(0xFFCFCFCF);

class DetailDoaScreen extends GetView<DetailDoaController> {
  const DetailDoaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final doa = controller.doa.value;
      if (doa == null) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: ColorApp.primary,
            iconTheme: const IconThemeData(color: ColorApp.white),
          ),
          body: const Center(
            child: Text("Data doa tidak ditemukan"),
          ),
        );
      }

      return Scaffold(
        backgroundColor: ColorApp.secondary,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: ColorApp.primary,
          title: Text(
            doa.nama ?? "Detail Doa",
            style: primary700.copyWith(
              fontSize: 18.0,
              color: ColorApp.white,
            ),
          ),
          iconTheme: const IconThemeData(color: ColorApp.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: _PressableDoaCard(
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
                      color: _detailDoaBaseShadowColor,
                      borderRadius: BorderRadius.circular(22.0),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: ColorApp.white,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: _detailDoaBorderColor,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: ColorApp.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "${doa.id}",
                              style: primary600.copyWith(fontSize: 12.0),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Text(
                              doa.nama ?? "Doa",
                              style: primary700.copyWith(
                                fontSize: 18.0,
                                color: ColorApp.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          doa.ar ?? "",
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 28.0,
                            height: 1.8,
                            fontWeight: FontWeight.w700,
                            color: ColorApp.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Text(
                        doa.tr ?? "",
                        style: const TextStyle(
                          color: ColorApp.primary,
                          fontSize: 15.0,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        doa.idn ?? "",
                        style: TextStyle(
                          color: ColorApp.black.withValues(alpha: 0.8),
                          fontSize: 15.0,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (doa.tentang != null && doa.tentang!.isNotEmpty) ...[
                        const SizedBox(height: 20.0),
                        const Divider(),
                        const SizedBox(height: 12.0),
                        Text(
                          "Keterangan / Sumber:",
                          style: primary600.copyWith(
                            fontSize: 14.0,
                            color: ColorApp.black,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          doa.tentang!,
                          style: TextStyle(
                            color: ColorApp.black.withValues(alpha: 0.6),
                            fontSize: 13.0,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _PressableDoaCard extends StatefulWidget {
  const _PressableDoaCard({required this.child});

  final Widget child;

  @override
  State<_PressableDoaCard> createState() => _PressableDoaCardState();
}

class _PressableDoaCardState extends State<_PressableDoaCard> {
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
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
