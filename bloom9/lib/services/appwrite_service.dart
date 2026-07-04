import 'package:appwrite/appwrite.dart';


class AppwriteService {
  static const String endpoint = "https://sgp.cloud.appwrite.io/v1";
  static const String projectId = "6a410d33003d880c3006";

  static const String databaseId = "6a410fff001e52dbe195";
  static const String userTableId = "users";
  static const String healthTableId = "health_profile";
  static const String  reminderTableId = "reminders";
  static const String symtom_logs = 'symtom_logs';
  static const String daily_health_logs = 'daily_heallth_logs';

  static final Client client = Client()
    ..setEndpoint(endpoint)
    ..setProject(projectId);

  static final Account account = Account(client);

  static final TablesDB tablesDB = TablesDB(client);
}