import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:dilalquran/modules/audio/audio_controller.dart';
import 'package:dilalquran/modules/data/models/juz_model.dart';
import 'package:dilalquran/modules/data/models/surah_detail_model.dart';
import 'package:dilalquran/modules/data/models/surah_model.dart';
import 'package:dilalquran/modules/data/sources/home_source.dart';
import 'package:dilalquran/modules/home/controller/home_controller.dart';
import 'package:dilalquran/services/quran_reading_progress_store.dart';
import 'package:dilalquran/widgets/app_notify.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailSurahController extends GetxController {
  static const _prefQariKey = 'dilalquran_selected_qari';
  static const _prefLastReadKey = 'dilalquran_last_read_ayat';
  static const _prefBookModeKey = 'dilalquran_book_mode';
  static const _prefTajweedEnabledKey = 'dilalquran_tajweed_enabled';

  final _surahDetail = SurahDetail().obs;
  SurahDetail get surahDetail => _surahDetail.value;

  final _juzDetail = Rxn<JuzDetail>();
  JuzDetail? get juzDetail => _juzDetail.value;

  final _category = QuranCategory.surah.obs;
  QuranCategory get category => _category.value;

  final _number = 0.obs;
  int get number => _number.value;

  final _isLoading = true.obs;
  bool get isLoading => _isLoading.value;
  RxBool get isLoadingRx => _isLoading;

  final _selectedQari = '05'.obs;
  String get selectedQari => _selectedQari.value;
  RxString get selectedQariRx => _selectedQari;

  final _activeVerseKey = ''.obs;
  String get activeVerseKey => _activeVerseKey.value;
  RxString get activeVerseKeyRx => _activeVerseKey;

  final _isPlaying = false.obs;
  bool get isPlaying => _isPlaying.value;

  final _lastRead = Rxn<LastReadAyat>();
  LastReadAyat? get lastRead => _lastRead.value;

  // Mode tampilan: false = mode gulir (default), true = mode buku (mushaf).
  final _isBookMode = false.obs;
  bool get isBookMode => _isBookMode.value;
  RxBool get isBookModeRx => _isBookMode;

  Future<void> toggleBookMode() async {
    _isBookMode.value = !_isBookMode.value;
    await _prefs?.setBool(_prefBookModeKey, _isBookMode.value);
  }

  // Warna tajwid aktif secara bawaan dan mengikuti preferensi pengguna.
  final _isTajweedEnabled = true.obs;
  bool get isTajweedEnabled => _isTajweedEnabled.value;
  RxBool get isTajweedEnabledRx => _isTajweedEnabled;

  Future<void> setTajweedEnabled(bool enabled) async {
    _isTajweedEnabled.value = enabled;
    await _prefs?.setBool(_prefTajweedEnabledKey, enabled);
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioController audioCtrl = Get.find<AudioController>();

  SharedPreferences? _prefs;
  final QuranReadingProgressStore _readingProgressStore =
      const QuranReadingProgressStore();
  final Map<String, int> _bookPageProgress = <String, int>{};

  String get _bookProgressKey => QuranReadingProgressStore.contentKey(
        category: _categoryToRaw(_category.value),
        number: _number.value,
      );

  int get initialBookPage => _bookPageProgress[_bookProgressKey] ?? 0;

  Future<void> saveBookPage(int pageIndex) async {
    if (pageIndex < 0) return;
    _bookPageProgress[_bookProgressKey] = pageIndex;
    await _readingProgressStore.save(_bookPageProgress);
  }

  final List<Map<String, String>> qariOptions = const [
    {'id': '01', 'name': 'Abdullah Al-Juhany'},
    {'id': '02', 'name': 'Abdul Muhsin Al-Qasim'},
    {'id': '03', 'name': 'Abdurrahman As-Sudais'},
    {'id': '04', 'name': 'Ibrahim Al-Dossari'},
    {'id': '05', 'name': 'Misyari Rasyid'},
    {'id': '06', 'name': 'Yasser Al-Dosari'},
  ];

  @override
  void onInit() {
    super.onInit();
    _listenAudioState();
    _listenPlaylistState();
    _bootstrap();
  }

  void _listenPlaylistState() {
    audioCtrl.currentPlayKey.listen((key) {
      if (audioCtrl.isPlaylistActive(
          _category.value == QuranCategory.juz ? 'juz' : 'surah',
          _number.value)) {
        if (key.isNotEmpty) {
          _activeVerseKey.value = key;
        } else {
          _activeVerseKey.value = '';
        }
      }
    });

    audioCtrl.isPlaying.listen((playing) {
      if (audioCtrl.isPlaylistActive(
          _category.value == QuranCategory.juz ? 'juz' : 'surah',
          _number.value)) {
        if (!playing && audioCtrl.currentPlayKey.value.isEmpty) {
          _activeVerseKey.value = '';
        }
      }
    });
  }

  Future<void> playPlaylist({
    required List<String> urls,
    required List<String> keys,
  }) async {
    final type = _category.value == QuranCategory.juz ? 'juz' : 'surah';

    // Jika playlist untuk surah/juz ini sudah aktif, toggle play/pause
    if (audioCtrl.isPlaylistActive(type, _number.value)) {
      await audioCtrl.togglePlay();
      return;
    }

    // Hentikan pemutaran single ayat jika sedang aktif
    await stopAudio();

    // Metadata untuk media notification (panel notifikasi + lock screen).
    final String album = _category.value == QuranCategory.juz
        ? "Juz ${_number.value}"
        : "QS. ${_surahDetail.value.namaLatin ?? _number.value}";
    final String qariName = qariOptions.firstWhere(
      (q) => q['id'] == _selectedQari.value,
      orElse: () => const {'name': 'Murottal'},
    )['name']!;

    // Jalankan pemutaran playlist melalui global controller
    await audioCtrl.playPlaylist(
      urls: urls,
      keys: keys,
      type: type,
      parentNumber: _number.value,
      startIndex: 0,
      album: album,
      artist: qariName,
    );
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }

  bool get hasLastReadOnCurrentPage {
    final item = _lastRead.value;
    if (item == null) return false;

    return item.category == _category.value &&
        item.parentNumber == _number.value;
  }

  String get lastReadSummary {
    final item = _lastRead.value;
    if (item == null) return '';

    if (item.category == QuranCategory.juz) {
      return 'Terakhir di Juz ${item.parentNumber}: ${item.surahNameLatin} ayat ${item.ayatNumber}';
    }

    return 'Terakhir di ${item.surahNameLatin}: ayat ${item.ayatNumber}';
  }

  String? get currentPageLastReadVerseKey {
    final item = _lastRead.value;
    if (item == null) return null;
    if (!hasLastReadOnCurrentPage) return null;
    return item.verseKey;
  }

  bool isLastReadVerse(String verseKey) {
    return currentPageLastReadVerseKey == verseKey;
  }

  Future<void> _bootstrap() async {
    await _loadPreferences();
    await loadDetail();
  }

  Future<void> loadDetail() async {
    try {
      _isLoading.value = true;
      final payload = _resolveArguments(Get.arguments);
      _category.value = payload.category;
      _number.value = payload.number;

      if (payload.category == QuranCategory.surah) {
        _surahDetail.value =
            await HomeSource.fetchDetailSurah(payload.number.toString());
        _juzDetail.value = null;
      } else {
        final surahList = await _resolveSurahList();
        _juzDetail.value = await HomeSource.fetchDetailJuz(
          juzNumber: payload.number,
          surahList: surahList,
        );
        _surahDetail.value = SurahDetail();
      }
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> playAyatAudio({
    required String verseKey,
    required Map<String, String>? audio,
    required int surahNumber,
    required int ayatNumber,
    required String surahNameLatin,
  }) async {
    final audioUrl = audio?[_selectedQari.value] ??
        (audio != null && audio.isNotEmpty ? audio.values.first : null);

    if (audioUrl == null || audioUrl.isEmpty) {
      showAppSnackbar(
        'Audio Tidak Tersedia',
        'Audio untuk ayat ini belum tersedia.',
        isError: true,
      );
      return;
    }

    await saveLastRead(
      verseKey: verseKey,
      surahNumber: surahNumber,
      ayatNumber: ayatNumber,
      surahNameLatin: surahNameLatin,
    );

    final type = _category.value == QuranCategory.juz ? 'juz' : 'surah';
    final playlistActive = audioCtrl.isPlaylistActive(type, _number.value);

    // Ayat ini yang sedang aktif -> jeda / lanjut (bukan stop).
    if (_activeVerseKey.value == verseKey) {
      if (playlistActive) {
        // Dikendalikan oleh pemutar playlist.
        await audioCtrl.togglePlay();
      } else if (_isPlaying.value) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
      return;
    }

    // Ayat berbeda -> hentikan playlist bila aktif, lalu putar ayat ini.
    if (playlistActive) {
      await audioCtrl.stopPlay();
    }

    _activeVerseKey.value = verseKey;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (_) {
      _activeVerseKey.value = '';
      _isPlaying.value = false;
      showAppSnackbar(
        'Gagal Memutar Audio',
        'Periksa koneksi internet lalu coba lagi.',
        isError: true,
      );
    }
  }

  Future<void> saveLastRead({
    required String verseKey,
    required int surahNumber,
    required int ayatNumber,
    required String surahNameLatin,
  }) async {
    final value = LastReadAyat(
      category: _category.value,
      parentNumber: _number.value,
      surahNumber: surahNumber,
      ayatNumber: ayatNumber,
      surahNameLatin: surahNameLatin,
      verseKey: verseKey,
      savedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
    );

    _lastRead.value = value;
    await _prefs?.setString(_prefLastReadKey, jsonEncode(value.toJson()));
  }

  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    _activeVerseKey.value = '';
    _isPlaying.value = false;

    // Hentikan juga playlist player jika aktif untuk surah/juz ini
    final type = _category.value == QuranCategory.juz ? 'juz' : 'surah';
    if (audioCtrl.isPlaylistActive(type, _number.value)) {
      await audioCtrl.stopPlay();
    }
  }

  Future<void> changeQari(String qariId) async {
    _selectedQari.value = qariId;
    await _prefs?.setString(_prefQariKey, qariId);

    // Hentikan pemutaran playlist jika qari berganti
    final type = _category.value == QuranCategory.juz ? 'juz' : 'surah';
    if (audioCtrl.isPlaylistActive(type, _number.value)) {
      await audioCtrl.stopPlay();
    }
  }

  bool isVersePlaying(String verseKey) {
    final bool isSinglePlaying =
        _activeVerseKey.value == verseKey && _isPlaying.value;
    final bool isPlaylistPlaying = _activeVerseKey.value == verseKey &&
        audioCtrl.isPlaying.value &&
        audioCtrl.isPlaylistActive(
            _category.value == QuranCategory.juz ? 'juz' : 'surah',
            _number.value);

    return isSinglePlaying || isPlaylistPlaying;
  }

  _DetailPayload _resolveArguments(dynamic args) {
    if (args is Map) {
      final categoryRaw = args['category']?.toString().toLowerCase();
      final numberRaw = args['number'];
      final parsedNumber = int.tryParse(numberRaw.toString()) ?? 1;

      return _DetailPayload(
        category:
            categoryRaw == 'juz' ? QuranCategory.juz : QuranCategory.surah,
        number: parsedNumber,
      );
    }

    if (args is String || args is int) {
      final parsed = int.tryParse(args.toString()) ?? 1;
      return _DetailPayload(category: QuranCategory.surah, number: parsed);
    }

    return const _DetailPayload(category: QuranCategory.surah, number: 1);
  }

  Future<List<Surah>> _resolveSurahList() async {
    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      if (homeController.surahList.isNotEmpty) {
        return homeController.surahList;
      }
      await homeController.getInitialData();
      return homeController.surahList;
    }

    return HomeSource.fetchSurah();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();

    final savedQari = _prefs?.getString(_prefQariKey);
    if (savedQari != null && savedQari.isNotEmpty) {
      _selectedQari.value = savedQari;
    }

    _isBookMode.value = _prefs?.getBool(_prefBookModeKey) ?? false;
    _isTajweedEnabled.value = _prefs?.getBool(_prefTajweedEnabledKey) ?? true;
    _bookPageProgress
      ..clear()
      ..addAll(await _readingProgressStore.load());

    final savedLastRead = _prefs?.getString(_prefLastReadKey);
    if (savedLastRead != null && savedLastRead.isNotEmpty) {
      try {
        final map = jsonDecode(savedLastRead) as Map<String, dynamic>;
        _lastRead.value = LastReadAyat.fromJson(map);
      } catch (_) {
        _lastRead.value = null;
      }
    }
  }

  void _listenAudioState() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying.value = state == PlayerState.playing;
      if (state != PlayerState.playing) {
        if (state == PlayerState.stopped || state == PlayerState.completed) {
          _activeVerseKey.value = '';
        }
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      _isPlaying.value = false;
      _activeVerseKey.value = '';
    });
  }
}

