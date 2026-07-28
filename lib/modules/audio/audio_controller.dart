import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dilalquran/widgets/app_notify.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';

class AudioController extends GetxController {
  final AudioPlayer _player = AudioPlayer();

  // URI file artwork (ikon Al-Quran) untuk media notification.
  String? _artFileUri;

  final RxList<String> activeUrls = <String>[].obs;
  final RxList<String> activeKeys = <String>[].obs;
  final RxInt currentPlayIndex = (-1).obs;
  final RxString currentPlayKey = "".obs;
  final RxBool isPlaying = false.obs;
  final RxBool isLoading = false.obs;
  final RxString playlistType = "".obs; // "surah" atau "juz"
  final RxInt activeParentNumber = (-1).obs; // Nomor Surah atau nomor Juz yang aktif

  // Posisi & durasi untuk full-screen player.
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> bufferedPosition = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;

  bool get hasNext => _player.hasNext;
  bool get hasPrevious => _player.hasPrevious;

  @override
  void onInit() {
    super.onInit();
    _initAudioListeners();
    _ensureArt();
  }

  // Salin ikon Al-Quran dari assets ke file lokal agar bisa dipakai
  // sebagai artwork media notification (audio_service butuh URI file/URL).
  Future<String?> _ensureArt() async {
    if (_artFileUri != null) return _artFileUri;
    try {
      final dir = await getApplicationSupportDirectory();
      // Nama baru (v2) agar art chunky ter-generate ulang, tidak memakai cache
      // ikon lama dari build sebelumnya.
      final file = File('${dir.path}/notif_art_chunky_v2.png');
      if (!await file.exists()) {
        final bytes = await _buildChunkyArt();
        if (bytes != null) await file.writeAsBytes(bytes);
      }
      _artFileUri = await file.exists() ? file.uri.toString() : null;
    } catch (_) {
      _artFileUri = null;
    }
    return _artFileUri;
  }

