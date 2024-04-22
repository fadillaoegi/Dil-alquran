// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';

// import 'package:dilalquran/main.dart';

// ignore_for_file: avoid_print

import 'package:dilalquran/modules/data/models/surah_model.dart';
import 'package:dilalquran/modules/data/sources/home_source.dart';

void main() async {
  // print("runTest");

  print(HomeSource.fetchSurah());

  List<Surah> surah = await HomeSource.fetchSurah();
  print(surah.length);

  // Surah surahh =
}
