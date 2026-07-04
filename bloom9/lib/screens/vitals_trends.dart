import 'package:bloom9/services/appwrite_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // add google_fonts to pubspec.yaml
import 'package:fl_chart/fl_chart.dart'; // add fl_chart to pubspec.yaml
import 'package:appwrite/appwrite.dart';

/// ---------------------------------------------------------------------
/// THEME — matches HealthLogScreen (Bloom9Colors is already defined there;
/// if this file is compiled standalone, keep this import removed and reuse
/// the Bloom9Colors class from logs.dart instead of redeclaring it).
/// ---------------------------------------------------------------------
// If Bloom9Colors already exists in your project (e.g. from logs.dart),
// delete this class and import it instead to avoid a duplicate-definition error.
// import 'package:bloom9/screens/logs.dart' show Bloom9Colors;

class Bloom9Colors {
  static const Color primary = Color(0xFF0191F7);
  static const Color primaryDeep = Color(0xFF046BC1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF3F8FE);
  static const Color ink = Color(0xFF14202B);
  static const Color subtext = Color(0xFF7C8797);
  static const Color border = Color(0xFFE6EFF9);
  static const Color chipUnselected = Color(0xFFF1F6FC);
  static const Color danger = Color(0xFFE5484D);
  static const List<Color> heroGradient = [Color(0xFF0191F7), Color(0xFF3EA6F5), Color(0xFF6FC2FF)];
}

TextStyle _display({double size = 20, FontWeight w = FontWeight.w700, Color color = Bloom9Colors.ink, double? letterSpacing}) =>
    GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: w, color: color, letterSpacing: letterSpacing);

TextStyle _body({double size = 14, FontWeight w = FontWeight.w500, Color color = Bloom9Colors.ink}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: w, color: color);

/// ---------------------------------------------------------------------
/// MODELS
/// ---------------------------------------------------------------------
enum VitalMetric { weight, bloodPressure, sugar }

class VitalPoint {
  final DateTime date;
  final double? weight;
  final int? systolic;
  final int? diastolic;
  final double? sugar;

  VitalPoint({required this.date, this.weight, this.systolic, this.diastolic, this.sugar});
}

/// ---------------------------------------------------------------------
/// MAIN SCREEN
/// ---------------------------------------------------------------------
class VitalsTrendsScreen extends StatefulWidget {
  const VitalsTrendsScreen({super.key});
  @override
  State<VitalsTrendsScreen> createState() => _VitalsTrendsScreenState();
}

class _VitalsTrendsScreenState extends State<VitalsTrendsScreen> {
  VitalMetric _selected = VitalMetric.weight;
  int _rangeDays = 30; // 7 / 30 / 90
  bool _loading = true;
  String? _error;
  List<VitalPoint> _points = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await AppwriteService.account.get();
      final userId = user.$id;

      final result = await AppwriteService.tablesDB.listRows(
        databaseId: AppwriteService.databaseId,
        tableId: AppwriteService.daily_health_logs,
        queries: [
          Query.equal('userId', userId),
          Query.orderAsc('logDate'),
          Query.limit(500),
        ],
      );

      final cutoff = DateTime.now().subtract(Duration(days: _rangeDays));
      final pts = result.rows
          .map((row) {
            final data = row.data;
            final date = DateTime.tryParse(data['logDate'] ?? '') ?? DateTime.now();
            return VitalPoint(
              date: date,
              weight: (data['weight'] as num?)?.toDouble(),
              systolic: (data['systolicBP'] as num?)?.toInt(),
              diastolic: (data['diastolicBP'] as num?)?.toInt(),
              sugar: (data['bloodSugar'] as num?)?.toDouble(),
            );
          })
          .where((p) => p.date.isAfter(cutoff))
          .toList();

