import 'package:bloom9/services/appwrite_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // add google_fonts to pubspec.yaml

import 'package:appwrite/appwrite.dart';

/// ---------------------------------------------------------------------
/// THEME — Bloom9 blue / white, softened for warmth
/// ---------------------------------------------------------------------
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
class SymptomDef {
  final String name;
  final IconData icon;
  const SymptomDef(this.name, this.icon);
}

const List<SymptomDef> kCommonSymptoms = [
  SymptomDef('Nausea', Icons.sick_outlined),
  SymptomDef('Vomiting', Icons.local_hospital_outlined),
  SymptomDef('Headache', Icons.psychology_outlined),
  SymptomDef('Dizziness', Icons.blur_circular),
  SymptomDef('Fatigue', Icons.battery_2_bar_outlined),
  SymptomDef('Swollen feet', Icons.airline_seat_legroom_extra),
  SymptomDef('Back pain', Icons.accessibility_new),
  SymptomDef('Abdominal pain', Icons.circle_outlined),
  SymptomDef('Leg cramps', Icons.directions_walk),
  SymptomDef('Constipation', Icons.self_improvement),
  SymptomDef('Heartburn', Icons.local_fire_department_outlined),
  SymptomDef('Shortness of breath', Icons.air),
  SymptomDef('Blurred vision', Icons.visibility_outlined),
  SymptomDef('Vaginal bleeding', Icons.water_drop_outlined),
  SymptomDef('Water leakage', Icons.opacity),
  SymptomDef('Reduced fetal movement', Icons.child_care_outlined),
  SymptomDef('Contractions', Icons.waves),
];

class SymptomEntry {
  final String name;
  int severity;
  String duration;
  String notes;
  SymptomEntry({required this.name, this.severity = 3, this.duration = '', this.notes = ''});
}

class VitalsLog {
  double? weightKg;
  int? systolic;
  int? diastolic;
  double? bloodSugar;
  double? tempC;

  Map<String, dynamic> toJson() => {
        'weight_kg': weightKg,
        'systolic': systolic,
        'diastolic': diastolic,
        'blood_sugar_mgdl': bloodSugar,
        'temperature_c': tempC,
        'logged_at': DateTime.now().toIso8601String(),
      };
}

/// ---------------------------------------------------------------------
/// MAIN SCREEN
/// ---------------------------------------------------------------------
class HealthLogScreen extends StatefulWidget {
  const HealthLogScreen({super.key});
  @override
  State<HealthLogScreen> createState() => _HealthLogScreenState();
}

class _HealthLogScreenState extends State<HealthLogScreen> {
  final _weightCtrl = TextEditingController();
  final _sysCtrl = TextEditingController();
  final _diaCtrl = TextEditingController();
  final _sugarCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();

  final Set<String> _selectedSymptoms = {};
  final Map<String, SymptomEntry> _symptomDetails = {};

  final VitalsLog _vitals = VitalsLog();

