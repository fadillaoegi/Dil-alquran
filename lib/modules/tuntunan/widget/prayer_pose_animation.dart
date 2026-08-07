import 'dart:math' as math;

import 'package:dilalquran/modules/tuntunan/model/tuntunan_model.dart';
import 'package:dilalquran/themes/colors.dart';
import 'package:flutter/material.dart';

// Kerangka figur (tampak samping, menghadap ke kanan/kiblat).
// Koordinat dinormalisasi 0..1 terhadap kotak gambar.
class _Skeleton {
  const _Skeleton({
    required this.head,
    required this.neck,
    required this.shoulder,
    required this.elbow,
    required this.hand,
    required this.hip,
    required this.knee,
    required this.ankle,
    required this.toe,
    this.headRadius = 0.062,
    this.highlight,
  });

  final Offset head;
  final Offset neck;
  final Offset shoulder;
  final Offset elbow;
  final Offset hand;
  final Offset hip;
  final Offset knee;
  final Offset ankle;
  final Offset toe;
  final double headRadius;

  // Titik sorotan (dipakai tahap wudhu untuk menandai anggota badan).
  final Offset? highlight;

  static Offset _lp(Offset a, Offset b, double t) => Offset.lerp(a, b, t)!;

  static _Skeleton lerp(_Skeleton a, _Skeleton b, double t) {
    return _Skeleton(
      head: _lp(a.head, b.head, t),
      neck: _lp(a.neck, b.neck, t),
      shoulder: _lp(a.shoulder, b.shoulder, t),
      elbow: _lp(a.elbow, b.elbow, t),
      hand: _lp(a.hand, b.hand, t),
      hip: _lp(a.hip, b.hip, t),
      knee: _lp(a.knee, b.knee, t),
      ankle: _lp(a.ankle, b.ankle, t),
      toe: _lp(a.toe, b.toe, t),
      headRadius: a.headRadius + (b.headRadius - a.headRadius) * t,
      // Sorotan tidak diinterpolasi agar tidak "terbang" antar bagian tubuh.
      highlight: t < 0.5 ? a.highlight : b.highlight,
    );
  }
}

// Pose dasar berdiri — dipakai ulang oleh tahap wudhu dengan sorotan berbeda.
const _Skeleton _berdiri = _Skeleton(
  head: Offset(0.40, 0.145),
  neck: Offset(0.40, 0.225),
  shoulder: Offset(0.40, 0.265),
  // Lengan sengaja dimajukan sedikit ke depan agar tidak tertutup badan
  // pada tampak samping.
  elbow: Offset(0.462, 0.398),
  hand: Offset(0.470, 0.528),
  hip: Offset(0.40, 0.545),
  knee: Offset(0.40, 0.725),
  ankle: Offset(0.40, 0.900),
  toe: Offset(0.505, 0.900),
);

_Skeleton _wudhu({Offset? highlight, Offset? hand, Offset? elbow}) {
  return _Skeleton(
    head: _berdiri.head,
    neck: _berdiri.neck,
    shoulder: _berdiri.shoulder,
    elbow: elbow ?? const Offset(0.470, 0.400),
    hand: hand ?? const Offset(0.520, 0.470),
    hip: _berdiri.hip,
    knee: _berdiri.knee,
    ankle: _berdiri.ankle,
    toe: _berdiri.toe,
    highlight: highlight,
  );
}