      setState(() {
        _points = pts;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // -- data helpers for the currently selected metric --------------------

  List<VitalPoint> get _metricPoints {
    switch (_selected) {
      case VitalMetric.weight:
        return _points.where((p) => p.weight != null).toList();
      case VitalMetric.bloodPressure:
        return _points.where((p) => p.systolic != null && p.diastolic != null).toList();
      case VitalMetric.sugar:
        return _points.where((p) => p.sugar != null).toList();
    }
  }

  Color get _accent {
    switch (_selected) {
      case VitalMetric.weight:
        return Bloom9Colors.primary;
      case VitalMetric.bloodPressure:
        return const Color(0xFFE5484D);
      case VitalMetric.sugar:
        return const Color(0xFFE58A3B);
    }
  }

  String get _unit {
    switch (_selected) {
      case VitalMetric.weight:
        return 'kg';
      case VitalMetric.bloodPressure:
        return 'mmHg';
      case VitalMetric.sugar:
        return 'mg/dL';
    }
  }

  double? get _latest {
    final pts = _metricPoints;
    if (pts.isEmpty) return null;
    switch (_selected) {
      case VitalMetric.weight:
        return pts.last.weight;
      case VitalMetric.bloodPressure:
        return pts.last.systolic?.toDouble();
      case VitalMetric.sugar:
        return pts.last.sugar;
    }
  }

  double? get _average {
    final pts = _metricPoints;
    if (pts.isEmpty) return null;
    switch (_selected) {
      case VitalMetric.weight:
        return pts.map((p) => p.weight!).reduce((a, b) => a + b) / pts.length;
      case VitalMetric.bloodPressure:
        return pts.map((p) => p.systolic!).reduce((a, b) => a + b) / pts.length;
      case VitalMetric.sugar:
        return pts.map((p) => p.sugar!).reduce((a, b) => a + b) / pts.length;
    }
  }

  double? get _min {
    final pts = _metricPoints;
    if (pts.isEmpty) return null;
    switch (_selected) {
      case VitalMetric.weight:
        return pts.map((p) => p.weight!).reduce((a, b) => a < b ? a : b);
      case VitalMetric.bloodPressure:
        return pts.map((p) => p.diastolic!.toDouble()).reduce((a, b) => a < b ? a : b);
      case VitalMetric.sugar:
        return pts.map((p) => p.sugar!).reduce((a, b) => a < b ? a : b);
    }
  }

  double? get _max {
    final pts = _metricPoints;
    if (pts.isEmpty) return null;
    switch (_selected) {
      case VitalMetric.weight:
        return pts.map((p) => p.weight!).reduce((a, b) => a > b ? a : b);
      case VitalMetric.bloodPressure:
        return pts.map((p) => p.systolic!.toDouble()).reduce((a, b) => a > b ? a : b);
      case VitalMetric.sugar:
        return pts.map((p) => p.sugar!).reduce((a, b) => a > b ? a : b);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Bloom9Colors.background,
      body: RefreshIndicator(
        color: Bloom9Colors.primary,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _hero()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _metricSelector(),
                  const SizedBox(height: 18),
                  _rangeSelector(),
                  const SizedBox(height: 18),
                  if (_loading)
                    _loadingCard()
                  else if (_error != null)
                    _errorCard()
                  else if (_metricPoints.isEmpty)
                    _emptyCard()
                  else ...[
                    _statsRow(),
                    const SizedBox(height: 16),
                    _chartCard(),
                    const SizedBox(height: 24),
                    Text('Recent entries', style: _display(size: 16)),
                    const SizedBox(height: 10),
                    ..._metricPoints.reversed.take(8).map(_entryTile),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- hero ---------------------------------------------------------------

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 34),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: Bloom9Colors.heroGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -30,
            top: -40,
            child: Container(width: 140, height: 140, decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle)),
          ),
          Positioned(
            right: 46,
            top: 6,
            child: Container(width: 54, height: 54, decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), shape: BoxShape.circle)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Icon(Icons.arrow_back_ios_new, color: Colors.white.withOpacity(0.9), size: 18),
                  ),
                  GestureDetector(
                    onTap: _loadData,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text('Your trends', style: _display(size: 27, w: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 6),
              Text('Weight, blood pressure & blood sugar over time',
                  style: _body(size: 13.5, color: Colors.white.withOpacity(0.88))),
            ],
          ),
        ],
      ),
    );
  }

  // -- selectors ------------------------------------------------------------

  Widget _metricSelector() {
    final items = [
      (VitalMetric.weight, 'Weight', Icons.monitor_weight_outlined),
      (VitalMetric.bloodPressure, 'Blood pressure', Icons.favorite_border),
      (VitalMetric.sugar, 'Blood sugar', Icons.water_drop_outlined),
    ];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Bloom9Colors.chipUnselected,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: items.map((item) {
          final selected = _selected == item.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selected = item.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: selected ? Bloom9Colors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? [BoxShadow(color: Bloom9Colors.primary.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Column(
                  children: [
                    Icon(item.$3, size: 17, color: selected ? _accentFor(item.$1) : Bloom9Colors.subtext),
                    const SizedBox(height: 4),
                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      style: _body(size: 11, w: FontWeight.w700, color: selected ? Bloom9Colors.ink : Bloom9Colors.subtext),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _accentFor(VitalMetric m) {
    switch (m) {
      case VitalMetric.weight:
        return Bloom9Colors.primary;
      case VitalMetric.bloodPressure:
        return const Color(0xFFE5484D);
      case VitalMetric.sugar:
        return const Color(0xFFE58A3B);
    }
  }

  Widget _rangeSelector() {
    final ranges = [7, 30, 90];
    return Row(
      children: ranges.map((r) {
        final selected = _rangeDays == r;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              setState(() => _rangeDays = r);
              _loadData();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? _accent : Bloom9Colors.chipUnselected,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                r == 7 ? '7 days' : r == 30 ? '30 days' : '90 days',
                style: _body(size: 12.5, w: FontWeight.w700, color: selected ? Colors.white : Bloom9Colors.subtext),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // -- stats row ------------------------------------------------------------

  Widget _statsRow() {
    String fmt(double? v) => v == null ? '—' : v.toStringAsFixed(_selected == VitalMetric.bloodPressure ? 0 : 1);
    return Row(
      children: [
        Expanded(child: _statCard('Latest', fmt(_latest), _unit, _accent)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('Average', fmt(_average), _unit, Bloom9Colors.ink)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('Range', '${fmt(_min)}–${fmt(_max)}', _unit, Bloom9Colors.subtext)),
      ],
    );
  }

  Widget _statCard(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Bloom9Colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Bloom9Colors.border),
        boxShadow: [BoxShadow(color: Bloom9Colors.primary.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: _body(size: 10, w: FontWeight.w700, color: Bloom9Colors.subtext).copyWith(letterSpacing: 0.6)),
          const SizedBox(height: 6),
          Text(value, style: _display(size: 16.5, w: FontWeight.w800, color: color)),
          Text(unit, style: _body(size: 10.5, color: Bloom9Colors.subtext)),
        ],
      ),
    );
  }

  // -- chart ------------------------------------------------------------

  Widget _chartCard() {
    final pts = _metricPoints;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 12),
      decoration: BoxDecoration(
        color: Bloom9Colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Bloom9Colors.border),
        boxShadow: [BoxShadow(color: Bloom9Colors.primary.withOpacity(0.05), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: SizedBox(
        height: 220,
        child: LineChart(
          _selected == VitalMetric.bloodPressure ? _bpChartData(pts) : _singleLineChartData(pts),
          duration: const Duration(milliseconds: 300),
        ),
      ),
    );
  }

  LineChartData _singleLineChartData(List<VitalPoint> pts) {
    final spots = <FlSpot>[];
    for (var i = 0; i < pts.length; i++) {
      final p = pts[i];
      final y = _selected == VitalMetric.weight ? p.weight! : p.sugar!;
      spots.add(FlSpot(i.toDouble(), y));
    }
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _gridInterval(spots),
        getDrawingHorizontalLine: (v) => FlLine(color: Bloom9Colors.border, strokeWidth: 1),
      ),
      titlesData: _titlesData(pts),
      borderData: FlBorderData(show: false),
      lineTouchData: _touchData(pts, unit: _unit),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.25,
          color: _accent,
          barWidth: 3,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, pct, bar, i) => FlDotCirclePainter(radius: 3.5, color: _accent, strokeWidth: 2, strokeColor: Colors.white),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_accent.withOpacity(0.22), _accent.withOpacity(0.0)],
            ),
          ),
        ),
      ],
    );
  }

  LineChartData _bpChartData(List<VitalPoint> pts) {
    final sysSpots = <FlSpot>[];
    final diaSpots = <FlSpot>[];
    for (var i = 0; i < pts.length; i++) {
      sysSpots.add(FlSpot(i.toDouble(), pts[i].systolic!.toDouble()));
      diaSpots.add(FlSpot(i.toDouble(), pts[i].diastolic!.toDouble()));
    }
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (v) => FlLine(color: Bloom9Colors.border, strokeWidth: 1),
      ),
      titlesData: _titlesData(pts),
      borderData: FlBorderData(show: false),
      lineTouchData: _touchData(pts, unit: 'mmHg'),
      lineBarsData: [
        LineChartBarData(
          spots: sysSpots,
          isCurved: true,
          curveSmoothness: 0.25,
          color: const Color(0xFFE5484D),
          barWidth: 3,
          dotData: FlDotData(show: true, getDotPainter: (s, p, b, i) => FlDotCirclePainter(radius: 3.5, color: const Color(0xFFE5484D), strokeWidth: 2, strokeColor: Colors.white)),
        ),
        LineChartBarData(
          spots: diaSpots,
          isCurved: true,
          curveSmoothness: 0.25,
          color: const Color(0xFF5FB8FA),
          barWidth: 3,
          dotData: FlDotData(show: true, getDotPainter: (s, p, b, i) => FlDotCirclePainter(radius: 3.5, color: const Color(0xFF5FB8FA), strokeWidth: 2, strokeColor: Colors.white)),
        ),
      ],
    );
  }

  double _gridInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 1;
    final ys = spots.map((s) => s.y).toList();
    final range = ys.reduce((a, b) => a > b ? a : b) - ys.reduce((a, b) => a < b ? a : b);
    if (range <= 0) return 1;
    return (range / 4).clamp(1, double.infinity);
  }

  FlTitlesData _titlesData(List<VitalPoint> pts) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 34,
          getTitlesWidget: (value, meta) => Text(
            value.toStringAsFixed(0),
            style: _body(size: 10, color: Bloom9Colors.subtext),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 26,
          interval: (pts.length / 4).clamp(1, double.infinity).roundToDouble(),
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i < 0 || i >= pts.length) return const SizedBox.shrink();
            final d = pts[i].date;
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('${d.day}/${d.month}', style: _body(size: 10, color: Bloom9Colors.subtext)),
            );
          },
        ),
      ),
    );
  }

  LineTouchData _touchData(List<VitalPoint> pts, {required String unit}) {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => Bloom9Colors.ink,
        tooltipRoundedRadius: 12,
        getTooltipItems: (spots) => spots.map((s) {
          final i = s.x.toInt();
          final d = i >= 0 && i < pts.length ? pts[i].date : null;
          final dateLabel = d != null ? '${d.day}/${d.month}  ' : '';
          return LineTooltipItem(
            '$dateLabel${s.y.toStringAsFixed(1)} $unit',
            _body(size: 11.5, w: FontWeight.w600, color: Colors.white),
          );
        }).toList(),
      ),
    );
  }

  // -- entries / states ------------------------------------------------------------

  Widget _entryTile(VitalPoint p) {
    String valueText;
    switch (_selected) {
      case VitalMetric.weight:
        valueText = '${p.weight!.toStringAsFixed(1)} kg';
        break;
      case VitalMetric.bloodPressure:
        valueText = '${p.systolic}/${p.diastolic} mmHg';
        break;
      case VitalMetric.sugar:
        valueText = '${p.sugar!.toStringAsFixed(1)} mg/dL';
        break;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Bloom9Colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Bloom9Colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text('${p.date.day}/${p.date.month}/${p.date.year}', style: _body(size: 13, w: FontWeight.w600)),
          const Spacer(),
          Text(valueText, style: _display(size: 14, w: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: Bloom9Colors.primary),
    );
  }

  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Bloom9Colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Bloom9Colors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Bloom9Colors.danger, size: 28),
          const SizedBox(height: 10),
          Text('Could not load your trends', style: _display(size: 15)),
          const SizedBox(height: 4),
          Text(_error ?? '', style: _body(size: 12, color: Bloom9Colors.subtext), textAlign: TextAlign.center),
          const SizedBox(height: 14),
          TextButton(onPressed: _loadData, child: Text('Try again', style: _body(w: FontWeight.w700, color: Bloom9Colors.primary))),
        ],
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      decoration: BoxDecoration(
        color: Bloom9Colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Bloom9Colors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: _accent.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.show_chart_rounded, color: _accent, size: 26),
          ),
          const SizedBox(height: 14),
          Text('No data in this range yet', style: _display(size: 15)),
          const SizedBox(height: 4),
          Text('Log a check-in to start seeing trends here.', style: _body(size: 12.5, color: Bloom9Colors.subtext), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}