import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
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
              onTap: () {},
              leading: CircleAvatar(
                child: Center(
                  child: Text("${i + 1}"),
                ),
              ),
              title: Text(
                "TiTle",
                style: white400,
              ),
              subtitle: Text(
                "Subtitle",
                style: white400,
              ),
              trailing: Text(
                "Trailing",
                style: white400,
              ),
            );
          },
        ),
      ),
    );
  }
}
