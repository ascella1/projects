import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/services/storage_service.dart';
import 'state/app_state.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final storage = StorageService();
  final appState = AppState(storage);

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const QuestDayApp(),
    ),
  );

  await appState.initialize();
}
