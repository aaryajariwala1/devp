import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'data/remote/inventory_repository.dart';
import 'features/dashboard/bloc/dashboard_bloc.dart';
import 'features/dashboard/bloc/dashboard_event.dart';
import 'features/inventory/bloc/inventory_bloc.dart';
import 'app_shell.dart';

class TakaTrackApp extends StatelessWidget {
  final InventoryRepository repository;

  const TakaTrackApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              DashboardBloc(repository: repository)..add(const LoadDashboard()),
        ),
        BlocProvider(
          create: (_) => InventoryBloc(repository: repository),
        ),
      ],
      child: MaterialApp(
        title: 'TakaTrack',
        theme: AppTheme.darkTheme,
        home: MainShell(repository: repository),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
