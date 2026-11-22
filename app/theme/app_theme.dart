import 'package:fitness_tracker/app/theme/app_colors.dart';
import 'package:fitness_tracker/app/theme/app_typography.dart';
import 'package:flutter/cupertino.dart';

/// Builds the single [CupertinoThemeData] used by the app.
///
/// Both brightnesses come from the same token set: the dynamic colours in
/// [AppColors] resolve themselves, so the light and dark themes differ only in
/// the [Brightness] they declare.
abstract final class AppTheme {
  static CupertinoThemeData light() => _build(Brightness.light);

  static CupertinoThemeData dark() => _build(Brightness.dark);

  static CupertinoThemeData _build(Brightness brightness) {
    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: AppColors.accentPrimary,
      scaffoldBackgroundColor: AppColors.surfacePage,
      barBackgroundColor: AppColors.surfacePage,
      applyThemeToAll: true,
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.accentPrimary,
        textStyle: AppTypography.body.copyWith(color: AppColors.textPrimary),
        actionTextStyle: AppTypography.body.copyWith(
          color: AppColors.accentPrimary,
        ),
        tabLabelTextStyle: AppTypography.footnote.copyWith(
          fontSize: 10,
          letterSpacing: 0.12,
          height: 12 / 10,
        ),
        navTitleTextStyle: AppTypography.headline.copyWith(
          color: AppColors.textPrimary,
        ),
        navLargeTitleTextStyle: AppTypography.largeTitle.copyWith(
          color: AppColors.textPrimary,
        ),
        navActionTextStyle: AppTypography.body.copyWith(
          color: AppColors.accentPrimary,
        ),
        dateTimePickerTextStyle: AppTypography.title2.copyWith(
          color: AppColors.textPrimary,
        ),
        pickerTextStyle: AppTypography.title2.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
