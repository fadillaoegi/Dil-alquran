import 'package:dilalquran/themes/colors.dart';
import 'package:flutter/material.dart';

// ============================================================
// FONT ARAB (Amiri, gaya Naskh) — khusus untuk tulisan Arab:
// ayat Al-Qur'an, doa, dan dzikir. Sengaja DIBEDAKAN dari teks
// Latin/Indonesia (sans-serif) agar mudah dipisahkan mata.
// ============================================================
const String arabicFontFamily = 'Amiri';

// Ayat Al-Qur'an — besar & lega, height longgar agar harakat jelas.
const TextStyle arabicQuran = TextStyle(
  fontFamily: arabicFontFamily,
  color: ColorApp.black,
  fontSize: 26.0,
  height: 2.0,
  fontWeight: FontWeight.w700,
);

// Teks Arab pada doa & dzikir.
const TextStyle arabicBody = TextStyle(
  fontFamily: arabicFontFamily,
  color: ColorApp.black,
  fontSize: 26.0,
  height: 1.9,
  fontWeight: FontWeight.w700,
);

// Nama surah dalam tulisan Arab (mis. di header).
const TextStyle arabicTitle = TextStyle(
  fontFamily: arabicFontFamily,
  color: ColorApp.white,
  fontSize: 24.0,
  fontWeight: FontWeight.w700,
);

// NOTE: FONT POPPINS WHITE COLOR
const TextStyle white400 =
    TextStyle(color: Colors.white, fontWeight: FontWeight.w400);
const TextStyle white500 =
    TextStyle(color: Colors.white, fontWeight: FontWeight.w500);
const TextStyle white600 =
    TextStyle(color: Colors.white, fontWeight: FontWeight.w600);
const TextStyle white700 =
    TextStyle(color: Colors.white, fontWeight: FontWeight.w700);

// NOTE: FONT POPPINS PRIMARY COLOR
const TextStyle primary400 =
    TextStyle(color: ColorApp.primary, fontWeight: FontWeight.w400);
const TextStyle primary500 =
    TextStyle(color: ColorApp.primary, fontWeight: FontWeight.w500);
const TextStyle primary600 =
    TextStyle(color: ColorApp.primary, fontWeight: FontWeight.w600);
const TextStyle primary700 =
    TextStyle(color: ColorApp.primary, fontWeight: FontWeight.w700);

// NOTE: FONT POPPINS BLACK COLOR
const TextStyle black400 =
    TextStyle(color: ColorApp.black, fontWeight: FontWeight.w400);
const TextStyle black500 =
    TextStyle(color: ColorApp.black, fontWeight: FontWeight.w500);
const TextStyle black600 =
    TextStyle(color: ColorApp.black, fontWeight: FontWeight.w600);
const TextStyle black700 =
    TextStyle(color: ColorApp.black, fontWeight: FontWeight.w700);

// NOTE: FONT DANCINGSCRIPT WHITE COLOR
const TextStyle dancing500 =
    TextStyle(color: Colors.white, fontWeight: FontWeight.w500);
const TextStyle dancing600 =
    TextStyle(color: Colors.white, fontWeight: FontWeight.w600);
const TextStyle dancing700 =
    TextStyle(color: Colors.white, fontWeight: FontWeight.w700);
