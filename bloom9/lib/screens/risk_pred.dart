// risk_check_screen.dart
//
// pubspec.yaml -> dependencies:
//   google_fonts: ^6.2.1
//   http: ^1.2.0        (only if you use ApiRiskService)
//
// Usage:
//   Navigator.push(context, MaterialPageRoute(builder: (_) => const RiskCheckScreen()));
//   or plug in your model:
//   RiskCheckScreen(service: ApiRiskService(Uri.parse('https://your-api/predict')))

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// ─────────────────────────────────────────────────────────────
// Units. These MUST match the units your model was trained on.
// (UCI Maternal Health Risk dataset: blood sugar in mmol/L, temp in °F.)
// ─────────────────────────────────────────────────────────────
const kSugarUnit = 'mmol/L';
const kTempUnit = '°F';

// ─────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFF6F9FE);
  static const wash = Color(0xFFE4EEFC);
  static const ink = Color(0xFF1B2A41);
  static const muted = Color(0xFF7F8FA6);
  static const line = Color(0xFFE3EBF6);
  static const blue = Color(0xFF4A8FE7);
  static const blueDeep = Color(0xFF3B6FD4);
  static const low = Color(0xFF3FBF9B);
  static const mid = Color(0xFFF2A93B);
  static const high = Color(0xFFEA5D6A);
}

TextStyle _t(double size, FontWeight w, Color c, {double? h, double? ls}) =>
    GoogleFonts.plusJakartaSans(
        fontSize: size, fontWeight: w, color: c, height: h, letterSpacing: ls);

BoxShadow _softShadow([Color? c, double a = .07]) => BoxShadow(
      color: (c ?? const Color(0xFF3B6FD4)).withValues(alpha: a),
      blurRadius: 30,
      offset: const Offset(0, 12),
    );

// ─────────────────────────────────────────────────────────────
// Model layer
// ─────────────────────────────────────────────────────────────
enum RiskLevel { low, mid, high }

extension RiskX on RiskLevel {
  Color get color => const [_C.low, _C.mid, _C.high][index];
  double get position => const [1 / 6, 3 / 6, 5 / 6][index];
  String get title => const ['Low risk', 'Moderate risk', 'High risk'][index];
  String get short => const ['Low', 'Moderate', 'High'][index];
  IconData get icon => const [
        Icons.check_circle_rounded,
        Icons.info_rounded,
        Icons.warning_rounded,
      ][index];
  String get message => const [
        'Your readings look steady. Keep up your regular check-ups.',
        'A few readings are worth watching. Recheck soon and mention it at your next visit.',
        'These readings need attention. Please contact your doctor or midwife today.',
      ][index];
}

class Vitals {
  const Vitals({
    required this.age,
    required this.systolic,
    required this.diastolic,
    required this.bloodSugar,
    required this.bodyTemp,
    required this.heartRate,
  });

  final double age, systolic, diastolic, bloodSugar, bodyTemp, heartRate;

  Map<String, dynamic> toJson() => {
        'Age': age,
        'SystolicBP': systolic,
        'DiastolicBP': diastolic,
        'BS': bloodSugar,
        'BodyTemp': bodyTemp,
        'HeartRate': heartRate,
      };
}

/// What your model returns: probabilities for low / mid / high (sum to 1).
/// The predicted level is whichever has the highest probability.
class RiskResult {
  RiskResult._(this.low, this.mid, this.high);

  /// Pass raw probabilities (0–1 or 0–100, any scale). They get normalised.
  factory RiskResult.fromProbs(double low, double mid, double high) {
    final sum = low + mid + high;
    if (sum <= 0) return RiskResult._(1 / 3, 1 / 3, 1 / 3);
    return RiskResult._(low / sum, mid / sum, high / sum);
  }

  final double low, mid, high;

  List<double> get probs => [low, mid, high];

  RiskLevel get level {
    final p = probs;
    var best = 0;
    for (var i = 1; i < 3; i++) {
      if (p[i] > p[best]) best = i;
    }
    return RiskLevel.values[best];
  }

  double get confidence => probs[level.index];

