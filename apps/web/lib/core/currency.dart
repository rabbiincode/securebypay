String formatNaira(dynamic value) {
  final amount = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
  final absolute = amount.abs().toStringAsFixed(2).split('.');
  final grouped = absolute.first.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  return '${amount < 0 ? '-' : ''}₦$grouped.${absolute.last}';
}
