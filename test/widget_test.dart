import 'package:flutter_test/flutter_test.dart';
import 'package:worterabenteuer/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('AppColors defines violet primary color', (tester) async {
    expect(AppColors.violet, const Color(0xFF7C4DFF));
  });

  testWidgets('AppColors defines sky secondary color', (tester) async {
    expect(AppColors.sky, const Color(0xFF29B6F6));
  });
}
