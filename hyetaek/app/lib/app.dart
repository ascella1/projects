import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/home_dashboard/presentation/views/home_view.dart';
import 'features/onboarding/presentation/views/onboarding_view.dart';
import 'shared/providers/profile_provider.dart';

class HyetaekApp extends ConsumerWidget {
  const HyetaekApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return MaterialApp(
      title: '혜택',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: profile.isOnboarded ? const HomeView() : const OnboardingView(),
    );
  }
}
