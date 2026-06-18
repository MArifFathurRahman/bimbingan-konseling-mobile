bool isStudentRole(dynamic role) {
  if (role == null) return false;
  final r = role.toString().toLowerCase().trim();
  return r.contains('student') ||
      r.contains('siswa') ||
      r.contains('murid') ||
      r.contains('peserta');
}

String normalizeDepartment(dynamic dept) {
  if (dept == null) return '';
  final d = dept.toString().toUpperCase().trim();
  if (d == 'TKJ' || d == 'TJKT' || d.contains('TEKNIK')) return 'TJKT';
  if (d == 'MM' || d == 'DKV') return 'DKV';
  if (d == 'MP' || d == 'MPLB') return 'MPLB';
  if (d == 'AKL') return 'AKL';
  return d;
}
