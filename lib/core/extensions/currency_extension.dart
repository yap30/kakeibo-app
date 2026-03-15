extension CurrencyExtension on double {
  String toRupiah({bool compact = false, bool showSymbol = true}) {
    final prefix = showSymbol ? 'Rp' : '';
    final isNegative = this < 0;
    final absValue = isNegative ? -this : this;

    if (compact) {
      if (absValue >= 1000000000) {
        final v = (absValue / 1000000000).toStringAsFixed(1);
        return '${isNegative ? "-" : ""}$prefix${v}M';
      } else if (absValue >= 1000000) {
        final v = (absValue / 1000000).toStringAsFixed(1);
        return '${isNegative ? "-" : ""}$prefix${v}jt';
      } else if (absValue >= 1000) {
        final v = (absValue / 1000).toStringAsFixed(0);
        return '${isNegative ? "-" : ""}$prefix${v}rb';
      }
      return '${isNegative ? "-" : ""}$prefix${absValue.toStringAsFixed(0)}';
    }

    // Format manual tanpa package intl (web compatible)
    final str = absValue.truncate().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      count++;
    }
    final formatted = buffer.toString().split('').reversed.join('');
    return '${isNegative ? "-" : ""}$prefix$formatted';
  }
}
