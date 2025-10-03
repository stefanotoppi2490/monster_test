import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monster/features/game/domain/repositories/game_repo.dart';
import 'package:monster/features/game/presentation/cubit/game_cubit.dart';

final gameRepoProvider = Provider<GameRepo>((ref) => GameRepo());

final gameCubitProvider = Provider<GameCubit>((ref) {
  final repo = ref.watch(gameRepoProvider);
  final cubit = GameCubit(repo: repo);
  cubit.startMatch(); // avvio partita al build
  ref.onDispose(cubit.close);
  return cubit;
});
