// router.dart (o dove definisci le route)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monster/features/game/di/providers.dart';
import 'package:monster/features/game/presentation/views/game_page.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) {
        final container = ProviderScope.containerOf(context);
        final cubit = container.read(gameCubitProvider);
        // Se vuoi avviare qui la partita:
        // cubit.startMatch(); // opzionale: io lo chiamo già nel provider

        return MaterialPage(
          child: BlocProvider.value(value: cubit, child: const GamePage()),
        );
      },
    ),
  ],
);
