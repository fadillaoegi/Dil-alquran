import 'package:dilalquran/modules/detail_surah/detail_controller.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DetailSurahScreen extends GetView<DetailSurahController> {
  const DetailSurahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Detail Surah",
          style: black600.copyWith(fontSize: 18.0),
        ),
      ),
      body: Container(
        height: MediaQuery.sizeOf(context).height,
        width: MediaQuery.sizeOf(context).width,
        padding: const EdgeInsets.all(10.0),
        decoration: const BoxDecoration(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: MediaQuery.sizeOf(context).width,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      Text(
                        "Nama~Surah",
                        style: black600.copyWith(fontSize: 18.0),
                      ),
                      Text(
                        "(Arti Surah)",
                        style: black500.copyWith(fontSize: 16.0),
                      ),
                      Text(
                        "Surah 00 | Ayat 00",
                        style: black400.copyWith(fontSize: 16.0),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