_Skeleton _skeletonFor(PrayerPose pose) {
  switch (pose) {
    // ---------------- Wudhu ----------------
    case PrayerPose.wudhuHands:
      return _wudhu(
        highlight: const Offset(0.520, 0.470),
        elbow: const Offset(0.470, 0.400),
        hand: const Offset(0.520, 0.470),
      );
    case PrayerPose.wudhuMouth:
      return _wudhu(
        highlight: const Offset(0.455, 0.170),
        elbow: const Offset(0.470, 0.330),
        hand: const Offset(0.455, 0.205),
      );
    case PrayerPose.wudhuNose:
      return _wudhu(
        highlight: const Offset(0.462, 0.145),
        elbow: const Offset(0.475, 0.315),
        hand: const Offset(0.460, 0.185),
      );
    case PrayerPose.wudhuFace:
      return _wudhu(
        highlight: const Offset(0.430, 0.145),
        elbow: const Offset(0.485, 0.300),
        hand: const Offset(0.452, 0.160),
      );
    case PrayerPose.wudhuArms:
      return _wudhu(
        highlight: const Offset(0.480, 0.360),
        elbow: const Offset(0.490, 0.360),
        hand: const Offset(0.420, 0.300),
      );
    case PrayerPose.wudhuHead:
      return _wudhu(
        highlight: const Offset(0.400, 0.098),
        elbow: const Offset(0.480, 0.270),
        hand: const Offset(0.418, 0.108),
      );
    case PrayerPose.wudhuEars:
      return _wudhu(
        highlight: const Offset(0.372, 0.150),
        elbow: const Offset(0.470, 0.280),
        hand: const Offset(0.396, 0.145),
      );
    case PrayerPose.wudhuFeet:
      // Sedikit membungkuk dan tangan menjulur ke depan-bawah menuju kaki,
      // supaya lengan tidak menyatu dengan garis badan.
      return const _Skeleton(
        head: Offset(0.432, 0.196),
        neck: Offset(0.418, 0.268),
        shoulder: Offset(0.410, 0.306),
        elbow: Offset(0.492, 0.452),
        hand: Offset(0.470, 0.742),
        hip: Offset(0.395, 0.562),
        knee: Offset(0.400, 0.730),
        ankle: Offset(0.400, 0.900),
        toe: Offset(0.505, 0.900),
        highlight: Offset(0.455, 0.882),
      );
    case PrayerPose.wudhuDoa:
      // Kedua tangan menengadah di depan dada.
      return const _Skeleton(
        head: Offset(0.395, 0.145),
        neck: Offset(0.395, 0.225),
        shoulder: Offset(0.398, 0.265),
        elbow: Offset(0.462, 0.402),
        hand: Offset(0.556, 0.352),
        hip: Offset(0.398, 0.545),
        knee: Offset(0.398, 0.725),
        ankle: Offset(0.398, 0.900),
        toe: Offset(0.505, 0.900),
      );

    // ---------------- Shalat ----------------
    case PrayerPose.berdiri:
      return _berdiri;
    case PrayerPose.takbir:
      return const _Skeleton(
        head: Offset(0.400, 0.145),
        neck: Offset(0.400, 0.225),
        shoulder: Offset(0.400, 0.265),
        elbow: Offset(0.480, 0.275),
        hand: Offset(0.470, 0.150),
        hip: Offset(0.400, 0.545),
        knee: Offset(0.400, 0.725),
        ankle: Offset(0.400, 0.900),
        toe: Offset(0.505, 0.900),
      );
    case PrayerPose.sedekap:
      return const _Skeleton(
        head: Offset(0.400, 0.150),
        neck: Offset(0.400, 0.230),
        shoulder: Offset(0.400, 0.270),
        elbow: Offset(0.468, 0.365),
        hand: Offset(0.432, 0.345),
        hip: Offset(0.400, 0.548),
        knee: Offset(0.400, 0.726),
        ankle: Offset(0.400, 0.900),
        toe: Offset(0.505, 0.900),
      );
    case PrayerPose.rukuk:
      // Punggung rata (bahu sedikit lebih tinggi dari pinggul), pinggul mundur
      // ke belakang, dan kedua tangan turun memegang lutut.
      return const _Skeleton(
        head: Offset(0.706, 0.446),
        neck: Offset(0.648, 0.451),
        shoulder: Offset(0.590, 0.457),
        // Lengan menggantung hampir tegak lurus di depan lutut agar siluetnya
        // terbaca jelas (tidak membentuk segitiga tertutup dengan paha).
        elbow: Offset(0.562, 0.578),
        hand: Offset(0.528, 0.700),
        hip: Offset(0.368, 0.482),
        knee: Offset(0.392, 0.722),
        ankle: Offset(0.400, 0.900),
        toe: Offset(0.505, 0.900),
      );
    case PrayerPose.itidal:
      return const _Skeleton(
        head: Offset(0.400, 0.140),
        neck: Offset(0.400, 0.220),
        shoulder: Offset(0.400, 0.262),
        elbow: Offset(0.470, 0.300),
        hand: Offset(0.462, 0.180),
        hip: Offset(0.400, 0.542),
        knee: Offset(0.400, 0.722),
        ankle: Offset(0.400, 0.900),
        toe: Offset(0.505, 0.900),
      );
    case PrayerPose.sujud:
      // Lutut menempel lantai, punggung melandai, dahi dan kedua telapak
      // tangan menyentuh lantai.
      return const _Skeleton(
        head: Offset(0.652, 0.848),
        neck: Offset(0.592, 0.828),
        shoulder: Offset(0.545, 0.812),
        elbow: Offset(0.600, 0.862),
        hand: Offset(0.672, 0.896),
        hip: Offset(0.375, 0.706),
        knee: Offset(0.348, 0.884),
        ankle: Offset(0.250, 0.896),
        toe: Offset(0.208, 0.900),
        headRadius: 0.058,
      );
    case PrayerPose.dudukAntaraSujud:
    case PrayerPose.tasyahud:
      return const _Skeleton(
        head: Offset(0.395, 0.408),
        neck: Offset(0.395, 0.488),
        shoulder: Offset(0.396, 0.528),
        elbow: Offset(0.452, 0.640),
        hand: Offset(0.520, 0.735),
        hip: Offset(0.375, 0.800),
        knee: Offset(0.545, 0.815),
        ankle: Offset(0.610, 0.898),
        toe: Offset(0.660, 0.900),
      );
    case PrayerPose.salamKanan:
      return const _Skeleton(
        head: Offset(0.470, 0.415),
        neck: Offset(0.400, 0.488),
        shoulder: Offset(0.396, 0.528),
        elbow: Offset(0.452, 0.640),
        hand: Offset(0.520, 0.735),
        hip: Offset(0.375, 0.800),
        knee: Offset(0.545, 0.815),
        ankle: Offset(0.610, 0.898),
        toe: Offset(0.660, 0.900),
      );
  }
}

