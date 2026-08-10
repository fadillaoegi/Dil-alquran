import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Penampil halaman dengan animasi membuka lembaran kertas.
///
/// Halaman yang dibalik berputar pada sumbu Y di sisi punggung buku (spine),
/// lengkap dengan perspektif dan bayangan yang bergerak — sehingga terasa
/// seperti mengangkat dan membalik lembaran mushaf.
///
/// Arah mengikuti buku Arab (punggung di kanan): geser ke KANAN untuk halaman
/// berikutnya, geser ke KIRI untuk kembali.
class PageFlipView extends StatefulWidget {
  const PageFlipView({
    super.key,
    required this.pageCount,
    required this.builder,
    this.initialPage = 0,
    this.onPageChanged,
    this.controller,
  });

  final int pageCount;
  final IndexedWidgetBuilder builder;
  final int initialPage;
  final ValueChanged<int>? onPageChanged;
  final PageFlipController? controller;

  @override
  State<PageFlipView> createState() => _PageFlipViewState();
}

/// Kendali eksternal untuk berpindah halaman (tombol prev/next, lompat ayat).
class PageFlipController {
  _PageFlipViewState? _state;

  void _attach(_PageFlipViewState state) => _state = state;
  void _detach(_PageFlipViewState state) {
    if (identical(_state, state)) _state = null;
  }

  int get page => _state?._index ?? 0;

  void next() => _state?.animateNext();
  void previous() => _state?.animatePrevious();
  void jumpTo(int page) => _state?.jumpTo(page);
}

class _PageFlipViewState extends State<PageFlipView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late int _index;

  // Progres balik halaman 0..1 dan arahnya.
  double _progress = 0.0;
  bool _forward = true;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialPage.clamp(0, math.max(0, widget.pageCount - 1));
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..addListener(() {
        setState(() => _progress = _anim.value);
      });
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(covariant PageFlipView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    // Jumlah halaman bisa berubah (mis. ukuran layar berubah).
    if (_index > widget.pageCount - 1) {
      _index = math.max(0, widget.pageCount - 1);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _anim.dispose();
    super.dispose();
  }

  bool get _canGoNext => _index < widget.pageCount - 1;
  bool get _canGoPrevious => _index > 0;

  void jumpTo(int page) {
    final int target = page.clamp(0, math.max(0, widget.pageCount - 1)).toInt();
    if (target == _index) return;
    _anim.stop();
    setState(() {
      _index = target;
      _progress = 0.0;
    });
    widget.onPageChanged?.call(_index);
  }

  Future<void> animateNext() async {
    if (!_canGoNext || _anim.isAnimating) return;
    setState(() {
      _forward = true;
      _progress = 0.0;
    });
    await _anim.forward(from: 0.0);
    _commitFlip();
  }

  Future<void> animatePrevious() async {
    if (!_canGoPrevious || _anim.isAnimating) return;
    setState(() {
      _forward = false;
      _progress = 0.0;
    });
    await _anim.forward(from: 0.0);
    _commitFlip();
  }

  // Selesaikan pembalikan: geser index lalu reset progres.
  void _commitFlip() {
    if (!mounted) return;
    setState(() {
      _index += _forward ? 1 : -1;
      _index = _index.clamp(0, math.max(0, widget.pageCount - 1));
      _progress = 0.0;
    });
    widget.onPageChanged?.call(_index);
  }

  void _onDragStart(DragStartDetails details) {
    if (_anim.isAnimating) return;
    _dragging = true;
    _progress = 0.0;
  }

  void _onDragUpdate(DragUpdateDetails details, double width) {
    if (!_dragging || width <= 0) return;
    final dx = details.primaryDelta ?? 0;

    // Tentukan arah pada gerakan pertama: ke kanan = halaman berikutnya.
    if (_progress == 0.0) {
      final wantForward = dx > 0;
      if (wantForward && !_canGoNext) return;
      if (!wantForward && !_canGoPrevious) return;
      _forward = wantForward;
    }

    final delta = (_forward ? dx : -dx) / width;
    setState(() => _progress = (_progress + delta).clamp(0.0, 1.0));
  }

  void _onDragEnd(DragEndDetails details, double width) {
    if (!_dragging) return;
    _dragging = false;
    if (_progress == 0.0) return;

    final velocity = details.primaryVelocity ?? 0;
    final flingForward = _forward ? velocity > 350 : velocity < -350;
    final shouldComplete = _progress > 0.35 || flingForward;

    if (shouldComplete) {
      _anim.forward(from: _progress).then((_) => _commitFlip());
    } else {
      _anim.animateBack(0.0, duration: const Duration(milliseconds: 260)).then(
        (_) {
          if (mounted) setState(() => _progress = 0.0);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pageCount == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Halaman yang sedang dibalik & halaman yang tersingkap di baliknya.
        final int turningIndex = _forward ? _index : _index - 1;
        final int revealedIndex = _forward ? _index + 1 : _index;

        final bool flipping = _progress > 0.0;
        final bool turningValid =
            turningIndex >= 0 && turningIndex < widget.pageCount;
        final bool revealedValid =
            revealedIndex >= 0 && revealedIndex < widget.pageCount;

        // Saat mundur, animasi berjalan dari tertutup (1) menuju terbuka (0).
        final double turnAmount = _forward ? _progress : 1.0 - _progress;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: (d) => _onDragUpdate(d, width),
          onHorizontalDragEnd: (d) => _onDragEnd(d, width),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Lapisan bawah: halaman yang tersingkap.
              if (flipping && revealedValid)
                _SpineShade(
                  amount: turnAmount,
                  child: widget.builder(context, revealedIndex),
                )
              else
                widget.builder(context, _index),

              // Lapisan atas: lembaran yang sedang dibalik.
              if (flipping && turningValid)
                _TurningPage(
                  amount: turnAmount,
                  child: widget.builder(context, turningIndex),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Lembaran yang berputar pada punggung buku (sisi kanan) dengan perspektif.
class _TurningPage extends StatelessWidget {
  const _TurningPage({required this.amount, required this.child});

  /// 0 = rebah penuh (belum dibalik), 1 = tegak lurus (sudah lewat).
  final double amount;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = amount.clamp(0.0, 1.0);
    final angle = -t * (math.pi / 2);

    return IgnorePointer(
      child: Transform(
        alignment: Alignment.centerRight,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0015) // perspektif — memberi kedalaman 3D
          ..rotateY(angle),
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            // Kertas makin gelap saat menjauh dari cahaya ketika terangkat.
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Colors.black.withValues(alpha: 0.28 * t),
                      Colors.black.withValues(alpha: 0.04 * t),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bayangan yang jatuh di dekat punggung buku pada halaman di bawahnya.
class _SpineShade extends StatelessWidget {
  const _SpineShade({required this.amount, required this.child});

  final double amount;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = amount.clamp(0.0, 1.0);
    // Bayangan paling pekat saat lembaran setengah terangkat.
    final strength = math.sin(t * math.pi);

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          child: Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.45,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Colors.black.withValues(alpha: 0.22 * strength),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