  /// Whole-number percentages that always add up to exactly 100.
  List<int> get percents {
    final raw = probs.map((e) => e * 100).toList();
    final fl = raw.map((e) => e.floor()).toList();
    final rem = 100 - fl.reduce((a, b) => a + b);
    final order = List.generate(3, (i) => i)
      ..sort((a, b) => (raw[b] - fl[b]).compareTo(raw[a] - fl[a]));
    for (var i = 0; i < rem && i < 3; i++) {
      fl[order[i]]++;
    }
    return fl;
  }
}

/// Plug your model in here.
abstract class RiskService {
  Future<RiskResult> predict(Vitals v);
}

/// PLACEHOLDER ONLY: simple rule of thumb so the UI works end to end.
/// Replace with your real model before shipping.
class MockRiskService implements RiskService {
  const MockRiskService();

  @override
  Future<RiskResult> predict(Vitals v) async {
    var s = 0;
    if (v.systolic >= 140 || v.diastolic >= 90) {
      s += 2;
    } else if (v.systolic >= 130 || v.diastolic >= 85) {
      s += 1;
    }
    if (v.bloodSugar >= 11) {
      s += 2;
    } else if (v.bloodSugar >= 7.8) {
      s += 1;
    }
    if (v.bodyTemp >= 100.4) s += 1;
    if (v.heartRate >= 100) s += 1;
    if (v.age < 18 || v.age >= 35) s += 1;

    // Fake softmax so the percentages look realistic.
    final logits = [
      2.0 - s * 0.9,
      0.6 - (s - 2).abs() * 0.7,
      -2.0 + s * 0.9,
    ];
    final ex = logits.map(math.exp).toList();
    return RiskResult.fromProbs(ex[0], ex[1], ex[2]);
  }
}


class ApiRiskService implements RiskService {
  ApiRiskService(this.endpoint);

  final Uri endpoint;

  @override
  Future<RiskResult> predict(Vitals v) async {
    final response = await http
        .post(
          endpoint,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(v.toJson()),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'Prediction failed: ${response.statusCode}',
      );
    }

    final data =
        jsonDecode(response.body) as Map<String, dynamic>;

    final probabilities =
        data['probabilities'] as Map<String, dynamic>;

    // Supports the Flask response keys:
    // "Low Risk", "Mid Risk", "High Risk"
    // as well as "low", "mid", "high".
    double readProbability(String shortKey, String fullKey) {
      final value =
          probabilities[shortKey] ?? probabilities[fullKey];

      if (value == null) {
        throw FormatException(
          'Missing probability: $fullKey',
        );
      }

      return (value as num).toDouble();
    }

    return RiskResult.fromProbs(
      readProbability('low', 'Low Risk'),
      readProbability('mid', 'Mid Risk'),
      readProbability('high', 'High Risk'),
    );
  }
}

// ── Example: model served by FastAPI / Flask ──────────────────
// Add `http` to pubspec and these imports:
//   import 'dart:convert';
//   import 'package:http/http.dart' as http;
//
// Your API should return something like:
//   {"probabilities": {"low": 0.12, "mid": 0.23, "high": 0.65}}
// (In Python: model.predict_proba(X)[0] -> map to your class order.)
//
// class ApiRiskService implements RiskService {
//   ApiRiskService(this.endpoint);
//   final Uri endpoint;
//
//   @override
//   Future<RiskResult> predict(Vitals v) async {
//     final res = await http
//         .post(endpoint,
//             headers: {'Content-Type': 'application/json'},
//             body: jsonEncode(v.toJson()))
//         .timeout(const Duration(seconds: 15));
//     if (res.statusCode != 200) throw Exception('Prediction failed');
//     final p = jsonDecode(res.body)['probabilities'] as Map<String, dynamic>;
//     return RiskResult.fromProbs(
//       (p['low'] as num).toDouble(),
//       (p['mid'] as num).toDouble(),
//       (p['high'] as num).toDouble(),
//     );
//   }
// }

// ─────────────────────────────────────────────────────────────
// Small animation helper: fade + slide up with a delay
// ─────────────────────────────────────────────────────────────
class _Reveal extends StatelessWidget {
  const _Reveal({required this.delay, required this.child});
  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const base = 550;
    final total = base + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      builder: (_, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 18), child: c),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class RiskCheckScreen extends StatefulWidget {
  const RiskCheckScreen({super.key, this.service = const MockRiskService()});
  final RiskService service;

  @override
  State<RiskCheckScreen> createState() => _RiskCheckScreenState();
}

