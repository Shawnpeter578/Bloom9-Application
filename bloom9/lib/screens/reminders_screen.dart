import 'package:bloom9/services/notification_service.dart';
import 'package:flutter/material.dart';

class Bloom9Colors {
  static const Color ink = Color(0xFF1F2333);
  static const Color primary = Color(0xFF0191F7); // blue
  static const Color pink = Color(0xFFE28ABE);
  static const Color coral = Color(0xFFFF8A8A);
  static const Color surface = Color(0xFFF7F9FC);
  static const Color border = Color(0xFFE7ECF3);
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _Reminder {
  final String title;
  final String time;
  final String group; // Missed, Today, Upcoming
  bool enabled;

  _Reminder({
    required this.title,
    required this.time,
    required this.group,
    this.enabled = true,
  });
}

class _RemindersScreenState extends State<RemindersScreen> {
  final List<_Reminder> _reminders = [
    _Reminder(title: "Take prenatal vitamins", time: "8:00 AM", group: "Missed"),
    _Reminder(title: "Drink 2 glasses of water", time: "11:00 AM", group: "Today"),
    _Reminder(title: "Evening walk", time: "6:30 PM", group: "Today"),
    _Reminder(title: "Doctor's appointment", time: "Tomorrow, 10:00 AM", group: "Upcoming"),
    _Reminder(title: "Log weekly weight", time: "Fri, 9:00 AM", group: "Upcoming"),
  ];

  Map<String, List<_Reminder>> get _grouped {
    final map = <String, List<_Reminder>>{"Missed": [], "Today": [], "Upcoming": []};
    for (final r in _reminders) {
      map[r.group]?.add(r);
    }
    return map;
  }

  void _deleteReminder(_Reminder r) {
    setState(() => _reminders.remove(r));
  }


  Future<void> _showAddReminderDialog() async {
  final titleController = TextEditingController();

  TimeOfDay? selectedTime;
  String selectedGroup = "Today";

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Bloom9Colors.primary.withOpacity(.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: Bloom9Colors.primary,
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "New Reminder",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Bloom9Colors.ink,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Stay on top of your pregnancy care.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 24),

                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: "Reminder title",
                      prefixIcon: const Icon(Icons.edit_outlined),
                      filled: true,
                      fillColor: Bloom9Colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );

                      if (picked != null) {
                        setDialogState(() {
                          selectedTime = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Bloom9Colors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            color: Bloom9Colors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedTime == null
                                  ? "Select reminder time"
                                  : selectedTime!.format(context),
                              style: TextStyle(
                                color: selectedTime == null
                                    ? Colors.grey
                                    : Bloom9Colors.ink,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  DropdownButtonFormField<String>(
                    value: selectedGroup,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Bloom9Colors.surface,
                      prefixIcon: const Icon(Icons.category_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Today",
                        child: Text("Today"),
                      ),
                      DropdownMenuItem(
                        value: "Upcoming",
                        child: Text("Upcoming"),
                      ),
                      DropdownMenuItem(
                        value: "Missed",
                        child: Text("Missed"),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedGroup = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child:ElevatedButton(
  child: const Text("Save"),
  onPressed: () async {
    if (titleController.text.trim().isEmpty ||
        selectedTime == null) {
      return;
    }

    DateTime now = DateTime.now();

    DateTime scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await NotificationService.scheduleNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: titleController.text.trim(),
      body: "It's time for your reminder!",
      scheduledTime: scheduled,
    );

    setState(() {
      _reminders.add(
        _Reminder(
          title: titleController.text.trim(),
          time: selectedTime!.format(context),
          group: selectedGroup,
        ),
      );
    });

    Navigator.pop(context);
  },
),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: Bloom9Colors.surface,
      appBar: AppBar(
        backgroundColor: Bloom9Colors.surface,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Reminders",
          style: TextStyle(
            color: Bloom9Colors.ink,
            fontWeight: FontWeight.w700,
            fontSize: 26,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReminderDialog,
        backgroundColor: Bloom9Colors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "New Reminder",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _reminders.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                for (final entry in grouped.entries)
                  if (entry.value.isNotEmpty) ...[
                    _buildSectionHeader(entry.key, entry.value.length),
                    const SizedBox(height: 10),
                    for (final r in entry.value) ...[
                      _buildReminderCard(r),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 12),
                  ],
              ],
            ),
    );
  }

  


  Widget _buildSectionHeader(String title, int count) {
    Color dotColor;
    switch (title) {
      case "Missed":
        dotColor = Bloom9Colors.coral;
        break;
      case "Today":
        dotColor = Bloom9Colors.primary;
        break;
      default:
        dotColor = Bloom9Colors.pink;
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Bloom9Colors.ink,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          "($count)",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Bloom9Colors.ink.withOpacity(0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderCard(_Reminder r) {
    final isMissed = r.group == "Missed";

    return Dismissible(
      key: ValueKey(r.title + r.time),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteReminder(r),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: Bloom9Colors.coral.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Bloom9Colors.border),
          boxShadow: [
            BoxShadow(
              color: Bloom9Colors.primary.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isMissed
                    ? Bloom9Colors.coral.withOpacity(0.12)
                    : Bloom9Colors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isMissed ? Icons.notifications_off_outlined : Icons.notifications_active_outlined,
                color: isMissed ? Bloom9Colors.coral : Bloom9Colors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Bloom9Colors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r.time,
                    style: TextStyle(
                      fontSize: 13,
                      color: isMissed ? Bloom9Colors.coral : Bloom9Colors.ink.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoSwitchStandIn(
              value: r.enabled,
              activeColor: Bloom9Colors.pink,
              onChanged: (v) => setState(() => r.enabled = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Bloom9Colors.pink.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded, size: 42, color: Bloom9Colors.pink),
          ),
          const SizedBox(height: 18),
          const Text(
            "No reminders yet",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Bloom9Colors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            "Tap + to add your first reminder",
            style: TextStyle(fontSize: 13, color: Bloom9Colors.ink.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}

// Thin wrapper so this file compiles even if you're not importing Cupertino elsewhere.
// If you already use CupertinoSwitch directly, just swap this for that.
class CupertinoSwitchStandIn extends StatelessWidget {
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const CupertinoSwitchStandIn({
    super.key,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: value,
      activeColor: activeColor,
      onChanged: onChanged,
    );
  }
}



