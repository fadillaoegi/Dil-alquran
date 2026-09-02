import 'package:dilalquran/modules/scan_ayat/controller/scan_ayat_controller.dart';
import 'package:dilalquran/modules/scan_ayat/model/ayat_chat_model.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bagian tanya jawab (Fase 2). Jawaban dibatasi pada terjemahan & tafsir
/// resmi ayat yang sedang dibuka.
class AyatChatSection extends StatefulWidget {
  const AyatChatSection({super.key, required this.controller});

  final ScanAyatController controller;

  @override
  State<AyatChatSection> createState() => _AyatChatSectionState();
}

class _AyatChatSectionState extends State<AyatChatSection> {
  final TextEditingController _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty) return;
    _input.clear();
    FocusScope.of(context).unfocus();
    widget.controller.askQuestion(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 24.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: ColorApp.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFE3EDE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.forum_rounded,
                size: 18.0,
                color: ColorApp.primary,
              ),
              const SizedBox(width: 8.0),
              Text(
                "Tanya tentang ayat ini",
                style: black700.copyWith(fontSize: 15.0),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            "Jawaban disusun dari terjemahan dan tafsir resmi yang ditampilkan "
            "di atas. Untuk pertanyaan hukum, tanyakan kepada ustadz.",
            style: black400.copyWith(fontSize: 11.5, height: 1.5),
          ),
          const SizedBox(height: 14.0),
          Obx(() {
            final messages = widget.controller.messages;
            if (messages.isEmpty) return _buildSuggestions();
            return Column(
              children: [
                for (final message in messages) _buildBubble(message),
              ],
            );
          }),
          const SizedBox(height: 12.0),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        for (final question in widget.controller.suggestedQuestions)
          InkWell(
            onTap: () => _send(question),
            borderRadius: BorderRadius.circular(30.0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: ColorApp.secondary,
                borderRadius: BorderRadius.circular(30.0),
                border: Border.all(color: const Color(0xFFD8E8DE)),
              ),
              child: Text(
                question,
                style: primary500.copyWith(fontSize: 12.0),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isUser ? ColorApp.primary : ColorApp.secondary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14.0),
            topRight: const Radius.circular(14.0),
            bottomLeft: Radius.circular(isUser ? 14.0 : 4.0),
            bottomRight: Radius.circular(isUser ? 4.0 : 14.0),
          ),
        ),
        child: message.isPending
            ? const SizedBox(
                width: 18.0,
                height: 18.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: ColorApp.primary,
                ),
              )
            : Text(
                message.text,
                style: (isUser ? white400 : black400).copyWith(
                  fontSize: 13.0,
                  height: 1.6,
                ),
              ),
      ),
    );
  }

  Widget _buildInput() {
    return Obx(() {
      final busy = widget.controller.isAnswering.value;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              enabled: !busy,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: black400.copyWith(fontSize: 13.0),
              decoration: InputDecoration(
                isDense: true,
                hintText: busy ? "Sedang menjawab..." : "Tulis pertanyaan...",
                hintStyle: black400.copyWith(
                  fontSize: 13.0,
                  color: ColorApp.black.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: ColorApp.secondary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 12.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Material(
            color: busy ? const Color(0xFFB9CFC2) : ColorApp.primary,
            borderRadius: BorderRadius.circular(14.0),
            child: InkWell(
              onTap: busy ? null : _send,
              borderRadius: BorderRadius.circular(14.0),
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(
                  Icons.send_rounded,
                  size: 20.0,
                  color: ColorApp.white,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
