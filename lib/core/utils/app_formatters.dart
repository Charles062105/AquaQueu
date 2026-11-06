abstract final class AppFormatters {
  static String currency(int amount) => '₱$amount';

  static String date(DateTime value) =>
      '${_month(value.month)} ${value.day}, ${value.year}';

  static String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}