// Widget animasi figur: transisi halus saat pose berganti, plus gerak napas
// dan denyut sorotan agar tidak terasa statis.
class PrayerPoseAnimation extends StatefulWidget {
  const PrayerPoseAnimation({super.key, required this.pose});

  final PrayerPose pose;

  @override
  State<PrayerPoseAnimation> createState() => _PrayerPoseAnimationState();
}

class _PrayerPoseAnimationState extends State<PrayerPoseAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _transition;
  late final AnimationController _ambient;

  late _Skeleton _from;
  late _Skeleton _to;

  @override
  void initState() {
    super.initState();
    _from = _skeletonFor(widget.pose);
    _to = _from;
    _transition = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
      value: 1.0,
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant PrayerPoseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pose != widget.pose) {
      // Mulai transisi dari posisi yang sedang tampil agar tidak melompat.
      _from = _Skeleton.lerp(_from, _to, _transition.value);
      _to = _skeletonFor(widget.pose);
      _transition.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _transition.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_transition, _ambient]),
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_transition.value);
        final skeleton = _Skeleton.lerp(_from, _to, t);
        return CustomPaint(
          painter: _PrayerPosePainter(
            skeleton: skeleton,
            ambient: _ambient.value,
            settling: _transition.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _PrayerPosePainter extends CustomPainter {
  _PrayerPosePainter({
    required this.skeleton,
    required this.ambient,
    required this.settling,
  });

  final _Skeleton skeleton;
  final double ambient;
  final double settling;

  static const Color _figure = Color(0xff11623f);
  static const Color _figureDark = Color(0xff0a3d29);

  Offset _p(Offset n, Size size, double breath) {
    return Offset(n.dx * size.width, (n.dy + breath) * size.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Gerak napas halus (berhenti saat sedang transisi pose).
    final breath =
        math.sin(ambient * 2 * math.pi) * 0.004 * (settling >= 1.0 ? 1.0 : 0.2);

    final head = _p(skeleton.head, size, breath);
    final neck = _p(skeleton.neck, size, breath);
    final shoulder = _p(skeleton.shoulder, size, breath);
    final elbow = _p(skeleton.elbow, size, breath);
    final hand = _p(skeleton.hand, size, breath);
    final hip = _p(skeleton.hip, size, breath);
    final knee = _p(skeleton.knee, size, breath);
    final ankle = _p(skeleton.ankle, size, breath);
    final toe = _p(skeleton.toe, size, breath);
    final headR = skeleton.headRadius * size.width;

    // Lantai / sajadah.
    _paintGround(canvas, size);

    final limb = Paint()
      ..color = _figure
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.052
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final limbBack = Paint()
      ..color = _figureDark.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.052
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Kaki sisi jauh (lebih gelap) memberi kesan kedalaman.
    canvas.drawPath(
      Path()
        ..moveTo(hip.dx, hip.dy)
        ..lineTo(knee.dx - size.width * 0.03, knee.dy)
        ..lineTo(ankle.dx - size.width * 0.03, ankle.dy),
      limbBack,
    );

    // Kaki depan + telapak.
    canvas.drawPath(
      Path()
        ..moveTo(hip.dx, hip.dy)
        ..lineTo(knee.dx, knee.dy)
        ..lineTo(ankle.dx, ankle.dy)
        ..lineTo(toe.dx, toe.dy),
      limb,
    );

    // Badan (pinggul -> bahu -> leher).
    canvas.drawPath(
      Path()
        ..moveTo(hip.dx, hip.dy)
        ..lineTo(shoulder.dx, shoulder.dy)
        ..lineTo(neck.dx, neck.dy),
      limb..strokeWidth = size.width * 0.062,
    );

    // Lengan.
    canvas.drawPath(
      Path()
        ..moveTo(shoulder.dx, shoulder.dy)
        ..lineTo(elbow.dx, elbow.dy)
        ..lineTo(hand.dx, hand.dy),
      Paint()
        ..color = _figure
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.044
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Kepala + penutup kepala (peci/imamah) agar figur mudah dikenali.
    canvas.drawCircle(head, headR, Paint()..color = _figure);
    final capRect = Rect.fromCircle(center: head, radius: headR * 1.06);
    canvas.drawArc(
      capRect,
      math.pi * 1.04,
      math.pi * 0.92,
      true,
      Paint()..color = _figureDark,
    );

    // Sorotan anggota badan (tahap wudhu).
    final hl = skeleton.highlight;
    if (hl != null) {
      final c = _p(hl, size, breath);
      final pulse = 0.5 + 0.5 * math.sin(ambient * 2 * math.pi);
      final r = size.width * (0.075 + 0.022 * pulse);
      canvas.drawCircle(
        c,
        r,
        Paint()..color = ColorApp.accent.withValues(alpha: 0.16 + 0.10 * pulse),
      );
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = ColorApp.accent.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
    }
  }

  void _paintGround(Canvas canvas, Size size) {
    final y = size.height * 0.912;
    final rect = Rect.fromLTWH(
      size.width * 0.08,
      y,
      size.width * 0.84,
      size.height * 0.055,
    );
    // Sajadah sederhana bergaya chunky (hard shadow).
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.translate(0, size.height * 0.018),
        Radius.circular(size.height * 0.02),
      ),
      Paint()..color = _figureDark.withValues(alpha: 0.85),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.height * 0.02)),
      Paint()..color = ColorApp.accent.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _PrayerPosePainter old) => true;
}
