class DateTimeFormat {
  static DateTime parseToDateTime(String iso8601String) {
    try {
      return DateTime.parse(iso8601String);
    } catch (e) {
      throw FormatException("Invalid ISO 8601 date format: $iso8601String");
    }
  }

  static String dateTimeToString(DateTime dateTime) {
    final now = DateTime.now().toUtc();
    final difference = now.difference(dateTime);

    if (difference.inDays >= 3) {
      return "${dateTime.day} thg ${dateTime.month}";
    } else {
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    }
  }
}
