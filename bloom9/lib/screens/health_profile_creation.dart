import 'package:appwrite/appwrite.dart';
import 'package:bloom9/screens/onboarding.dart';
import 'package:bloom9/services/appwrite_service.dart';
import 'package:flutter/material.dart';

// ---- Palette derived from app theme (seedColor 0xFF2563EB, white bg) ----
// Falls back to these if Theme.of(context) isn't available in a preview.
const _bg = Colors.white;
const _ink = Color(0xFF0F172A);
const _subtleInk = Color(0xFF64748B);
const _accent = Color(0xFF2563EB);
const _accentSoft = Color(0xFFEFF4FE);
const _card = Colors.white;
const _line = Color(0xFFE6EBF3);

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key, required this.name});
  final String name;

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  
  
  final _formKey = GlobalKey<FormState>();


  DateTime? selectedDate;
  final heightController = TextEditingController();
  final weightController = TextEditingController();

  int pregnancyWeek = 1;

  double get bmi {
    final h = double.tryParse(heightController.text) ?? 0;
    final w = double.tryParse(weightController.text) ?? 0;
    if (h <= 0 || w <= 0) return 0;
    return w / ((h / 100) * (h / 100));
  }

  String get bmiLabel {
    if (bmi == 0) return '';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
    bool isAuthenticating = false;
    
      String get name => widget.name;

      @override
  void initState() {
    super.initState();
    heightController.addListener(() => setState(() {}));
    weightController.addListener(() => setState(() {}));
  }


  Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    isAuthenticating = true;
  });


  if (selectedDate == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select your date of birth")),
    );
    return;
  }

  try {
    final user = await AppwriteService.account.get();

    await AppwriteService.tablesDB.createRow(
      databaseId: "6a410fff001e52dbe195",
      tableId: "health_profile",
      rowId: ID.unique(),
      data: {
        "userId": user.$id,
        "dateOfBirth": selectedDate!.toIso8601String(),
        "height": double.parse(heightController.text),
        "weight": double.parse(weightController.text),
        "pregnancyWeek": pregnancyWeek,
        "bmi": bmi,
        "username": name,
      },
    );

    Navigator.of(context).pushReplacement(MaterialPageRoute( builder: (_) => const OnboardingScreen(),
      ),
    );
  } on AppwriteException catch (e) {
    print(e.code);
    print(e.type);
    print(e.message);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message ?? "Failed to save profile")),
    );
  }
}


  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialDate: DateTime(2000),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _accent,
              onPrimary: Colors.white,
              onSurface: _ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _subtleInk, fontSize: 14),
      prefixIcon: Icon(icon, color: _accent, size: 20),
      filled: true,
      fillColor: _bg,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
    );
  }

  Widget buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: _ink, fontSize: 15),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      decoration: _decoration(label, icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x1A2563EB), Color(0x002563EB)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress + step label
                        Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'STEP 2 OF 3',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                            color: _subtleInk,
                          ),
                        ),
                        const Text(
                          '66%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: .66,
                        minHeight: 4,
                        backgroundColor: _line,
                        valueColor: const AlwaysStoppedAnimation(_accent),
                      ),
                    ),
                    const SizedBox(height: 36),

                    const Text(
                      'Complete your profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "A few details to personalize your journey.",
                      style: TextStyle(
                        color: _subtleInk,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _line),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 16),
                              decoration: BoxDecoration(
                                color: _bg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _line),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined,
                                      color: _accent, size: 19),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      selectedDate == null
                                          ? 'Date of birth'
                                          : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: selectedDate == null
                                            ? _subtleInk
                                            : _ink,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded,
                                      color: _subtleInk, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: buildField(
                                  label: 'Height (cm)',
                                  icon: Icons.straighten,
                                  controller: heightController,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: buildField(
                                  label: 'Weight (kg)',
                                  icon: Icons.monitor_weight_outlined,
                                  controller: weightController,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<int>(
                            value: pregnancyWeek,
                            dropdownColor: _card,
                            style: const TextStyle(color: _ink, fontSize: 15),
                            decoration:
                                _decoration('Pregnancy week', Icons.favorite_outline),
                            items: List.generate(
                              42,
                              (i) => DropdownMenuItem(
                                value: i + 1,
                                child: Text('Week ${i + 1}'),
                              ),
                            ),
                            onChanged: (v) => setState(() => pregnancyWeek = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // BMI readout
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 20),
                      decoration: BoxDecoration(
                        color: _accentSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Current BMI',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _ink,
                              fontSize: 14,
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                bmi == 0 ? '—' : bmi.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: _accent,
                                ),
                              ),
                              if (bmiLabel.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  bmiLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _subtleInk,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: !isAuthenticating ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _submit,
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ) : const Center(
                            child: SizedBox(
                              height: 30,
                              width: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
            ),),
                    ),
                    )],
                ),
              ),
            ),
          ),
        ),
      ),
        ],
      ),
    );
  }
}