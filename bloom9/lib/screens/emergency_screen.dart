import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────
// Theme
// ─────────────────────────────────────────────────────────────
class _C {
  static const primary = Color(0xFF4BA3E3); // light blue
  static const primaryDark = Color(0xFF2B7BBF);
  static const tint = Color(0xFFEAF5FD); // pale blue surface
  static const bg = Color(0xFFF7FBFF);
  static const text = Color(0xFF1F3A52);
  static const muted = Color(0xFF6B8399);
  static const sos = Color(0xFFE5484D); // the only non-blue accent, on purpose
  static const ok = Color(0xFF2E9E6B);
}

const String kEmergencyNumber = '112'; // India unified emergency number

// ─────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────
class EmergencyContact {
  EmergencyContact({
    required this.name,
    required this.relation,
    required this.phone,
  });
  final String name;
  final String relation;
  final String phone;
}

enum ShareStatus { idle, locating, sending, handedOff, delivered, failed }

extension on ShareStatus {
  String get label => switch (this) {
        ShareStatus.idle => 'Not sent',
        ShareStatus.locating => 'Getting location…',
        ShareStatus.sending => 'Sending…',
        ShareStatus.handedOff => 'Opened in Messages – tap Send there',
        ShareStatus.delivered => 'Delivered',
        ShareStatus.failed => 'Failed – tap to retry',
      };

  Color get color => switch (this) {
        ShareStatus.idle => _C.muted,
        ShareStatus.locating || ShareStatus.sending => _C.primaryDark,
        ShareStatus.handedOff => _C.primaryDark,
        ShareStatus.delivered => _C.ok,
        ShareStatus.failed => _C.sos,
      };

  IconData get icon => switch (this) {
        ShareStatus.idle => Icons.circle_outlined,
        ShareStatus.locating => Icons.my_location,
        ShareStatus.sending => Icons.schedule_send_outlined,
        ShareStatus.handedOff => Icons.outbox_outlined,
        ShareStatus.delivered => Icons.check_circle,
        ShareStatus.failed => Icons.error_outline,
      };
}

// ─────────────────────────────────────────────────────────────
// Sender abstraction
// The default opens the SMS app (no real delivery receipt possible).
// For true "Delivered" status, implement this against a backend
// (e.g. Twilio / an Appwrite Function) and return ShareStatus.delivered.
// ─────────────────────────────────────────────────────────────
abstract class LocationSender {
  Future<ShareStatus> send(List<EmergencyContact> to, String message);
}

class SmsComposerSender implements LocationSender {
  @override
  Future<ShareStatus> send(List<EmergencyContact> to, String message) async {
    final numbers = to.map((c) => c.phone).join(',');
    final uri = Uri.parse('sms:$numbers?body=${Uri.encodeComponent(message)}');
    try {
      final ok = await launchUrl(uri);
      return ok ? ShareStatus.handedOff : ShareStatus.failed;
    } catch (_) {
      return ShareStatus.failed;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────
class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key, this.sender});

  /// Optional: inject a backend-based sender for real delivery receipts.
  final LocationSender? sender;

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  late final LocationSender _sender = widget.sender ?? SmsComposerSender();

  // TODO: persist these (Appwrite / shared_preferences).
  final List<EmergencyContact> _contacts = [];
  final Map<EmergencyContact, ShareStatus> _status = {};
  bool _sharing = false;
  String? _lastLink;

  // ── Calling ────────────────────────────────────────────────
  Future<void> _call(String number) async {
    final ok = await FlutterPhoneDirectCaller.callNumber(number);
    if (ok != true) {
      // Fallback (always the case on iOS): opens the dialer with number filled.
      await launchUrl(Uri(scheme: 'tel', path: number));
    }
  }

