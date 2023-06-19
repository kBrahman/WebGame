// ignore_for_file: curly_braces_in_flow_control_structures

extension StringExtension on String {
  String? capitalizeFirstLetters() {
    if (isEmpty) return this;
    final arr = split(' ');
    var res = '';
    for (final s in arr) res += '${s.capitalizeFirst()} ';
    return res.trim();
  }

  String capitalizeFirst() {
    if (isEmpty || this == 'and') return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
