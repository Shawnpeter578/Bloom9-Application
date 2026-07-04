String getTrimester(int week) {
  if (week <= 13) return "First Trimester";
  if (week <= 27) return "Second Trimester";
  return "Third Trimester";
}

String getBabySize(int week) {
  if (week <= 4) return "Poppy Seed";
  if (week <= 8) return "Raspberry";
  if (week <= 12) return "Lime";
  if (week <= 16) return "Avocado";
  if (week <= 20) return "Banana";
  if (week <= 24) return "Corn";
  if (week <= 28) return "Eggplant";
  if (week <= 32) return "Squash";
  if (week <= 36) return "Papaya";
  return "Watermelon";
}

String getBabyDescription(int week) {
  return "Your baby is growing beautifully this week.";
}

int getDaysToGo(int week) {
  return (40 - week) * 7;
}

String getDueDate(int week) {
  final due = DateTime.now().add(Duration(days: getDaysToGo(week)));
  return "${due.day}/${due.month}/${due.year}";
}