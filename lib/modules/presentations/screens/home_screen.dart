import 'package:dilalquran/routes/route.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
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
          style: white700,
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
            return ListTile(
              onTap: () {
                Get.toNamed(RouteScreen.detailSurah);
              },
              leading: CircleAvatar(
                child: Center(
                  child: Text("${i + 1}"),
                ),
              ),
              title: Text(
                "Surah ke-${i + 1}",
                style: white500.copyWith(fontSize: 14.0),
              ),
              subtitle: Text(
                "Subtitle ke-${i + 1}",
                style: white400.copyWith(fontSize: 12.0),
              ),
              trailing: Text(
                "Trailing ke-${i + 1}",
                style: white400.copyWith(fontSize: 12.0),
              ),
            );
          },
        ),
      ),
    );
  }
}
