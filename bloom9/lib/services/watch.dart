import 'package:health/health.dart';

class WatchService {
  final Health health = Health();

  Future<int?> getHeartRate() async {
    final types = [HealthDataType.HEART_RATE];
    final permissions = [HealthDataAccess.READ];

    print("Requesting Health permission...");

    await health.configure();

final granted = await health.requestAuthorization(
  types,
  permissions: permissions,
);
    print("Permission granted: $granted");

    if (!granted) return null;

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    final data = await health.getHealthDataFromTypes(
      startTime: yesterday,
      endTime: now,
      types: types,
    );

    if (data.isEmpty) return null;

    return (data.last.value as NumericHealthValue)
        .numericValue
        .round();
  }
}