class _DetailPayload {
  final QuranCategory category;
  final int number;

  const _DetailPayload({required this.category, required this.number});
}

class LastReadAyat {
  final QuranCategory category;
  final int parentNumber;
  final int surahNumber;
  final int ayatNumber;
  final String surahNameLatin;
  final String verseKey;
  final int savedAtEpochMs;

  const LastReadAyat({
    required this.category,
    required this.parentNumber,
    required this.surahNumber,
    required this.ayatNumber,
    required this.surahNameLatin,
    required this.verseKey,
    required this.savedAtEpochMs,
  });

  factory LastReadAyat.fromJson(Map<String, dynamic> json) {
    return LastReadAyat(
      category: _rawToCategory((json['category'] ?? 'surah').toString()),
      parentNumber: json['parentNumber'] ?? 1,
      surahNumber: json['surahNumber'] ?? 1,
      ayatNumber: json['ayatNumber'] ?? 1,
      surahNameLatin: (json['surahNameLatin'] ?? 'Surah').toString(),
      verseKey: (json['verseKey'] ?? '').toString(),
      savedAtEpochMs: json['savedAtEpochMs'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': _categoryToRaw(category),
      'parentNumber': parentNumber,
      'surahNumber': surahNumber,
      'ayatNumber': ayatNumber,
      'surahNameLatin': surahNameLatin,
      'verseKey': verseKey,
      'savedAtEpochMs': savedAtEpochMs,
    };
  }
}

String _categoryToRaw(QuranCategory category) {
  return category == QuranCategory.juz ? 'juz' : 'surah';
}

QuranCategory _rawToCategory(String raw) {
  return raw == 'juz' ? QuranCategory.juz : QuranCategory.surah;
}
