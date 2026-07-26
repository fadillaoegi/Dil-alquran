import 'package:dilalquran/widgets/app_notify.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

class AudioController extends GetxController {
  final AudioPlayer _player = AudioPlayer();

  final RxList<String> activeUrls = <String>[].obs;
  final RxList<String> activeKeys = <String>[].obs;
  final RxInt currentPlayIndex = (-1).obs;
  final RxString currentPlayKey = "".obs;
  final RxBool isPlaying = false.obs;
  final RxBool isLoading = false.obs;
  final RxString playlistType = "".obs; // "surah" atau "juz"
  final RxInt activeParentNumber = (-1).obs; // Nomor Surah atau nomor Juz yang aktif

  @override
  void onInit() {
    super.onInit();
    _initAudioListeners();
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

  // Memulai pemutaran Playlist secara dinamis
  Future<void> playPlaylist({
    required List<String> urls,
    required List<String> keys,
    required String type,
    required int parentNumber,
    int startIndex = 0,
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

      if (urls.isEmpty) {
        showAppSnackbar(
          "Gagal Memutar",
          "Daftar audio kosong atau tidak tersedia.",
          isError: true,
        );
        isLoading.value = false;
        return;
      }

      // Buat playlist gabungan
      final List<AudioSource> sources = urls.map((url) => AudioSource.uri(Uri.parse(url))).toList();

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