  // Gambar artwork bergaya chunky 3D (kartu putih + border tebal + hard offset
  // shadow + ikon Al-Quran) memakai canvas, lalu ubah ke PNG untuk dipakai
  // sebagai cover media notification. Ini satu-satunya elemen visual notifikasi
  // sistem yang bisa dikendalikan aplikasi.
  Future<Uint8List?> _buildChunkyArt() async {
    try {
      const double size = 512.0;
      const Color primary = Color(0xff107a4a);
      const Color cardBorder = Color(0xff0d4e34);
      const Color shadowDeep = Color(0xff0c3f2a);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        const Rect.fromLTWH(0, 0, size, size),
      );

      // Latar gradasi hijau lembut memenuhi kanvas.
      const bgRect = Rect.fromLTWH(0, 0, size, size);
      canvas.drawRect(
        bgRect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffe3f0e8), Color(0xffeaf4ee)],
          ).createShader(bgRect),
      );

      // Kotak kartu (dengan ruang untuk bayangan di bawah).
      final cardRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(74, 66, size - 148, size - 168),
        const Radius.circular(58),
      );

      // Hard offset shadow — ciri khas chunky 3D.
      canvas.drawRRect(
        cardRect.shift(const Offset(0, 22)),
        Paint()..color = shadowDeep,
      );
      // Isi kartu putih.
      canvas.drawRRect(cardRect, Paint()..color = Colors.white);
      // Border hijau tebal.
      canvas.drawRRect(
        cardRect,
        Paint()
          ..color = cardBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10,
      );

      // Ikon Al-Quran di tengah kartu (glyph MaterialIcons).
      const icon = Icons.menu_book_rounded;
      final tp = TextPainter(textDirection: TextDirection.ltr);
      tp.text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: 210,
          color: primary,
        ),
      );
      tp.layout();
      final cardCenter = cardRect.outerRect.center;
      tp.paint(
        canvas,
        Offset(cardCenter.dx - tp.width / 2, cardCenter.dy - tp.height / 2),
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  void _initAudioListeners() {
    // Menyimak status pemutaran (Play/Pause/Buffering)
    _player.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      
      if (state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering) {
        isLoading.value = true;
      } else {
        isLoading.value = false;
      }

      // Jika playlist selesai diputar, reset index
      if (state.processingState == ProcessingState.completed) {
        stopPlay();
      }
    });

    // Menyimak pergantian index track/ayat otomatis
    _player.currentIndexStream.listen((index) {
      if (index != null && activeKeys.isNotEmpty && index < activeKeys.length) {
        currentPlayIndex.value = index;
        currentPlayKey.value = activeKeys[index];
        _scrollToActiveVerse(index);
      }
    });

    // Menyimak posisi & durasi untuk seek bar full-screen player.
    _player.positionStream.listen((pos) => position.value = pos);
    _player.bufferedPositionStream
        .listen((buf) => bufferedPosition.value = buf);
    _player.durationStream.listen((dur) => duration.value = dur ?? Duration.zero);
  }

  // Loncat ke posisi tertentu pada track yang sedang diputar.
  Future<void> seek(Duration pos) async {
    await _player.seek(pos);
  }

  // Auto-scroll ke ayat yang sedang aktif
  void _scrollToActiveVerse(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final ScrollController scrollController = Get.find<ScrollController>(tag: 'verse_scroll');
        if (scrollController.hasClients) {
          // Setiap item tinggi rata-ratanya berkisar 160.0
          double targetOffset = index * 180.0;
          
          // Batasi scroll offset agar tidak melampaui batas max scroll
          double maxScroll = scrollController.position.maxScrollExtent;
          if (targetOffset > maxScroll) {
            targetOffset = maxScroll;
          }
          if (targetOffset < 0) {
            targetOffset = 0;
          }

          scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          );
        }
      } catch (e) {
        // ScrollController mungkin belum di-bind pada screen aktif, abaikan saja
      }
    });
  }

  // Judul & pembaca (qari) yang tampil di media notification.
  final RxString albumTitle = "".obs;
  final RxString artist = "".obs;

  // Memulai pemutaran Playlist secara dinamis
  Future<void> playPlaylist({
    required List<String> urls,
    required List<String> keys,
    required String type,
    required int parentNumber,
    int startIndex = 0,
    String album = "Audio Al-Qur'an",
    String artist = "Murottal",
    String? artUri,
  }) async {
    try {
      isLoading.value = true;
      
      // Stop pemutaran sebelumnya jika ada
      await _player.stop();

      activeUrls.assignAll(urls);
      activeKeys.assignAll(keys);
      playlistType.value = type;
      activeParentNumber.value = parentNumber;
      currentPlayIndex.value = startIndex;
      currentPlayKey.value = keys[startIndex];
      albumTitle.value = album;
      this.artist.value = artist;

      if (urls.isEmpty) {
        showAppSnackbar(
          "Gagal Memutar",
          "Daftar audio kosong atau tidak tersedia.",
          isError: true,
        );
        isLoading.value = false;
        return;
      }

      // Buat playlist gabungan + metadata untuk media notification (panel notifikasi).
      final String? resolvedArt =
          (artUri != null && artUri.isNotEmpty) ? artUri : await _ensureArt();
      final Uri? art =
          (resolvedArt != null) ? Uri.tryParse(resolvedArt) : null;
      final List<AudioSource> sources = [];
      for (int i = 0; i < urls.length; i++) {
        final key = i < keys.length ? keys[i] : "${i + 1}";
        // Ambil nomor ayat dari verseKey (mis. "2:255", "s1_3" -> "3").
        final match = RegExp(r'(\d+)\D*$').firstMatch(key);
        final ayat = match?.group(1) ?? "${i + 1}";
        sources.add(
          AudioSource.uri(
            Uri.parse(urls[i]),
            tag: MediaItem(
              id: "${i}_${urls[i]}",
              album: album,
              title: "$album — Ayat $ayat",
              artist: artist,
              artUri: art,
            ),
          ),
        );
      }

      // Set audio source pada player
      await _player.setAudioSources(
        sources,
        initialIndex: startIndex,
        initialPosition: Duration.zero,
      );

      // Putar audio
      _player.play();
    } catch (e) {
      showAppSnackbar(
        "Error Pemutaran",
        "Terjadi kesalahan saat memuat audio.",
        isError: true,
      );
      debugPrint("Error in playPlaylist: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Mengubah status Play / Pause
  Future<void> togglePlay() async {
    if (isPlaying.value) {
      await _player.pause();
    } else {
      _player.play();
    }
  }

  // Menghentikan pemutaran audio
  Future<void> stopPlay() async {
    await _player.stop();
    activeUrls.clear();
    activeKeys.clear();
    currentPlayIndex.value = -1;
    currentPlayKey.value = "";
    playlistType.value = "";
    activeParentNumber.value = -1;
    albumTitle.value = "";
    artist.value = "";
  }

  // Memutar track selanjutnya
  Future<void> next() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  // Memutar track sebelumnya
  Future<void> previous() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  // Mengecek apakah playlist bertipe tertentu sedang aktif diputar
  bool isPlaylistActive(String type, int parentNumber) {
    return playlistType.value == type && activeParentNumber.value == parentNumber;
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }
}
