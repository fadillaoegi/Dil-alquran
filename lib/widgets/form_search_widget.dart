import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';

class FormSearch extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final bool showClearIcon;
  final VoidCallback onClear;

  const FormSearch({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hintText,
    required this.showClearIcon,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 10,
            bottom: -8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFCFCFCF),
                borderRadius: BorderRadius.circular(18.0),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: ColorApp.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: const Color(0xFFD3D3D3),
                width: 1.25,
              ),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: black500.copyWith(fontSize: 14.0),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: black400.copyWith(
                  color: ColorApp.black.withValues(alpha: 0.4),
                  fontSize: 13.5,
                ),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: ColorApp.primary),
                suffixIcon: showClearIcon
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: ColorApp.primary),
                        onPressed: onClear,
                      )
                    : null,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: const BorderSide(
                      color: ColorApp.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
