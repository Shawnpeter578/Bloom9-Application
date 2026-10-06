import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────
// BLOOM9 — Appointment Booking Screen
// Theme: Blue (#0191F7) & White, consistent with Bloom9 design system
// ─────────────────────────────────────────────────────────────

class AppColors {
  static const primaryBlue = Color(0xFF0191F7);
  static const deepBlue = Color(0xFF045C9E);
  static const softBlue = Color(0xFFE7F3FE);
  static const pink = Color(0xFFE28ABE);
  static const coral = Color(0xFFFF8A8A);
  static const bgLight = Color(0xFFF3F8FE);
  static const bgSoft = Color(0xFFF7F9FC);
  static const textDark = Color(0xFF16233A);
  static const textMuted = Color(0xFF7B8AA0);
  static const white = Colors.white;
}

// ─────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────

enum Specialty { obGyn, mfm, familyMed }

extension SpecialtyLabel on Specialty {
  String get label {
    switch (this) {
      case Specialty.obGyn:
        return 'OB-GYN';
      case Specialty.mfm:
        return 'MFM Specialist';
      case Specialty.familyMed:
        return 'Family Medicine';
    }
  }

  String get fullLabel {
    switch (this) {
      case Specialty.obGyn:
        return 'Obstetrician-Gynecologist';
      case Specialty.mfm:
        return 'Maternal-Fetal Medicine / Perinatologist';
      case Specialty.familyMed:
        return 'Family Medicine Physician';
    }
  }

  IconData get icon {
    switch (this) {
      case Specialty.obGyn:
        return Icons.pregnant_woman_rounded;
      case Specialty.mfm:
        return Icons.favorite_rounded;
      case Specialty.familyMed:
        return Icons.health_and_safety;
    }
  }
}

class Doctor {
  final String name;
  final Specialty specialty;
  final String qualification;
  final double rating;
  final int reviews;
  final int experienceYears;
  final String avatarSeed; // used to pick a color/initial avatar
  final List<String> availableSlots;
  final String hospital;

  const Doctor({
    required this.name,
    required this.specialty,
    required this.qualification,
    required this.rating,
    required this.reviews,
    required this.experienceYears,
    required this.avatarSeed,
    required this.availableSlots,
    required this.hospital,
  });
}

// Mock data
final List<Doctor> kDoctors = [
  Doctor(
    name: 'Dr. Ananya Rao',
    specialty: Specialty.obGyn,
    qualification: 'MBBS, MS (OBG)',
    rating: 4.9,
    reviews: 214,
    experienceYears: 12,
    avatarSeed: 'AR',
    hospital: 'Highland Women\'s Clinic',
    availableSlots: ['9:00 AM', '11:30 AM', '3:00 PM', '5:30 PM'],
  ),
  Doctor(
    name: 'Dr. Priya Menon',
    specialty: Specialty.obGyn,
    qualification: 'MBBS, DGO, FICOG',
    rating: 4.8,
    reviews: 178,
    experienceYears: 9,
    avatarSeed: 'PM',
    hospital: 'Sunrise Maternity Center',
    availableSlots: ['10:00 AM', '1:00 PM', '4:15 PM'],
  ),
  Doctor(
    name: 'Dr. Kavitha Shenoy',
    specialty: Specialty.mfm,
    qualification: 'MD, FMFM (Perinatology)',
    rating: 5.0,
    reviews: 96,
    experienceYears: 15,
    avatarSeed: 'KS',
    hospital: 'St. Aloysius Fetal Care Unit',
    availableSlots: ['9:30 AM', '12:00 PM', '2:30 PM'],
  ),
  Doctor(
    name: 'Dr. Rohan Fernandes',
    specialty: Specialty.mfm,
    qualification: 'MD, DM (Maternal-Fetal Medicine)',
    rating: 4.7,
    reviews: 63,
    experienceYears: 11,
    avatarSeed: 'RF',
    hospital: 'Coastal Perinatal Institute',
    availableSlots: ['11:00 AM', '3:45 PM'],
  ),
  Doctor(
    name: 'Dr. Meera Pinto',
    specialty: Specialty.familyMed,
    qualification: 'MBBS, MD (Family Medicine)',
    rating: 4.6,
    reviews: 152,
    experienceYears: 7,
    avatarSeed: 'MP',
    hospital: 'Bloom9 Community Health',
    availableSlots: ['9:00 AM', '10:30 AM', '4:00 PM', '5:00 PM'],
  ),
  Doctor(
    name: 'Dr. Sameer Kulkarni',
    specialty: Specialty.familyMed,
    qualification: 'MBBS, DFM',
    rating: 4.5,
    reviews: 88,
    experienceYears: 6,
    avatarSeed: 'SK',
    hospital: 'Mangala Family Clinic',
    availableSlots: ['1:30 PM', '2:00 PM', '5:45 PM'],
  ),
];