  @override
  void initState() {
    super.initState();
    for (final c in [_weightCtrl, _sysCtrl, _diaCtrl, _sugarCtrl, _tempCtrl]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _sysCtrl.dispose();
    _diaCtrl.dispose();
    _sugarCtrl.dispose();
    _tempCtrl.dispose();
    super.dispose();
  }

  int get _vitalsFilled => [
        _weightCtrl.text.isNotEmpty,
        _sysCtrl.text.isNotEmpty && _diaCtrl.text.isNotEmpty,
        _sugarCtrl.text.isNotEmpty,
        _tempCtrl.text.isNotEmpty,
      ].where((v) => v).length;

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
        _symptomDetails.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
        _symptomDetails[symptom] = SymptomEntry(name: symptom);
        _openSymptomDetailSheet(symptom);
      }
    });
  }

  Future<void> _openSymptomDetailSheet(String symptom) async {
  final entry = _symptomDetails[symptom]!;
  final durationCtrl = TextEditingController(text: entry.duration);
  final notesCtrl = TextEditingController(text: entry.notes);
  int severity = entry.severity;
  final icon = kCommonSymptoms.firstWhere((s) => s.name == symptom).icon;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final screenHeight = MediaQuery.of(ctx).size.height;
          final keyboardHeight = MediaQuery.of(ctx).viewInsets.bottom;

          return AnimatedPadding(
            duration: const Duration(milliseconds: 100),
            padding: EdgeInsets.only(bottom: keyboardHeight),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // Never let the sheet try to be taller than the visible
                // area above the keyboard — this is what stops the overflow.
                maxHeight: screenHeight - keyboardHeight - MediaQuery.of(ctx).padding.top,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Bloom9Colors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: Bloom9Colors.border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: Bloom9Colors.heroGradient),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Bloom9Colors.primary.withOpacity(0.28),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(icon, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Text(symptom, style: _display(size: 19)),
                        ],
                      ),
                      const SizedBox(height: 26),

                      Text('HOW INTENSE',
                          style: _body(size: 11.5, w: FontWeight.w700, color: Bloom9Colors.subtext)
                              .copyWith(letterSpacing: 0.8)),
                      const SizedBox(height: 12),
                      _SeveritySelector(
                        value: severity,
                        onChanged: (v) => setSheetState(() => severity = v),
                      ),
                      const SizedBox(height: 24),

                      Text('DURATION',
                          style: _body(size: 11.5, w: FontWeight.w700, color: Bloom9Colors.subtext)
                              .copyWith(letterSpacing: 0.8)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['<1 hour', '1–3 hours', 'Most of the day', 'Ongoing'].map((d) {
                          final selected = durationCtrl.text == d;
                          return GestureDetector(
                            onTap: () => setSheetState(() => durationCtrl.text = d),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                              decoration: BoxDecoration(
                                color: selected ? Bloom9Colors.primary : Bloom9Colors.chipUnselected,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(d,
                                  style: _body(
                                      size: 12.5,
                                      w: FontWeight.w600,
                                      color: selected ? Colors.white : Bloom9Colors.subtext)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      _SoftField(controller: durationCtrl, hint: 'Or type a custom duration'),
                      const SizedBox(height: 22),

                      Text('NOTES',
                          style: _body(size: 11.5, w: FontWeight.w700, color: Bloom9Colors.subtext)
                              .copyWith(letterSpacing: 0.8)),
                      const SizedBox(height: 10),
                      _SoftField(controller: notesCtrl, hint: 'Anything else worth remembering…', maxLines: 3),
                      const SizedBox(height: 26),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(colors: Bloom9Colors.heroGradient),
                            boxShadow: [
                              BoxShadow(
                                color: Bloom9Colors.primary.withOpacity(0.32),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                setState(() {
                                  entry.severity = severity;
                                  entry.duration = durationCtrl.text.trim();
                                  entry.notes = notesCtrl.text.trim();
                                });
                                Navigator.pop(ctx);
                              },
                              child: Center(
                                child: Text('Save details',
                                    style: _display(size: 15.5, w: FontWeight.w700, color: Colors.white)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
  Color _severityColor(int level) {
    switch (level) {
      case 1:
        return const Color(0xFF4CB782);
      case 2:
        return const Color(0xFF9BCB53);
      case 3:
        return const Color(0xFFEFB93B);
      case 4:
        return const Color(0xFFF0863C);
      default:
        return Bloom9Colors.danger;
    }
  }


  void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}

bool validateDouble(
  TextEditingController controller,
  String fieldName,
  double min,
  double max,
) {
  if (controller.text.isEmpty) {
    _showError("$fieldName is required.");
    return false;
  }

  final value = double.tryParse(controller.text);

  if (value == null) {
    _showError("$fieldName must be a number.");
    return false;
  }

  if (value < min || value > max) {
    _showError("$fieldName must be between $min and $max.");
    return false;
  }

  return true;
}


bool validateInt(
  TextEditingController controller,
  String fieldName,
  int min,
  int max,
) {
  if (controller.text.isEmpty) {
    _showError("$fieldName is required.");
    return false;
  }

  final value = int.tryParse(controller.text);

  if (value == null) {
    _showError("$fieldName must be a number.");
    return false;
  }

  if (value < min || value > max) {
    _showError("$fieldName must be between $min and $max.");
    return false;
  }

  return true;
}


Future<void> _saveLog() async {

   

final user = await AppwriteService.account.get();
final userId = user.$id;

  try{
    _vitals
      ..weightKg = double.tryParse(_weightCtrl.text)
      ..systolic = int.tryParse(_sysCtrl.text)
      ..diastolic = int.tryParse(_diaCtrl.text)
      ..bloodSugar = double.tryParse(_sugarCtrl.text)
      ..tempC = double.tryParse(_tempCtrl.text);

    // TODO: persist `_vitals` and `_symptomDetails.values` to Appwrite TablesDB
    // tablesDB.createRow(databaseId, 'vitals_logs', ..._vitals.toJson());

    if (_weightCtrl.text.trim().isEmpty &&
    _sysCtrl.text.trim().isEmpty &&
    _diaCtrl.text.trim().isEmpty &&
    _sugarCtrl.text.trim().isEmpty &&
    _tempCtrl.text.trim().isEmpty &&
    _selectedSymptoms.isEmpty) {
  _showError("Please enter health details.");
  return;
}
      if (!validateDouble(_weightCtrl, "Weight", 30, 250)) return;

      if (!validateInt(_sysCtrl, "Systolic BP", 70, 250)) return;

      if (!validateInt(_diaCtrl, "Diastolic BP", 40, 150)) return;

      if (!validateDouble(_sugarCtrl, "Blood Sugar", 20, 600)) return;

      if (!validateDouble(_tempCtrl, "Temperature", 30, 200)) return;
        

  final healthLog = await AppwriteService.tablesDB.createRow(
      databaseId: AppwriteService.databaseId,
      tableId: AppwriteService.daily_health_logs,
      rowId: ID.unique(),
      data: {
        "userId": userId,
        "logDate": DateTime.now().toIso8601String(),
        "weight": _vitals.weightKg,
        "systolicBP": _vitals.systolic,
        "diastolicBP": _vitals.diastolic,
        "bloodSugar": _vitals.bloodSugar,
        "temperature": _vitals.tempC,
      },
    );

    final logId = healthLog.$id;
    
    for (final symptom in _symptomDetails.values) {
      await AppwriteService.tablesDB.createRow(
        databaseId: AppwriteService.databaseId,
        tableId: AppwriteService.symtom_logs,
        rowId: ID.unique(),
        data: {
          "dailyHeallthLogs": logId,
          "symtom": symptom.name,
          "severity": symptom.severity,
          "duration": symptom.duration,
          "notes": symptom.notes,
        },
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Health log saved sucessfully'),
        )
    );
    Navigator.of(context).pop();

  }catch (e){
    debugPrint(e.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString()))
    );
  }
  
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = '${months[today.month - 1]} ${today.day}, ${today.year}';

    return Scaffold(
      backgroundColor: Bloom9Colors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _hero(dateStr)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _sectionHeader('Vitals', '$_vitalsFilled of 4 logged'),
                const SizedBox(height: 14),
                _vitalsGrid(),
                const SizedBox(height: 30),
                _sectionHeader('How are you feeling?',
                    _selectedSymptoms.isEmpty ? 'Tap any that apply' : '${_selectedSymptoms.length} selected'),
                const SizedBox(height: 14),
                _symptomChips(),
                if (_selectedSymptoms.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Details', style: _display(size: 15.5)),
                  const SizedBox(height: 10),
                  ..._selectedSymptoms.map(_selectedSymptomTile),
                ],
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _saveBar(),
    );
  }

  Widget _hero(String dateStr) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 34),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: Bloom9Colors.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -30,
            top: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            right: 40,
            top: 10,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), shape: BoxShape.circle),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.arrow_back_ios_new, color: Colors.white.withOpacity(0.9), size: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(dateStr, style: _body(size: 12, w: FontWeight.w600, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text('Daily check-in', style: _display(size: 27, w: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 6),
              Text('Log your vitals and how you feel today',
                  style: _body(size: 13.5, color: Colors.white.withOpacity(0.88))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: _display(size: 17.5)),
        Text(trailing, style: _body(size: 12.5, color: Bloom9Colors.subtext, w: FontWeight.w600)),
      ],
    );
  }

  Widget _vitalsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _vitalCard(
                icon: Icons.monitor_weight_outlined,
                label: 'Weight',
                unit: 'kg',
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                accent: const Color(0xFF0191F7),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _bpCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _vitalCard(
                icon: Icons.water_drop_outlined,
                label: 'Blood sugar',
                unit: 'mg/dL',
                controller: _sugarCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                accent: const Color(0xFFE58A3B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _vitalCard(
                icon: Icons.thermostat_outlined,
                label: 'Temperature',
                unit: '°C',
                controller: _tempCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                accent: const Color(0xFFE5484D),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Bloom9Colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Bloom9Colors.border),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0191F7).withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _vitalCard({
    required IconData icon,
    required String label,
    required String unit,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required Color accent,
  }) {
    final filled = controller.text.isNotEmpty;
    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 17, color: accent),
              ),
              const Spacer(),
              if (filled) Container(width: 7, height: 7, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 10),
          Text(label, style: _body(size: 12, color: Bloom9Colors.subtext, w: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: _display(size: 20, w: FontWeight.w800),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: '—',
                    hintStyle: _display(size: 20, w: FontWeight.w800, color: Bloom9Colors.border),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 3, left: 3),
                child: Text(unit, style: _body(size: 11.5, color: Bloom9Colors.subtext, w: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bpCard() {
    final filled = _sysCtrl.text.isNotEmpty && _diaCtrl.text.isNotEmpty;
    return _cardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: const Color(0xFFE5484D).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.favorite_border, size: 16, color: Color(0xFFE5484D)),
              ),
              const Spacer(),
              if (filled)
                Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFFE5484D), shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 10),
          Text('Blood pressure', style: _body(size: 12, color: Bloom9Colors.subtext, w: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sysCtrl,
                  keyboardType: TextInputType.number,
                  style: _display(size: 20, w: FontWeight.w800),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: '120',
                    hintStyle: _display(size: 20, w: FontWeight.w800, color: Bloom9Colors.border),
                  ),
                ),
              ),
              Text('/', style: _display(size: 18, color: Bloom9Colors.subtext)),
              Expanded(
                child: TextField(
                  controller: _diaCtrl,
                  keyboardType: TextInputType.number,
                  style: _display(size: 20, w: FontWeight.w800),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: '80',
                    hintStyle: _display(size: 20, w: FontWeight.w800, color: Bloom9Colors.border),
                  ),
                ),
              ),
            ],
          ),
          Text('mmHg', style: _body(size: 11.5, color: Bloom9Colors.subtext, w: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _symptomChips() {
    return Wrap(
      spacing: 9,
      runSpacing: 10,
      children: kCommonSymptoms.map((s) {
        final selected = _selectedSymptoms.contains(s.name);
        return GestureDetector(
          onTap: () => _toggleSymptom(s.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: selected ? const LinearGradient(colors: Bloom9Colors.heroGradient) : null,
              color: selected ? null : Bloom9Colors.chipUnselected,
              borderRadius: BorderRadius.circular(24),
              boxShadow: selected
                  ? [BoxShadow(color: Bloom9Colors.primary.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 4))]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(s.icon, size: 15, color: selected ? Colors.white : Bloom9Colors.primary),
                const SizedBox(width: 6),
                Text(s.name, style: _body(size: 12.8, w: FontWeight.w600, color: selected ? Colors.white : Bloom9Colors.ink)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _selectedSymptomTile(String symptom) {
    final entry = _symptomDetails[symptom]!;
    final icon = kCommonSymptoms.firstWhere((s) => s.name == symptom).icon;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: _cardShell(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: _severityColor(entry.severity).withOpacity(0.14), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 19, color: _severityColor(entry.severity)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(symptom, style: _display(size: 14.5)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _severityDots(entry.severity),
                      if (entry.duration.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text('• ${entry.duration}', style: _body(size: 12, color: Bloom9Colors.subtext)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 17, color: Bloom9Colors.primary),
              onPressed: () => _openSymptomDetailSheet(symptom),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: Bloom9Colors.subtext),
              onPressed: () => _toggleSymptom(symptom),
            ),
          ],
        ),
      ),
    );
  }

  Widget _severityDots(int level) {
    return Row(
      children: List.generate(5, (i) {
        final active = i < level;
        return Container(
          width: 5.5,
          height: 5.5,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(color: active ? _severityColor(level) : Bloom9Colors.border, shape: BoxShape.circle),
        );
      }),
    );
  }

  Widget _saveBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Bloom9Colors.background.withOpacity(0), Bloom9Colors.background],
            stops: const [0, 0.35],
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(colors: Bloom9Colors.heroGradient),
              boxShadow: [
                BoxShadow(color: Bloom9Colors.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _saveLog,
                child: Center(
                  child: Text('Save check-in', style: _display(size: 16, w: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// SMALL REUSABLE PIECES
/// ---------------------------------------------------------------------
class _SoftField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _SoftField({required this.controller, required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: _body(size: 14, w: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _body(size: 13, color: Bloom9Colors.subtext),
        filled: true,
        fillColor: Bloom9Colors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Bloom9Colors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _SeveritySelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _SeveritySelector({required this.value, required this.onChanged});

  static const _labels = ['Mild', 'Noticeable', 'Moderate', 'Severe', 'Very severe'];
  static const _colors = [
    Color(0xFF4CB782),
    Color(0xFF9BCB53),
    Color(0xFFEFB93B),
    Color(0xFFF0863C),
    Color(0xFFE5484D),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(5, (i) {
            final level = i + 1;
            final selected = value == level;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(right: 7),
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? _colors[i] : Bloom9Colors.background,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: selected
                        ? [BoxShadow(color: _colors[i].withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 5))]
                        : [],
                  ),
                  child: Text('$level', style: _display(size: 16, w: FontWeight.w800, color: selected ? Colors.white : Bloom9Colors.subtext)),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Text(_labels[value - 1], style: _body(size: 12.5, w: FontWeight.w600, color: _colors[value - 1])),
      ],
    );
  }
}