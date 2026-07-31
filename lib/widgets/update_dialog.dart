import 'package:dilalquran/services/update_service.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:dilalquran/themes/fonts.dart';
import 'package:flutter/material.dart';

// Menampilkan dialog pembaruan bergaya chunky 3D. Panggil setelah
// UpdateService.isUpdateAvailable() bernilai true.
Future<void> showUpdateDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => const _UpdateDialog(),
  );
}

class _UpdateDialog extends StatelessWidget {
  const _UpdateDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
      child: Container(
        padding: const EdgeInsets.all(22.0),
        decoration: BoxDecoration(
          color: ColorApp.white,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(color: const Color(0xff0d4e34), width: 2.0),
          // Hard offset shadow — chunky 3D.
          boxShadow: const [
            BoxShadow(
              color: Color(0xff0c3f2a),
              offset: Offset(0, 8),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge ikon chunky.
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff11623f), Color(0xff2f9e69)],
                ),
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xff0a3d29),
                    offset: Offset(0, 5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: ColorApp.white,
                size: 34.0,
              ),
            ),
            const SizedBox(height: 18.0),
            Text(
              "Pembaruan Tersedia",
              textAlign: TextAlign.center,
              style: primary700.copyWith(
                fontSize: 19.0,
                color: ColorApp.black,
              ),
            ),
            const SizedBox(height: 10.0),
            Text(
              "Versi terbaru Dil ~ AlQuran sudah tersedia di Google Play. "
              "Perbarui sekarang untuk mendapatkan fitur terbaru dan "
              "perbaikan agar ibadahmu makin nyaman.",
              textAlign: TextAlign.center,
              style: black400.copyWith(
                fontSize: 13.5,
                height: 1.55,
                color: ColorApp.black.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 22.0),
            // Tombol utama chunky: perbarui.
            _ChunkyButton(
              label: "Perbarui Sekarang",
              icon: Icons.shop_rounded,
              primary: true,
              onTap: () {
                Navigator.of(context).pop();
                UpdateService.openStore();
              },
            ),
            const SizedBox(height: 10.0),
            // Tombol sekunder chunky: nanti.
            _ChunkyButton(
              label: "Nanti Saja",
              primary: false,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

// Tombol chunky 3D dengan efek tekan (blok turun & bayangan mengempis).
class _ChunkyButton extends StatefulWidget {
  const _ChunkyButton({
    required this.label,
    required this.onTap,
    required this.primary,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;
  final IconData? icon;

  @override
  State<_ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<_ChunkyButton> {
  bool _pressed = false;

  void _set(bool v) {
    if (mounted && _pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;
    const double depth = 5.0;
    final Color fg = primary ? ColorApp.white : ColorApp.primary;
    final Color shadow =
        primary ? const Color(0xff0a3d29) : ColorApp.primary.withValues(alpha: 0.22);

    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          width: double.infinity,
          transform: Matrix4.translationValues(0, _pressed ? depth : 0, 0),
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          decoration: BoxDecoration(
            gradient: primary
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xff11623f), Color(0xff2f9e69)],
                  )
                : null,
            color: primary ? null : ColorApp.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: primary
                  ? Colors.transparent
                  : ColorApp.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: shadow,
                offset: Offset(0, _pressed ? 0.0 : depth),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: fg, size: 18.0),
                const SizedBox(width: 8.0),
              ],
              Text(
                widget.label,
                style: (primary ? white700 : primary700).copyWith(
                  fontSize: 14.5,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