// ─────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────

class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({super.key});

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  Specialty? _selectedSpecialty; // null = All
  Doctor? _selectedDoctor;
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  final _searchController = TextEditingController();
  String _query = '';

  List<DateTime> get _next7Days =>
      List.generate(7, (i) => DateTime.now().add(Duration(days: i)));

  List<Doctor> get _filteredDoctors {
    return kDoctors.where((d) {
      final matchesSpecialty =
          _selectedSpecialty == null || d.specialty == _selectedSpecialty;
      final matchesQuery = _query.isEmpty ||
          d.name.toLowerCase().contains(_query.toLowerCase()) ||
          d.hospital.toLowerCase().contains(_query.toLowerCase());
      return matchesSpecialty && matchesQuery;
    }).toList();
  }

  void _selectDoctor(Doctor doc) {
    setState(() {
      _selectedDoctor = doc;
      _selectedSlot = null;
    });
  }

  void _confirmBooking() {
    if (_selectedDoctor == null || _selectedSlot == null) return;
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _BookingConfirmationSheet(
        doctor: _selectedDoctor!,
        date: _selectedDate,
        slot: _selectedSlot!,
      ),
    );
  }

  Future<void> _openDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null; // old slot no longer valid for new date
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canBook = _selectedDoctor != null && _selectedSlot != null;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildSearchBar(),
                    const SizedBox(height: 20),
                    _buildSpecialtyFilters(),
                    const SizedBox(height: 24),
                    _buildDateStrip(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Available Doctors',
                        subtitle: '${_filteredDoctors.length} found'),
                    const SizedBox(height: 12),
                    ..._filteredDoctors.map((d) => _DoctorCard(
                          doctor: d,
                          isSelected: _selectedDoctor == d,
                          selectedSlot:
                              _selectedDoctor == d ? _selectedSlot : null,
                          onTap: () => _selectDoctor(d),
                          onSlotSelected: (slot) =>
                              setState(() => _selectedSlot = slot),
                        )),
                    if (_filteredDoctors.isEmpty) _buildEmptyState(),
                  ],
                ),
              ),
            ),
            // Regular widget, NOT Scaffold.bottomSheet — a persistent
            // bottomSheet fights with showModalBottomSheet and was the
            // cause of the crash when tapping Confirm Booking.
            _buildBookingBar(canBook),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, Color(0xFF03A6F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _openDatePicker,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_month_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Book an Appointment',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Find trusted specialists for you and your baby',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search ──────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          style: GoogleFonts.inter(fontSize: 14.5, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: 'Search doctor or clinic...',
            hintStyle:
                GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.primaryBlue),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          ),
        ),
      ),
    );
  }

  // ── Specialty filter chips ─────────────────────────────
  Widget _buildSpecialtyFilters() {
    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _SpecialtyChip(
            label: 'All',
            icon: Icons.grid_view_rounded,
            isSelected: _selectedSpecialty == null,
            onTap: () => setState(() => _selectedSpecialty = null),
          ),
          const SizedBox(width: 10),
          ...Specialty.values.map((s) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _SpecialtyChip(
                  label: s.label,
                  icon: s.icon,
                  isSelected: _selectedSpecialty == s,
                  onTap: () => setState(() => _selectedSpecialty = s),
                ),
              )),
        ],
      ),
    );
  }

  // ── Date strip ──────────────────────────────────────────
  Widget _buildDateStrip() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Select Date'),
        const SizedBox(height: 12),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _next7Days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final date = _next7Days[i];
              final isSelected = date.day == _selectedDate.day &&
                  date.month == _selectedDate.month;
              const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  width: 58,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [
                              AppColors.primaryBlue,
                              Color(0xFF03A6F0)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? AppColors.primaryBlue.withOpacity(0.3)
                            : Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekdays[date.weekday - 1],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white.withOpacity(0.85)
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${date.day}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryBlue,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded,
              size: 46, color: AppColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            'No doctors found',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom booking bar ──────────────────────────────────
  Widget _buildBookingBar(bool canBook) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (canBook)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedDoctor!.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_selectedSlot} · ${_selectedDate.day}/${_selectedDate.month}',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: Text(
                  'Select a doctor & time slot',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: canBook ? _confirmBooking : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                decoration: BoxDecoration(
                  gradient: canBook
                      ? const LinearGradient(colors: [
                          AppColors.primaryBlue,
                          Color(0xFF03A6F0),
                        ])
                      : null,
                  color: canBook ? null : const Color(0xFFE3E9F1),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: canBook
                      ? [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  'Confirm Booking',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: canBook ? Colors.white : AppColors.textMuted,
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

// ─────────────────────────────────────────────────────────────
// SPECIALTY CHIP
// ─────────────────────────────────────────────────────────────

class _SpecialtyChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpecialtyChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.primaryBlue, Color(0xFF03A6F0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primaryBlue.withOpacity(0.28)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 22,
                color: isSelected ? Colors.white : AppColors.primaryBlue),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.15,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DOCTOR CARD
// ─────────────────────────────────────────────────────────────

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final bool isSelected;
  final String? selectedSlot;
  final VoidCallback onTap;
  final ValueChanged<String> onSlotSelected;

  const _DoctorCard({
    required this.doctor,
    required this.isSelected,
    required this.selectedSlot,
    required this.onTap,
    required this.onSlotSelected,
  });

  Color get _avatarColor {
    switch (doctor.specialty) {
      case Specialty.obGyn:
        return AppColors.primaryBlue;
      case Specialty.mfm:
        return AppColors.pink;
      case Specialty.familyMed:
        return AppColors.coral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : Colors.transparent,
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primaryBlue.withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _avatarColor.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          doctor.avatarSeed,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _avatarColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              doctor.qualification,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: _avatarColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                doctor.specialty.label,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: _avatarColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 15, color: Color(0xFFFFB800)),
                              const SizedBox(width: 2),
                              Text(
                                '${doctor.rating}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${doctor.reviews} reviews',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 14, color: AppColors.textMuted.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${doctor.hospital} · ${doctor.experienceYears} yrs exp',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                    child: isSelected
                        ? Column(
                            children: [
                              const SizedBox(height: 14),
                              Divider(
                                  color: AppColors.bgSoft, height: 1),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Available slots today',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: doctor.availableSlots.map((slot) {
                                  final selected = selectedSlot == slot;
                                  return GestureDetector(
                                    onTap: () => onSlotSelected(slot),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 9),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppColors.primaryBlue
                                            : AppColors.softBlue,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        slot,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? Colors.white
                                              : AppColors.deepBlue,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CONFIRMATION SHEET
// ─────────────────────────────────────────────────────────────

class _BookingConfirmationSheet extends StatelessWidget {
  final Doctor doctor;
  final DateTime date;
  final String slot;

  const _BookingConfirmationSheet({
    required this.doctor,
    required this.date,
    required this.slot,
  });

  @override
  Widget build(BuildContext context) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 34),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.bgSoft,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.primaryBlue, size: 38),
          ),
          const SizedBox(height: 18),
          Text(
            'Appointment Booked!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A confirmation has been sent to your inbox',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _infoRow(Icons.person_rounded, doctor.name),
                const SizedBox(height: 10),
                _infoRow(Icons.medical_services_rounded,
                    doctor.specialty.fullLabel),
                const SizedBox(height: 10),
                _infoRow(Icons.calendar_today_rounded,
                    '${date.day} ${months[date.month - 1]} ${date.year} · $slot'),
                const SizedBox(height: 10),
                _infoRow(Icons.location_on_rounded, doctor.hospital),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    AppColors.primaryBlue,
                    Color(0xFF03A6F0),
                  ]),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Done',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.primaryBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}