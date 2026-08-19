import 'package:intl/intl.dart';

final NumberFormat _fcfa = NumberFormat.decimalPattern('fr_FR');

String formatFcfa(num? amount) {
  if (amount == null) return '-';
  return '${_fcfa.format(amount)} FCFA';
}

final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

String formatDateTime(DateTime? date) {
  if (date == null) return '-';
  return _dateTimeFormat.format(date);
}
