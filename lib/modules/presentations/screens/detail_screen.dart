import 'package:dilalquran/modules/presentations/controllers/detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DetailSurahScreen extends GetView<DetailSurahController> {
  const DetailSurahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.sizeOf(context).height,
        width: MediaQuery.sizeOf(context).width,
        decoration: const BoxDecoration(),
        child: const Column(
          children: [Text("data")],
        ),
      ),
    );
  }
}
