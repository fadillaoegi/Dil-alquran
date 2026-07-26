import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';

/// Widget dropdown dengan fitur pencarian (search) yang dapat digunakan
/// di halaman mana saja.
///
/// Contoh penggunaan:
/// ```dart
/// SearchDropdown(
///   hintText: "Pilih Provinsi",
///   selectedValue: selectedProvinsi,
///   items: listProvinsi,
///   onSelected: (value) => print(value),
///   emptyText: "Provinsi tidak ditemukan",
/// )
/// ```
class SearchDropdown extends StatefulWidget {
  const SearchDropdown({
    super.key,
    required this.hintText,
    required this.selectedValue,
    required this.items,
    required this.onSelected,
    required this.emptyText,
    this.enabled = true,
  });

  /// Teks placeholder saat belum ada yang dipilih.
  final String hintText;

  /// Nilai yang sedang terpilih. Gunakan string kosong ("") jika belum ada.
  final String selectedValue;

  /// Daftar pilihan yang akan ditampilkan di dropdown.
  final List<String> items;

  /// Callback yang dipanggil ketika pengguna memilih salah satu item.
  final ValueChanged<String> onSelected;

  /// Teks yang ditampilkan saat hasil pencarian kosong.
  final String emptyText;

  /// Apakah dropdown dapat diinteraksi. Default: `true`.
  final bool enabled;

  @override
  State<SearchDropdown> createState() => _SearchDropdownState();
}

class _SearchDropdownState extends State<SearchDropdown> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.selectedValue);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant SearchDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValue != oldWidget.selectedValue &&
        widget.selectedValue != _textController.text) {
      _textController.text = widget.selectedValue;
    }

    if (!widget.enabled && _expanded) {
      setState(() => _expanded = false);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && mounted) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted || _focusNode.hasFocus) return;
        setState(() {
          _expanded = false;
          _textController.text = widget.selectedValue;
        });
      });
    }
  }

  List<String> get _filteredItems {
    final query = _textController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.items;
    return widget.items
        .where((item) => item.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    final showPanel = _expanded && widget.enabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _textController,
          focusNode: _focusNode,
          enabled: widget.enabled,
          onTap: () {
            if (widget.enabled) {
              if (_textController.text == widget.selectedValue) {
                _textController.clear();
              }
              setState(() => _expanded = true);
            }
          },
          onChanged: (_) {
            if (!_expanded && widget.enabled) {
              setState(() => _expanded = true);
            } else {
              setState(() {});
            }
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            filled: true,
            fillColor: widget.enabled
                ? ColorApp.secondary
                : ColorApp.secondary.withValues(alpha: 0.55),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),

            suffixIcon: widget.enabled
                ? IconButton(
                    tooltip: _expanded ? "Tutup daftar" : "Buka daftar",
                    onPressed: () {
                      if (_expanded) {
                        _focusNode.unfocus();
                        setState(() {
                          _expanded = false;
                          _textController.text = widget.selectedValue;
                        });
                      } else {
                        if (_textController.text == widget.selectedValue) {
                          _textController.clear();
                        }
                        _focusNode.requestFocus();
                        setState(() => _expanded = true);
                      }
                    },
                    icon: Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: ColorApp.primary,
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: ColorApp.primary,
                width: 1.2,
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: showPanel
              ? Container(
                  margin: const EdgeInsets.only(top: 8.0),
                  constraints: const BoxConstraints(maxHeight: 220.0),
                  decoration: BoxDecoration(
                    color: ColorApp.white,
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(
                      color: ColorApp.primary.withValues(alpha: 0.14),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: items.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Text(
                            widget.emptyText,
                            style: black400.copyWith(
                              fontSize: 12.5,
                              color: ColorApp.black.withValues(alpha: 0.6),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 14.0,
                            endIndent: 14.0,
                            color: ColorApp.black.withValues(alpha: 0.06),
                          ),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final selected = item == widget.selectedValue;
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _textController.text = item;
                                  _focusNode.unfocus();
                                  setState(() => _expanded = false);
                                  widget.onSelected(item);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14.0,
                                    vertical: 12.0,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item,
                                          style:
                                              (selected ? primary600 : black500)
                                                  .copyWith(fontSize: 13.5),
                                        ),
                                      ),
                                      if (selected)
                                        const Icon(
                                          Icons.check_rounded,
                                          size: 18.0,
                                          color: ColorApp.primary,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
