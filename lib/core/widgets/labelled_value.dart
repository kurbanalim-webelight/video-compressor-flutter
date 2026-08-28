import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class LabelledValue extends StatelessWidget {
  const LabelledValue({required this.label, required this.value, this.valueStyle, super.key});

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: valueStyle ?? AppTextStyles.bodyStrong),
      ],
    );
  }
}