class _RiskCheckScreenState extends State<RiskCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _age = TextEditingController();
  final _hr = TextEditingController();
  final _sys = TextEditingController();
  final _dia = TextEditingController();
  final _sugar = TextEditingController();
  final _temp = TextEditingController();

  bool _loading = false;
  RiskResult? _result;
  Vitals? _vitals;

  @override
  void dispose() {
    for (final c in [_age, _hr, _sys, _dia, _sugar, _temp]) {
      c.dispose();
    }
    super.dispose();
  }

  double _n(TextEditingController c) =>
      double.parse(c.text.trim().replaceAll(',', '.'));

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.selectionClick();
      return;
    }
    final v = Vitals(
      age: _n(_age),
      systolic: _n(_sys),
      diastolic: _n(_dia),
      bloodSugar: _n(_sugar),
      bodyTemp: _n(_temp),
      heartRate: _n(_hr),
    );
    setState(() => _loading = true);
    try {
      final minDelay = Future<void>.delayed(const Duration(milliseconds: 700));
      final res = await widget.service.predict(v);
      await minDelay; // keeps the loading state from flashing
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _vitals = v;
        _result = res;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _C.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text("Couldn't get a result. Check your connection and try again.",
            style: _t(13.5, FontWeight.w600, Colors.white)),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // soft decorative blobs
          Positioned(
            top: -90,
            right: -70,
            child: _Blob(size: 260, color: _C.blue.withValues(alpha: .14)),
          ),
          Positioned(
            top: 120,
            left: -110,
            child: _Blob(size: 220, color: _C.low.withValues(alpha: .10)),
          ),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, .04), end: Offset.zero)
                      .animate(anim),
                  child: child,
                ),
              ),
              child: _result == null
                  ? _buildForm(context)
                  : _ResultView(
                      key: ValueKey(_result.hashCode),
                      result: _result!,
                      vitals: _vitals!,
                      onEdit: () => setState(() => _result = null),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Navigator.canPop(context))
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [_softShadow()],
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        size: 20, color: _C.ink),
                  ),
                ),
              ),
            _Reveal(
              delay: 0,
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_C.blue, _C.blueDeep],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [_softShadow(_C.blue, .3)],
                    ),
                    child: const Icon(Icons.monitor_heart_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Risk check',
                            style: _t(28, FontWeight.w800, _C.ink, ls: -.6)),
                        Text('Takes less than a minute',
                            style: _t(13, FontWeight.w500, _C.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _Reveal(
              delay: 60,
              child: Text(
                "Enter your latest readings and we'll estimate your risk level.",
                style: _t(15, FontWeight.w500, _C.muted, h: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            _Reveal(
              delay: 120,
              child: _Section(
                title: 'About you',
                icon: Icons.person_outline_rounded,
                children: [
                  _row(
                    _VitalField(
                        controller: _age,
                        label: 'Age',
                        unit: 'yrs',
                        icon: Icons.cake_outlined,
                        min: 10,
                        max: 60),
                    _VitalField(
                        controller: _hr,
                        label: 'Heart rate',
                        unit: 'bpm',
                        icon: Icons.favorite_border_rounded,
                        min: 40,
                        max: 180),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Reveal(
              delay: 180,
              child: _Section(
                title: 'Blood pressure',
                icon: Icons.speed_rounded,
                children: [
                  _row(
                    _VitalField(
                        controller: _sys,
                        label: 'Systolic',
                        unit: 'mmHg',
                        icon: Icons.arrow_upward_rounded,
                        min: 70,
                        max: 220),
                    _VitalField(
                        controller: _dia,
                        label: 'Diastolic',
                        unit: 'mmHg',
                        icon: Icons.arrow_downward_rounded,
                        min: 40,
                        max: 140),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Reveal(
              delay: 240,
              child: _Section(
                title: 'Other vitals',
                icon: Icons.science_outlined,
                children: [
                  _row(
                    _VitalField(
                        controller: _sugar,
                        label: 'Blood sugar',
                        unit: kSugarUnit,
                        icon: Icons.water_drop_outlined,
                        min: 2,
                        max: 30,
                        decimals: true),
                    _VitalField(
                        controller: _temp,
                        label: 'Body temp',
                        unit: kTempUnit,
                        icon: Icons.thermostat_rounded,
                        min: 94,
                        max: 108,
                        decimals: true,
                        last: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _Reveal(
              delay: 300,
              child: _GradientButton(
                loading: _loading,
                label: 'Check my risk',
                onTap: _loading ? null : _submit,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      size: 14, color: _C.muted),
                  const SizedBox(width: 6),
                  Text('A screening aid, not a diagnosis.',
                      style: _t(12.5, FontWeight.w500, _C.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(Widget a, Widget b) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 14),
          Expanded(child: b),
        ],
      );
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _Section extends StatelessWidget {
  const _Section(
      {required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [_softShadow()],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _C.wash,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: _C.blue),
              ),
              const SizedBox(width: 10),
              Text(title, style: _t(14.5, FontWeight.w700, _C.ink)),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton(
      {required this.label, required this.onTap, required this.loading});
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: loading ? .85 : 1,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_C.blue, _C.blueDeep],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [_softShadow(_C.blueDeep, .35)],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: loading
                    ? const SizedBox(
                        key: ValueKey('spin'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white),
                      )
                    : Row(
                        key: const ValueKey('label'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(label,
                              style: _t(16.5, FontWeight.w700, Colors.white)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 20),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Input field
// ─────────────────────────────────────────────────────────────
class _VitalField extends StatelessWidget {
  const _VitalField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.icon,
    required this.min,
    required this.max,
    this.decimals = false,
    this.last = false,
  });

  final TextEditingController controller;
  final String label, unit;
  final IconData icon;
  final double min, max;
  final bool decimals, last;

  static OutlineInputBorder _b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: w),
      );

  static String _fmt(double n) =>
      n % 1 == 0 ? n.toInt().toString() : n.toString();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: _t(12.5, FontWeight.w600, _C.muted)),
        ),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: decimals),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
                RegExp(decimals ? r'[0-9.,]' : r'[0-9]')),
          ],
          textInputAction: last ? TextInputAction.done : TextInputAction.next,
          cursorColor: _C.blue,
          style: _t(18, FontWeight.w700, _C.ink),
          validator: (v) {
            final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
            if (n == null) return 'Required';
            if (n < min || n > max) return '${_fmt(min)}–${_fmt(max)}';
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: _C.bg,
            hintText: '–',
            hintStyle: _t(18, FontWeight.w700, _C.line),
            prefixIcon: Icon(icon, size: 19, color: _C.blue),
            suffixText: unit,
            suffixStyle: _t(12, FontWeight.w600, _C.muted),
            errorStyle: _t(11.5, FontWeight.w600, _C.high),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            border: _b(_C.line),
            enabledBorder: _b(_C.line),
            focusedBorder: _b(_C.blue, 1.6),
            errorBorder: _b(_C.high),
            focusedErrorBorder: _b(_C.high, 1.6),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Result
// ─────────────────────────────────────────────────────────────
class _ResultView extends StatelessWidget {
  const _ResultView({
    super.key,
    required this.result,
    required this.vitals,
    required this.onEdit,
  });

  final RiskResult result;
  final Vitals vitals;
  final VoidCallback onEdit;

  static String _f(double n) =>
      n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final level = result.level;
    final v = vitals;
    final chips = [
      (Icons.cake_outlined, 'Age ${_f(v.age)}'),
      (Icons.speed_rounded, 'BP ${_f(v.systolic)}/${_f(v.diastolic)}'),
      (Icons.water_drop_outlined, 'Sugar ${_f(v.bloodSugar)}'),
      (Icons.thermostat_rounded, 'Temp ${_f(v.bodyTemp)}°'),
      (Icons.favorite_border_rounded, 'HR ${_f(v.heartRate)}'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
      child: Column(
        children: [
          // ── Hero card ───────────────────────────────────
          _Reveal(
            delay: 0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(34),
                boxShadow: [_softShadow(level.color, .2)],
              ),
              child: Column(
                children: [
                  Text('YOUR RESULT',
                      style: _t(11.5, FontWeight.w700, _C.muted, ls: 1.6)),
                  const SizedBox(height: 14),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1300),
                    curve: Curves.easeOutCubic,
                    builder: (_, t, __) => SizedBox(
                      width: 280,
                      height: 150,
                      child: CustomPaint(
                          painter: _GaugePainter(progress: t, level: level)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: level.color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(level.icon, size: 18, color: level.color),
                        const SizedBox(width: 8),
                        Text(level.title,
                            style:
                                _t(17, FontWeight.w800, level.color, ls: -.2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    level.message,
                    textAlign: TextAlign.center,
                    style: _t(14.5, FontWeight.w500, _C.muted, h: 1.55),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ── Probability breakdown ───────────────────────
          _Reveal(
            delay: 150,
            child: _BreakdownCard(result: result),
          ),
          const SizedBox(height: 18),

          // ── Readings recap ──────────────────────────────
          _Reveal(
            delay: 300,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [_softShadow()],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Readings used',
                      style: _t(14.5, FontWeight.w700, _C.ink)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in chips)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _C.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _C.line),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(c.$1, size: 14, color: _C.blue),
                              const SizedBox(width: 6),
                              Text(c.$2,
                                  style: _t(12.5, FontWeight.w600, _C.ink)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _Reveal(
            delay: 400,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: Text('Edit readings',
                    style: _t(16, FontWeight.w700, _C.ink)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _C.ink,
                  side: const BorderSide(color: _C.line, width: 1.4),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('A screening aid, not a diagnosis.',
              style: _t(12.5, FontWeight.w500, _C.muted)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Probability breakdown card
// ─────────────────────────────────────────────────────────────
class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.result});
  final RiskResult result;

  @override
  Widget build(BuildContext context) {
    final pcts = result.percents;
    final probs = result.probs;
    final top = result.level;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [_softShadow()],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Risk breakdown',
                        style: _t(17, FontWeight.w800, _C.ink, ls: -.2)),
                    const SizedBox(height: 2),
                    Text('How likely each level is',
                        style: _t(12.5, FontWeight.w500, _C.muted)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: top.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${pcts[top.index]}% sure',
                    style: _t(12.5, FontWeight.w700, top.color)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // stacked overview bar
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (_, t, __) => ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 3),
                      Expanded(
                        flex: math.max(1, (probs[i] * 1000 * t).round()),
                        child: Container(color: RiskLevel.values[i].color),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),

          for (var i = 0; i < 3; i++) ...[
            _ProbRow(
              level: RiskLevel.values[i],
              probability: probs[i],
              percent: pcts[i],
              highlighted: RiskLevel.values[i] == top,
              delay: 250 + i * 150,
            ),
            if (i < 2) const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

class _ProbRow extends StatelessWidget {
  const _ProbRow({
    required this.level,
    required this.probability,
    required this.percent,
    required this.highlighted,
    required this.delay,
  });

  final RiskLevel level;
  final double probability;
  final int percent;
  final bool highlighted;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final c = level.color;
    final total = 900 + delay;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      builder: (_, t, __) {
        return Column(
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(level.icon, size: 18, color: c),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    level.short,
                    style: _t(15, highlighted ? FontWeight.w800 : FontWeight.w600,
                        _C.ink),
                  ),
                ),
                Text(
                  '${(percent * t).round()}',
                  style: _t(22, FontWeight.w800, highlighted ? c : _C.ink,
                      ls: -.5),
                ),
                Text('%', style: _t(13, FontWeight.w700, _C.muted)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: c.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (probability * t).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [c.withValues(alpha: .65), c],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: highlighted
                        ? [
                            BoxShadow(
                              color: c.withValues(alpha: .35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Gauge
// ─────────────────────────────────────────────────────────────
class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.progress, required this.level});
  final double progress;
  final RiskLevel level;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    const gap = 0.22; // round caps eat into the gap, so keep it generous
    const colors = [_C.low, _C.mid, _C.high];

    final center = Offset(size.width / 2, size.height - 14);
    final radius = size.width / 2 - 20;
    final rect = Rect.fromCircle(center: center, radius: radius);

    for (var i = 0; i < 3; i++) {
      final active = i == level.index;
      canvas.drawArc(
        rect,
        math.pi + i * math.pi / 3 + gap / 2,
        math.pi / 3 - gap,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = colors[i].withValues(alpha: active ? 1 : .2),
      );
    }

    // Marker sweeps from the left end to the predicted zone.
    final angle = math.pi + math.pi * level.position * progress;
    final m = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(
      m + const Offset(0, 2),
      13,
      Paint()
        ..color = Colors.black.withValues(alpha: .1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(m, 12, Paint()..color = Colors.white);
    canvas.drawCircle(
      m,
      12,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = level.color,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress || old.level != level;
}