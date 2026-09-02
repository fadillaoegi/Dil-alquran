// ignore_for_file: avoid_print

import 'package:dilalquran/config/ai_config.dart';
import 'package:dilalquran/modules/data/models/surah_model.dart';
import 'package:dilalquran/modules/data/sources/home_source.dart';
import 'package:dilalquran/modules/data/sources/tafsir_source.dart';
import 'package:dilalquran/modules/scan_ayat/model/ayat_chat_model.dart';
import 'package:dilalquran/modules/scan_ayat/model/ayat_recognition_model.dart';
import 'package:dilalquran/services/ayat_chat_service.dart';
import 'package:dilalquran/services/ayat_vision_service.dart';
import 'package:dilalquran/widgets/app_notify.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// Tahapan layar Scan Ayat.
enum ScanStage {
  /// Belum ada foto — tampilkan tombol kamera & galeri.
  idle,

  /// Foto sedang dikirim & dibaca.
  recognizing,

  /// AI memberi lebih dari satu kemungkinan, pengguna harus memilih.
  choosing,

  /// Teks resmi sedang ditarik dari equran.id.
  resolving,

  /// Hasil siap ditampilkan.
  result,
}

class ScanAyatController extends GetxController {
  final ImagePicker _picker = ImagePicker();

  final stage = ScanStage.idle.obs;
  final errorMessage = "".obs;

  /// Foto terakhir, dipakai untuk pratinjau kecil di layar hasil.
  final Rxn<Uint8List> imageBytes = Rxn<Uint8List>();

  final candidates = <AyatCandidate>[].obs;
  final Rxn<ResolvedAyat> resolved = Rxn<ResolvedAyat>();

  // ---- Fase 2: tanya jawab ----
  final messages = <ChatMessage>[].obs;
  final isAnswering = false.obs;

  List<Surah> _surahList = const [];

  bool get isFeatureReady => AiConfig.isConfigured;

  bool get isBusy =>
      stage.value == ScanStage.recognizing || stage.value == ScanStage.resolving;

  @override
  void onInit() {
    super.onInit();
    _preloadSurahIndex();
  }

  /// Daftar surah dipakai untuk memvalidasi nomor ayat hasil AI. Diambil
  /// lebih awal supaya validasi tidak menunggu jaringan saat hasil datang.
  Future<void> _preloadSurahIndex() async {
    try {
      _surahList = await HomeSource.fetchSurah();
    } catch (error) {
      print("ScanAyatController._preloadSurahIndex: $error");
    }
  }

  Map<int, int> get _ayatCountBySurah {
    final map = <int, int>{};
    for (final surah in _surahList) {
      final nomor = surah.nomor;
      final jumlah = surah.jumlahAyat;
      if (nomor != null && jumlah != null && jumlah > 0) {
        map[nomor] = jumlah;
      }
    }
    return map;
  }

  Future<void> captureFromCamera() => _pick(ImageSource.camera);

  Future<void> pickFromGallery() => _pick(ImageSource.gallery);

