import 'package:dilalquran/themes/colors.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            ListView.builder(
              itemBuilder: (context, index) {
                return const ListTile();
              },
            ),
          ],
        ),
      ),
    );
  }
}
