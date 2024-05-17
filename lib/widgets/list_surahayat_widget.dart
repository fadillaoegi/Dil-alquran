import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';

class ListSurahAyat extends StatelessWidget {
  const ListSurahAyat({
    super.key,
    required this.i,
    required this.onTap,
  });

  final int i;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: ColorApp.secondary,
            child: Center(
              child: Text("${i + 1}"),
            ),
          ),
          title: Text(
            "Surah ke-${i + 1}",
            style: black500.copyWith(fontSize: 14.0),
          ),
          subtitle: Text(
            "Subtitle ke-${i + 1}",
            style: black400.copyWith(fontSize: 12.0),
          ),
          trailing: Text(
            "Trailing ke-${i + 1}",
            style: black400.copyWith(fontSize: 12.0),
          ),
        ),
        Divider(
          color: ColorApp.secondary,
        ),
      ],
    );
  }
}
