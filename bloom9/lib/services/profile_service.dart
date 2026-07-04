import 'package:appwrite/appwrite.dart';
import 'package:bloom9/services/appwrite_service.dart';

class HealthService {
  static Future<Map<String, dynamic>> getHealthData() async {
    try {
      // Logged-in Appwrite user
      final user = await AppwriteService.account.get();

      final response = await AppwriteService.tablesDB.listRows(
        databaseId: AppwriteService.databaseId,
        tableId: AppwriteService.healthTableId, // or userTableId
        queries: [
          Query.equal("userId", user.$id),
        ],
      );

      if (response.rows.isEmpty) {
        throw Exception("No health data found.");
      }

      return response.rows.first.data;
    } on AppwriteException catch (e) {
      throw Exception(e.message);
    }
  }
}