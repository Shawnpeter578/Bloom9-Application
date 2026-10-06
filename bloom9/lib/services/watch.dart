import 'package:health/health.dart';

class WatchService {
  final Health health = Health();

  Future<int?> getHeartRate() async {
    try {
      const types = [
        HealthDataType.HEART_RATE,
      ];

      const permissions = [
        HealthDataAccess.READ,
      ];

      print('==============================');
      print('Bloom9: Requesting heart rate');
      print('==============================');

      await health.configure();

      final authorized = await health.requestAuthorization(
        types,
        permissions: permissions,
      );

      print('Health authorization: $authorized');

      if (!authorized) {
        print('❌ Heart-rate permission denied');
        return null;
      }

      final now = DateTime.now();
      final startTime = now.subtract(
        const Duration(hours: 24),
      );

      final data = await health.getHealthDataFromTypes(
        startTime: startTime,
        endTime: now,
        types: types,
      );

      print('Heart-rate records found: ${data.length}');

      if (data.isEmpty) {
        print('❌ No heart-rate data found');
        return null;
      }

      // Remove duplicate records
      final cleanData = health.removeDuplicates(data);

      // Sort newest last
      cleanData.sort(
        (a, b) => a.dateTo.compareTo(b.dateTo),
      );

      final latest = cleanData.last;

      print('Latest heart-rate timestamp: ${latest.dateTo}');

      if (latest.value is NumericHealthValue) {
        final value =
            (latest.value as NumericHealthValue).numericValue;

        final bpm = value.round();

        print('❤️ BLOOM9 HEART RATE: $bpm BPM');

        return bpm;
      }

      print('❌ Heart-rate value was not numeric');

      return null;
    } catch (e, stackTrace) {
      print('❌ Heart-rate error: $e');
      print(stackTrace);

      return null;
    }
  }
}