  Future<void> _pick(ImageSource source) async {
    if (isBusy) return;

    if (!isFeatureReady) {
      errorMessage.value = AiConfig.notConfiguredMessage;
      return;
    }

    try {
      // Gambar dikecilkan di sisi plugin: menekan biaya token, waktu unggah,
      // dan pemakaian memori pada ponsel kelas bawah.
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: AiConfig.maxImageWidth.toDouble(),
        imageQuality: AiConfig.imageQuality,
      );
      if (picked == null) return; // pengguna membatalkan

      final bytes = await picked.readAsBytes();
      imageBytes.value = bytes;
      await _recognize(bytes);
    } catch (error) {
      print("ScanAyatController._pick: $error");
      errorMessage.value = "Gagal membuka gambar.";
      stage.value = ScanStage.idle;
    }
  }

  Future<void> _recognize(Uint8List bytes) async {
    stage.value = ScanStage.recognizing;
    errorMessage.value = "";
    candidates.clear();
    resolved.value = null;
    messages.clear();

    final outcome = await AyatVisionService.recognize(imageBytes: bytes);

    if (!outcome.isSuccess) {
      errorMessage.value = outcome.errorMessage ?? "Terjadi kesalahan.";
      stage.value = ScanStage.idle;
      return;
    }

    final recognition = outcome.recognition!;

    if (!recognition.isQuranPage) {
      errorMessage.value = recognition.note.isNotEmpty
          ? recognition.note
          : "Foto ini sepertinya bukan halaman Al-Qur'an. "
              "Coba foto ulang halaman mushaf dengan cahaya cukup.";
      stage.value = ScanStage.idle;
      return;
    }

    // Saring terhadap kenyataan: nomor surah/ayat harus benar-benar ada.
    final valid = validateCandidates(
      recognition.candidates,
      _ayatCountBySurah,
    );

    if (valid.isEmpty) {
      errorMessage.value = recognition.note.isNotEmpty
          ? recognition.note
          : "Ayat belum bisa dikenali. Coba foto lebih dekat dan pastikan "
              "tulisan tidak buram.";
      stage.value = ScanStage.idle;
      return;
    }

    candidates.assignAll(valid);

    // Satu dugaan saja, atau dugaan teratas sangat kuat -> langsung buka.
    if (valid.length == 1) {
      await selectCandidate(valid.first);
      return;
    }

    stage.value = ScanStage.choosing;
  }

  /// Menarik teks resmi untuk dugaan yang dipilih pengguna.
  Future<void> selectCandidate(AyatCandidate candidate) async {
    stage.value = ScanStage.resolving;
    errorMessage.value = "";

    try {
      final detail = await HomeSource.fetchDetailSurah(
        candidate.surahNumber.toString(),
      );
      final allAyat = detail.ayat ?? [];

      final selected = allAyat.where((ayat) {
        final nomor = ayat.nomorAyat ?? 0;
        return nomor >= candidate.ayatStart && nomor <= candidate.ayatEnd;
      }).toList();

      if (selected.isEmpty) {
        errorMessage.value =
            "Teks ayat tidak dapat diambil. Periksa koneksi internet Anda.";
        stage.value = ScanStage.choosing;
        return;
      }

      // Tafsir bersifat pelengkap: kegagalan di sini tidak membatalkan hasil.
      final tafsirAyat = await TafsirSource.fetchAyat(
        surahNumber: candidate.surahNumber,
        ayatNumber: candidate.ayatStart,
      );

      resolved.value = ResolvedAyat(
        surahNumber: candidate.surahNumber,
        surahNameLatin:
            detail.namaLatin ?? candidate.surahNameGuess.ifEmpty("Surah"),
        surahNameArab: detail.nama ?? "",
        ayatList: selected,
        tafsir: tafsirAyat?.teks ?? "",
      );
      messages.clear();
      stage.value = ScanStage.result;
    } catch (error) {
      print("ScanAyatController.selectCandidate: $error");
      errorMessage.value = "Gagal mengambil teks ayat.";
      stage.value = ScanStage.choosing;
    }
  }

  /// Kembali ke keadaan awal untuk memindai ayat lain.
  void reset() {
    stage.value = ScanStage.idle;
    errorMessage.value = "";
    imageBytes.value = null;
    candidates.clear();
    resolved.value = null;
    messages.clear();
    isAnswering.value = false;
  }

  /// Kembali ke daftar pilihan bila pengguna merasa ayatnya salah.
  void backToCandidates() {
    if (candidates.length <= 1) {
      reset();
      return;
    }
    resolved.value = null;
    messages.clear();
    stage.value = ScanStage.choosing;
  }

  // ================= Fase 2: tanya jawab =================

  bool get canChat => resolved.value != null && !isAnswering.value;

  Future<void> askQuestion(String question) async {
    final current = resolved.value;
    if (current == null) return;

    final trimmed = question.trim();
    if (trimmed.isEmpty) return;
    if (isAnswering.value) return;

    messages
      ..add(ChatMessage.user(trimmed))
      ..add(const ChatMessage.assistant("", isPending: true));
    isAnswering.value = true;

    // Riwayat tidak termasuk dua pesan yang baru saja ditambahkan.
    final history = messages.length > 2
        ? messages.sublist(0, messages.length - 2)
        : <ChatMessage>[];

    final outcome = await AyatChatService.ask(
      question: trimmed,
      ayatContext: current.buildChatContext(),
      history: history,
    );

    // Ganti gelembung "sedang mengetik" dengan jawaban sebenarnya.
    if (messages.isNotEmpty && messages.last.isPending) {
      messages.removeLast();
    }

    if (outcome.isSuccess) {
      messages.add(ChatMessage.assistant(outcome.answer!));
    } else {
      final message = outcome.errorMessage ?? "Gagal mendapatkan jawaban.";
      messages.add(ChatMessage.assistant(message));
      showAppSnackbar("Tanya Jawab", message, isError: true);
    }

    isAnswering.value = false;
  }

  /// Pertanyaan siap pakai supaya pengguna tidak perlu mengetik.
  List<String> get suggestedQuestions => const [
        "Apa makna ayat ini secara sederhana?",
        "Apa pelajaran yang bisa saya amalkan?",
        "Apa konteks turunnya ayat ini?",
      ];
}

extension _StringFallback on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
