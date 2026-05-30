import 'package:dilalquran/modules/data/models/juz_model.dart';
import 'package:dilalquran/modules/data/models/surah_model.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ListSurahAyat extends StatelessWidget {
  const ListSurahAyat({
    super.key,
    required this.surah,
    required this.onTap,
  });

  final Surah surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nameLatin = surah.namaLatin ?? "";
    final meaning = surah.arti ?? "";
    final arabicName = surah.nama ?? "";
    final versesCount = surah.jumlahAyat ?? 0;
    final revelation = surah.tempatTurun ?? "Mekah";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: ColorApp.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: ColorApp.black.withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
        border: Border.all(
          color: ColorApp.primary.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: onTap,
          splashColor: ColorApp.primary.withValues(alpha: 0.05),
          highlightColor: ColorApp.primary.withValues(alpha: 0.02),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ColorApp.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorApp.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "${surah.nomor}",
                      style: GoogleFonts.roboto(
                        color: ColorApp.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nameLatin,
                        style: black700.copyWith(fontSize: 15.0),
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              meaning,
                              style: black400.copyWith(
                                fontSize: 11.5,
                                color: ColorApp.black.withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6.0),
                            width: 3.5,
                            height: 3.5,
                            decoration: BoxDecoration(
                              color: ColorApp.black.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            "$versesCount Ayat",
                            style: primary600.copyWith(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      arabicName,
                      style: GoogleFonts.amiri(
                        color: ColorApp.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 22.0,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 3.0,
                      ),
                      decoration: BoxDecoration(
                        color: ColorApp.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Text(
                        revelation,
                        style: GoogleFonts.roboto(
                          color: ColorApp.primary,
                          fontSize: 9.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ListJuzCard extends StatelessWidget {
  const ListJuzCard({
    super.key,
    required this.juz,
    required this.onTap,
  });

  final JuzSummary juz;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorApp.primary,
            ColorApp.primary.withValues(alpha: 0.85),
            ColorApp.black,
          ],
        ),
        borderRadius: BorderRadius.circular(18.0),
        boxShadow: [
          BoxShadow(
            color: ColorApp.primary.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18.0),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ColorApp.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(
                      color: ColorApp.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "${juz.number}",
                      style: white700.copyWith(fontSize: 18.0),
                    ),
                  ),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Juz ${juz.number}",
                        style: white700.copyWith(fontSize: 16.0),
                      ),
                      const SizedBox(height: 3.0),
                      Text(
                        "${juz.startSurahName} - ${juz.endSurahName}",
                        style: white500.copyWith(
                          fontSize: 12.0,
                          color: ColorApp.white.withValues(alpha: 0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  "${juz.totalAyat} ayat",
                  style: white600.copyWith(fontSize: 11.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
