import 'package:app_usage/app_usage.dart';
import 'package:flutter/services.dart';

class WellbeingService {
  Future<List<AppUsageInfo>> getUsageToday() async {
    try {
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      DateTime endOfDay = now;

      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(startOfDay, endOfDay);
      return infoList;
    } catch (exception) {
      print(exception);
      return [];
    }
  }

  Future<Duration> getTotalScreenTimeToday() async {
    try {
      List<AppUsageInfo> usage = await getUsageToday();
      Duration total = Duration.zero;
      for (var info in usage) {
        // Filter system apps if needed, but for now take all
        // Common non-user apps might need filtering based on package name, 
        // but 'on screen' time usually implies user interaction.
        // AppUsage plugin returns "foreground time".
        total += info.usage;
      }
      return total;
    } catch (e) {
      return Duration.zero;
    }
  }
}