  // ── Location ───────────────────────────────────────────────
  Future<Position?> _getPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _toast('Turn on location services to share your location.');
      return null;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      _toast('Location permission is needed to share your location.');
      return null;
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return Geolocator.getLastKnownPosition(); // fall back to cached fix
    }
  }

  Future<void> _shareLocation({List<EmergencyContact>? only}) async {
    final targets = only ?? _contacts;
    if (targets.isEmpty) {
      _toast('Add an emergency contact first.');
      return;
    }
    setState(() {
      _sharing = true;
      for (final c in targets) {
        _status[c] = ShareStatus.locating;
      }
    });

    final pos = await _getPosition();
    if (pos == null) {
      setState(() {
        _sharing = false;
        for (final c in targets) {
          _status[c] = ShareStatus.failed;
        }
      });
      return;
    }

    final link = 'https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
    final message = 'I need help. This is my current location:\n$link';
    setState(() {
      _lastLink = link;
      for (final c in targets) {
        _status[c] = ShareStatus.sending;
      }
    });

    final result = await _sender.send(targets, message);
    if (!mounted) return;
    setState(() {
      _sharing = false;
      for (final c in targets) {
        _status[c] = result;
      }
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Add contact ────────────────────────────────────────────
  Future<void> _addContact() async {
    final name = TextEditingController();
    final relation = TextEditingController();
    final phone = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final added = await showModalBottomSheet<EmergencyContact>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add emergency contact',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _C.text)),
              const SizedBox(height: 16),
              _field(name, 'Name', validator: _required),
              const SizedBox(height: 12),
              _field(relation, 'Relation (e.g. Husband, Mother)'),
              const SizedBox(height: 12),
              _field(phone, 'Phone number',
                  keyboard: TextInputType.phone,
                  validator: (v) =>
                      _normalize(v ?? '').length < 10 ? 'Enter a valid number' : null),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _C.primary),
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(
                      ctx,
                      EmergencyContact(
                        name: name.text.trim(),
                        relation: relation.text.trim(),
                        phone: _normalize(phone.text),
                      ),
                    );
                  },
                  child: const Text('Save contact'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (added != null) {
      setState(() {
        _contacts.add(added);
        _status[added] = ShareStatus.idle;
      });
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  /// Keeps digits and a leading +; assumes India (+91) for bare 10-digit numbers.
  String _normalize(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (RegExp(r'^\d{10}$').hasMatch(cleaned)) return '+91$cleaned';
    return cleaned;
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? keyboard, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _C.tint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const Text('Emergency',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _C.text)),
            const SizedBox(height: 4),
            const Text('Help is one tap away.',
                style: TextStyle(fontSize: 15, color: _C.muted)),
            const SizedBox(height: 28),
            _sosButton(),
            const SizedBox(height: 28),
            _shareCard(),
            const SizedBox(height: 28),
            _contactsSection(),
          ],
        ),
      ),
    );
  }

  Widget _sosButton() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _C.sos.withOpacity(0.10),
            ),
            child: Material(
              color: _C.sos,
              shape: const CircleBorder(),
              elevation: 6,
              shadowColor: _C.sos.withOpacity(0.5),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _call(kEmergencyNumber), // no confirmation
                child: const SizedBox(
                  width: 190,
                  height: 190,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_in_talk_rounded,
                          color: Colors.white, size: 44),
                      SizedBox(height: 6),
                      Text('SOS',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2)),
                      Text('Call $kEmergencyNumber',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Tap once to call emergency services',
              style: TextStyle(color: _C.muted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _shareCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.tint, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                    color: _C.tint, shape: BoxShape.circle),
                child: const Icon(Icons.location_on_rounded,
                    color: _C.primaryDark),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Share my location',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _C.text)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Sends a map link with your current position to all emergency contacts.',
            style: TextStyle(color: _C.muted, fontSize: 13.5),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _C.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _sharing ? null : () => _shareLocation(),
              icon: _sharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(_sharing ? 'Working…' : 'Share with all contacts'),
            ),
          ),
          if (_lastLink != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => launchUrl(Uri.parse(_lastLink!),
                  mode: LaunchMode.externalApplication),
              child: Text('Open shared map link',
                  style: TextStyle(
                      color: _C.primaryDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      decoration: TextDecoration.underline)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _contactsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Emergency contacts',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _C.text)),
            ),
            TextButton.icon(
              onPressed: _addContact,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add'),
              style: TextButton.styleFrom(foregroundColor: _C.primaryDark),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_contacts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _C.tint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'No contacts yet. Add a family member or caregiver so you can call or share your location in one tap.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _C.muted, height: 1.4),
            ),
          )
        else
          ..._contacts.map(_contactTile),
      ],
    );
  }

  Widget _contactTile(EmergencyContact c) {
    final s = _status[c] ?? ShareStatus.idle;
    final initial = c.name.isNotEmpty ? c.name[0].toUpperCase() : '?';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.tint, width: 1.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _C.tint,
            child: Text(initial,
                style: const TextStyle(
                    color: _C.primaryDark, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _C.text)),
                if (c.relation.isNotEmpty)
                  Text(c.relation,
                      style: const TextStyle(color: _C.muted, fontSize: 13)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: s == ShareStatus.failed
                      ? () => _shareLocation(only: [c])
                      : null,
                  child: Row(
                    children: [
                      Icon(s.icon, size: 14, color: s.color),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(s.label,
                            style: TextStyle(
                                color: s.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: _C.primary),
            tooltip: 'Call ${c.name}',
            onPressed: () => _call(c.phone), // one tap
            icon: const Icon(Icons.call_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}