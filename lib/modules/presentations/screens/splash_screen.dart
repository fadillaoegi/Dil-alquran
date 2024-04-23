import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.sizeOf(context).height,
        width: MediaQuery.sizeOf(context).width,
        margin: const EdgeInsets.all(0.0),
        decoration: BoxDecoration(color: ColorApp.primary),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Dil ~ AlQuran",
              style: dancing700.copyWith(fontSize: 40.0),
            ),
            SizedBox(
                height: 350.0,
                width: 350.0,
                child: Lottie.asset("assets/lotties/animationReadQuran.json")),
            ElevatedButton(
                onPressed: () {},
                child: Text(
                  "Baca Al-Quran",
                  style: black400.copyWith(fontSize: 14.0),
                ))
          ],
        ),
      ),
    );
  }
}
