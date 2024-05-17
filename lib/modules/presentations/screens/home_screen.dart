import 'package:dilalquran/routes/route.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:dilalquran/widgets/list_surahayat_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shape: Border.all(
          color: Colors.white,
        ),
        backgroundColor: ColorApp.primary,
        title: Text(
          "Al~Quran",
          textAlign: TextAlign.center,
          style: dancing700.copyWith(fontSize: 36.0),
        ),
      ),
      body: Container(
        height: MediaQuery.sizeOf(context).height,
        width: MediaQuery.sizeOf(context).width,
        margin: const EdgeInsets.all(0.0),
        decoration: BoxDecoration(color: ColorApp.primary),
        child: ListView.builder(
          itemCount: 10,
          itemBuilder: (context, index) {
            int i = index++;
            return ListSurahAyat(
              i: i,
              onTap: () {
                Get.toNamed(RouteScreen.detailSurah);
              },
            );
          },
        ),
      ),
    );
  }
}
