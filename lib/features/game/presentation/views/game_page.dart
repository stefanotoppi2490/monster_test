import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monster/core/config.dart';
import 'package:monster/core/models/models.dart';
import 'package:monster/features/game/presentation/cubit/game_cubit.dart';
import 'package:monster/features/game/presentation/cubit/game_state.dart';
import 'package:monster/features/game/presentation/widgets/card_chip.dart';
import 'package:monster/features/game/presentation/widgets/flip_card_face.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final GameCubit cubit;

  // Slot campo miei (destinazioni del volo)
  final GlobalKey _mySprintSlotKey = GlobalKey(debugLabel: 'mySprintSlot');
  final GlobalKey _myBlockSlotKey = GlobalKey(debugLabel: 'myBlockSlot');

  final Set<String> _flyingIds = {};
  bool _isFlying(String id) => _flyingIds.contains(id);
  void _startFlight(String id) => setState(() => _flyingIds.add(id));
  void _endFlight(String id) => setState(() => _flyingIds.remove(id));

  // ref alle card della mano (sorgenti del volo)
  final Map<String, GlobalKey> _handItemKeys = {};

  final GlobalKey _handListKey = GlobalKey(debugLabel: 'handList');

  // helper: calcola un Rect al centro della lista mano con dimensioni dal config
  Rect? _centerRectOfHand() {
    final box = _handListKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;
    final w = kCardWidth, h = kCardHeight;
    final left = pos.dx + (size.width - w) / 2;
    final top = pos.dy + (size.height - h) / 2;
    return Rect.fromLTWH(left, top, w, h);
  }

  @override
  void didChangeDependencies() {
    // Recupero il cubit dal BlocProvider.value della route
    cubit = context.read<GameCubit>();
    super.didChangeDependencies();
  }

  Future<void> _flyCardToSlot({
    required String cardId,
    GlobalKey? sourceKey,
    GlobalKey? destKey,
    Rect? endOverride, // <— nuovo
    required Widget flyingChild,
    Duration duration = const Duration(milliseconds: 420),
    Curve curve = Curves.easeOutCubic,
  }) async {
    final overlay = Overlay.of(context);

    final srcBox = sourceKey?.currentContext?.findRenderObject() as RenderBox?;
    final dstBox = destKey?.currentContext?.findRenderObject() as RenderBox?;
    if (srcBox == null) return;

    final srcPos = srcBox.localToGlobal(Offset.zero);
    final startRect = srcPos & srcBox.size;

    late final Rect endRect;
    if (endOverride != null) {
      endRect = endOverride;
    } else {
      if (dstBox == null) return;
      final dstPos = dstBox.localToGlobal(Offset.zero);
      endRect = dstPos & dstBox.size;
    }

    final entry = OverlayEntry(
      builder: (ctx) => _FlyingCard(
        start: startRect,
        end: endRect,
        duration: duration,
        curve: curve,
        child: flyingChild,
      ),
    );

    _startFlight(cardId);
    overlay.insert(entry);
    try {
      await Future.delayed(duration);
    } finally {
      entry.remove();
      _endFlight(cardId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      bloc: cubit,
      builder: (context, state) {
        final terrain = state.currentTerrain;
        return Scaffold(
          backgroundColor: const Color(0xFF0E1020),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _TopOpponentBar(state: state),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            Flexible(
                              child: _OpponentField(
                                terrain: terrain,
                                state: state,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Flexible(
                              child: _MyField(
                                terrain: terrain,
                                state: state,
                                cubit: cubit,
                                sprintSlotKey: _mySprintSlotKey,
                                blockSlotKey: _myBlockSlotKey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _BottomHand(state: state, cubit: cubit),
                  ],
                ),

                // --- overlay recap ---
                if (state.phase == Phase.recap || state.phase == Phase.finished)
                  Positioned.fill(
                    child: _RoundRecapOverlay(
                      round: state.roundIndex,
                      seconds: state.secondsLeft,
                      scoreMe: state.me.score,
                      scoreOpp: state.opp.score,
                      isFinal: state.phase == Phase.finished, // 👈 nuovo
                      onNewMatch: () =>
                          context.read<GameCubit>().startMatch(), // 👈 nuovo
                      totalRounds:
                          state.terrainOrder.length, // 👈 opzionale per testo
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// …tutto il resto del tuo file rimane identico (Badge, Field, FaceDownSlot, ecc.)
// Assicurati di avere `import 'dart:math';` in alto per `min(...)`.

class _TopOpponentBar extends StatelessWidget {
  final GameState state;
  const _TopOpponentBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final round = state.roundIndex + 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: [
                Text(
                  'Round $round/${state.terrainOrder.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _Badge(label: 'TERRAIN', value: state.currentTerrain.label),
                _Badge(label: 'TIME', value: '${state.secondsLeft}s'),
                // 🔴 RIMOSSO _Badge SCORE
                _Badge(label: 'MANA', value: state.me.mana.toString()),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final String value;
  const _Badge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpponentField extends StatelessWidget {
  final Terrain terrain;
  final GameState state;
  const _OpponentField({required this.terrain, required this.state});

  // slot vuoto (placeholder)
  Widget _emptySlot(String label) {
    return Container(
      width: kFieldCardWidth,
      height: kFieldCardHeight,
      decoration: BoxDecoration(
        color: Colors.white10.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(color: Colors.white38, fontSize: 11),
        textAlign: TextAlign.center,
      ),
    );
  }

  // badge ±x
  Widget _withDelta(Widget child, int delta) {
    if (delta == 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(right: -6, top: -6, child: _DeltaBadge(delta)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final inDrafting = state.phase == Phase.drafting;
    final inRevealOrAfter =
        state.phase == Phase.reveal ||
        state.phase == Phase.scoring ||
        state.phase == Phase.recap;

    // Effetti lato avversario
    final eff = state.effects;
    final oppSprintDestroyed = eff.destroyOppSprint;
    final oppBlockDestroyed = eff.destroyOppBlock;
    final oppSprintDelta = eff.oppSprintDelta;
    final oppBlockDelta = eff.oppBlockDelta;

    // Scelte (possono arrivare durante il drafting). Può essere null.
    final opp = state.oppPreview;
    final oppSprint = opp?.sprint;
    final oppBlock = opp?.block;

    // Stato slot indipendente per Sprint/Block
    final sprintChosen = oppSprint != null && !oppSprintDestroyed;
    final blockChosen = oppBlock != null && !oppBlockDestroyed;

    // In reveal/scoring mostriamo la faccia; in drafting mostriamo COPERTA se scelto,
    // altrimenti lo slot resta VUOTO.
    final Widget sprintWidget = () {
      if (inRevealOrAfter && sprintChosen) {
        return _withDelta(
          FlipCardFace(card: oppSprint!, terrain: terrain),
          oppSprintDelta,
        );
      }
      if (inDrafting) {
        return sprintChosen
            ? const _FaceDownSlot(faceUp: false) // coperta
            : _emptySlot('Sprinter'); // vuoto
      }
      // altri casi (es. distrutto o non scelto in reveal)
      return _emptySlot('Sprinter');
    }();

    final Widget blockWidget = () {
      if (inRevealOrAfter && blockChosen) {
        return _withDelta(
          FlipCardFace(card: oppBlock!, terrain: terrain),
          oppBlockDelta,
        );
      }
      if (inDrafting) {
        return blockChosen
            ? const _FaceDownSlot(faceUp: false) // coperta
            : _emptySlot('Blocker'); // vuoto
      }
      return _emptySlot('Blocker');
    }();

    return _FieldArea(
      label: 'Avversario',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: kFieldCardWidth,
                height: kFieldCardHeight,
                child: sprintWidget,
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: kFieldCardWidth,
                height: kFieldCardHeight,
                child: blockWidget,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Punteggio: ${state.opp.score}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MyField extends StatelessWidget {
  final Terrain terrain;
  final GameState state;
  final GameCubit cubit;
  final GlobalKey sprintSlotKey;
  final GlobalKey blockSlotKey;

  const _MyField({
    required this.terrain,
    required this.state,
    required this.cubit,
    required this.sprintSlotKey,
    required this.blockSlotKey,
  });

  @override
  Widget build(BuildContext context) {
    final showReveal = state.phase != Phase.drafting;

    final hasSprintBase = state.myPrivate.choice.sprint != null;
    final hasBlockBase = state.myPrivate.choice.block != null;

    // Effetti/distruzioni lato mio
    final eff = state.effects;
    final bool mySprintDestroyed = eff.destroyMySprint;
    final bool myBlockDestroyed = eff.destroyMyBlock;
    final int sprintDelta = eff.mySprintDelta;
    final int blockDelta = eff.myBlockDelta;

    // Dopo le distruzioni, valutiamo se "c'è" ancora la carta
    final hasSprint = hasSprintBase && !mySprintDestroyed;
    final hasBlock = hasBlockBase && !myBlockDestroyed;

    // Helper per sovrapporre il badge delta
    Widget wrapWithDelta({required Widget child, required int delta}) {
      if (delta == 0) return child;
      final txt = delta > 0 ? '+$delta' : '$delta';
      return Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                txt,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return _FieldArea(
      label: 'Tu',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PlaceSlot(
                key: sprintSlotKey,
                kind: CardKind.sprint,
                state: state,
                cubit: cubit,
                // In drafting mostro il dorso se ho scelto; se distrutta, niente
                showBack: hasSprintBase && !showReveal && !mySprintDestroyed,
                // In reveal/scoring mostro la faccia se non distrutta
                faceUp: showReveal && hasSprint,
                front: hasSprint
                    ? wrapWithDelta(
                        child: FlipCardFace(
                          card: state.myPrivate.choice.sprint!,
                          terrain: terrain,
                        ),
                        delta: sprintDelta,
                      )
                    : null, // distrutta => nulla
                isMine: true,
              ),
              const SizedBox(width: 16),
              _PlaceSlot(
                key: blockSlotKey,
                kind: CardKind.block,
                state: state,
                cubit: cubit,
                showBack: hasBlockBase && !showReveal && !myBlockDestroyed,
                faceUp: showReveal && hasBlock,
                front: hasBlock
                    ? wrapWithDelta(
                        child: FlipCardFace(
                          card: state.myPrivate.choice.block!,
                          terrain: terrain,
                        ),
                        delta: blockDelta,
                      )
                    : null,
                isMine: true,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Punteggio: ${state.me.score}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PlaceSlot extends StatelessWidget {
  final bool
  showBack; // durante drafting se ho scelto una carta (ignorato se isMine=true)
  final bool faceUp; // in reveal/scoring
  final Widget? front;

  // nuovi:
  final CardKind kind;
  final GameState state;
  final GameCubit cubit;
  final bool isMine; // <— se true, mostra scoperta in drafting + tap-to-return

  const _PlaceSlot({
    super.key,
    required this.showBack,
    required this.faceUp,
    this.front,
    required this.kind,
    required this.state,
    required this.cubit,
    this.isMine = false,
  });

  bool _canAccept(GameCard? c) {
    if (c == null) return false;
    if (state.phase != Phase.drafting) return false;
    if (c.kind != kind) return false;
    if (c.manaCost > state.me.mana) return false;
    // slot libero?
    if (kind == CardKind.sprint && state.myPrivate.choice.sprint != null) {
      return false;
    }
    if (kind == CardKind.block && state.myPrivate.choice.block != null) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final inDrafting = state.phase == Phase.drafting;

    return DragTarget<GameCard>(
      onWillAccept: _canAccept,
      onAccept: (card) => cubit.selectCard(card),
      builder: (context, candidates, rejects) {
        final hovering = candidates.isNotEmpty && _canAccept(candidates.first);

        // SLOT VUOTO → solo contorno + glow su hovering
        final slotIsEmpty =
            (!faceUp) && (front == null || (!showBack && !isMine));
        if (slotIsEmpty) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: kFieldCardWidth,
            height: kFieldCardHeight,
            decoration: BoxDecoration(
              color: hovering
                  ? Colors.white10.withOpacity(0.12)
                  : Colors.white10.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),

              boxShadow: hovering
                  ? const [
                      BoxShadow(
                        color: Color(0x806A72E8),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : const [],
            ),
            alignment: Alignment.center,
            child: Text(
              kind == CardKind.sprint ? 'Sprinter' : 'Blocker',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          );
        }

        // --- MIE CARTE: in drafting le voglio SCOPERTE subito e cliccabili per il "ritorno" ---
        if (isMine && inDrafting && front != null) {
          // carta attuale nello slot (serve l'id per attenuazione/animazione)
          final GameCard? current = (kind == CardKind.sprint)
              ? state.myPrivate.choice.sprint
              : state.myPrivate.choice.block;

          return Builder(
            builder: (ctx) {
              final pageState = ctx.findAncestorStateOfType<_GamePageState>();
              return InkWell(
                onTap: () async {
                  if (pageState == null || current == null) {
                    cubit.undoChoice(kind);
                    return;
                  }

                  // start = questo slot (key passato dal padre)
                  final srcKey = key as GlobalKey?;
                  // end = centro della lista mano 120x160
                  final endRect = pageState._centerRectOfHand();
                  if (srcKey == null || endRect == null) {
                    cubit.undoChoice(kind);
                    return;
                  }

                  // animiamo la stessa faccia scoperta in size 110x150 (dimensione slot)
                  final flying = SizedBox(
                    width: kFieldCardWidth,
                    height: kFieldCardHeight,
                    child: front!,
                  );

                  await pageState._flyCardToSlot(
                    cardId: current.id,
                    sourceKey: srcKey,
                    endOverride: endRect, // <— vola verso la mano
                    flyingChild: flying,
                    duration: const Duration(milliseconds: 420),
                  );

                  // rimetti la carta in mano (refund mana ecc. lato cubit)
                  cubit.undoChoice(kind);
                },
                child: SizedBox(
                  width: kFieldCardWidth,
                  height: kFieldCardHeight,
                  child: front,
                ),
              );
            },
          );
        }

        // --- AVVERSARIO (o fase reveal): usa flip/back come prima ---
        return _FaceDownSlot(faceUp: faceUp, front: front);
      },
    );
  }
}

class _FieldArea extends StatelessWidget {
  final double? height;
  final String label;
  final Widget child;
  const _FieldArea({this.height, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF151836), Color(0xFF101223)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          Center(child: child),
        ],
      ),
    );
  }
}

class _FaceDownSlot extends StatefulWidget {
  final bool faceUp;
  final Widget? front; // contenuto carta rivelata
  const _FaceDownSlot({required this.faceUp, this.front});

  @override
  State<_FaceDownSlot> createState() => _FaceDownSlotState();
}

class _FaceDownSlotState extends State<_FaceDownSlot>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      transitionBuilder: (child, anim) {
        final rotate = Tween(begin: 3.1415, end: 0.0).animate(anim);
        return AnimatedBuilder(
          animation: rotate,
          child: child,
          builder: (ctx, w) {
            final isUnder = (ValueKey(widget.faceUp) != child.key);
            final tilt = (anim.value - 0.5).abs() * 0.002;
            final value = isUnder
                ? min(rotate.value, 3.1415 / 2)
                : rotate.value;
            return Transform(
              transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
              alignment: Alignment.center,
              child: w,
            );
          },
        );
      },
      child: widget.faceUp
          ? SizedBox(
              key: const ValueKey(true),
              width: kFieldCardWidth,
              height: kFieldCardHeight,
              child: widget.front ?? const SizedBox(),
            )
          : Container(
              key: const ValueKey(false),
              width: kFieldCardWidth,
              height: kFieldCardHeight,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3943A5), Color(0xFF222856)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              alignment: Alignment.center,
              child: const Text(
                'COPERTA',
                style: TextStyle(color: Colors.white70),
              ),
            ),
    );
  }
}

class _BottomHand extends StatelessWidget {
  final GameState state;
  final GameCubit cubit;
  const _BottomHand({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF12142A),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        children: [
          // Scelte correnti + undo (scrollabile per evitare overflow)
          const SizedBox(height: 8),

          // Mano
          SizedBox(
            height: kCardHeight,
            child: Builder(
              builder: (ctx) {
                final pageState = ctx.findAncestorStateOfType<_GamePageState>();
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: state.myPrivate.hand.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final c = state.myPrivate.hand[i];
                    final disabled =
                        !((state.phase == Phase.drafting &&
                                (c.kind == CardKind.sprint ||
                                    c.kind == CardKind.block) &&
                                c.manaCost <= state.me.mana) ||
                            (state.phase == Phase.reveal &&
                                c.kind == CardKind.trick &&
                                c.manaCost <= state.me.mana));

                    // key stabile per calcolo start
                    final itemKey = pageState?._handItemKeys.putIfAbsent(
                      c.id,
                      () => GlobalKey(debugLabel: 'hand_${c.id}'),
                    );

                    // se sta volando, teniamo il posto attenuato per evitare "salti"
                    final isFlying = (pageState?._isFlying(c.id) ?? false);

                    final cardContent = SizedBox(
                      key: itemKey,
                      width: kCardWidth,
                      height: kCardHeight,
                      child: CardChip(card: c, terrain: state.currentTerrain),
                    );

                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 120),
                      opacity: (disabled || isFlying) ? 0.25 : 1.0,
                      child: IgnorePointer(
                        ignoring: disabled || isFlying,
                        child: InkWell(
                          onTap: () async {
                            if (pageState == null || itemKey == null) return;

                            final isDrafting = state.phase == Phase.drafting;
                            final isReveal = state.phase == Phase.reveal;

                            final hasMana = c.manaCost <= state.me.mana;

                            if (c.kind == CardKind.trick) {
                              // Giocabile solo in reveal
                              if (!isReveal || !hasMana) return;
                              // Lancia immediatamente la trick (nessun drag/animazione necessaria)
                              cubit.playTrick(c);
                              return;
                            }

                            // SPRINT/BLOCK: solo in drafting + slot libero
                            if (!isDrafting) return;
                            final slotFree = (c.kind == CardKind.sprint)
                                ? state.myPrivate.choice.sprint == null
                                : state.myPrivate.choice.block == null;
                            if (!slotFree || !hasMana) return;

                            final destKey = (c.kind == CardKind.sprint)
                                ? pageState._mySprintSlotKey
                                : pageState._myBlockSlotKey;

                            final flying = SizedBox(
                              width: kFieldCardWidth,
                              height: kFieldCardHeight,
                              child: CardChip(
                                card: c,
                                terrain: state.currentTerrain,
                              ),
                            );

                            await pageState._flyCardToSlot(
                              cardId: c.id,
                              sourceKey: itemKey,
                              destKey: destKey,
                              flyingChild: flying,
                            );
                            cubit.selectCard(c);
                          },
                          child: cardContent,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FlyingCard extends StatefulWidget {
  final Rect start;
  final Rect end;
  final Duration duration;
  final Curve curve;
  final Widget child;
  const _FlyingCard({
    required this.start,
    required this.end,
    required this.duration,
    required this.curve,
    required this.child,
  });

  @override
  State<_FlyingCard> createState() => _FlyingCardState();
}

class _FlyingCardState extends State<_FlyingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)..forward();
    _t = CurvedAnimation(parent: _c, curve: widget.curve);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _t,
            builder: (_, __) {
              final l = lerpDouble(
                widget.start.left,
                widget.end.left,
                _t.value,
              )!;
              final t = lerpDouble(widget.start.top, widget.end.top, _t.value)!;
              final w = lerpDouble(
                widget.start.width,
                widget.end.width,
                _t.value,
              )!;
              final h = lerpDouble(
                widget.start.height,
                widget.end.height,
                _t.value,
              )!;

              return Positioned(
                left: l,
                top: t,
                width: w,
                height: h,
                child: Material(
                  type: MaterialType.transparency,
                  child: widget.child,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RoundRecapOverlay extends StatelessWidget {
  final int round;
  final int seconds;
  final int scoreMe;
  final int scoreOpp;

  final bool isFinal; // 👈 nuovo
  final VoidCallback onNewMatch; // 👈 nuovo
  final int? totalRounds; // 👈 opzionale (per mostrare “Round X/N”)

  const _RoundRecapOverlay({
    required this.round,
    required this.seconds,
    required this.scoreMe,
    required this.scoreOpp,
    required this.isFinal,
    required this.onNewMatch,
    this.totalRounds,
  });

  @override
  Widget build(BuildContext context) {
    final title = isFinal
        ? 'Partita conclusa'
        : 'Round ${round + 1}${totalRounds != null ? "/$totalRounds" : ""} concluso';

    String? verdict;
    if (isFinal) {
      if (scoreMe > scoreOpp) {
        verdict = 'Hai VINTO! 🎉';
      } else if (scoreMe < scoreOpp) {
        verdict = 'Hai PERSO 😬';
      } else {
        verdict = 'PAREGGIO 🤝';
      }
    }

    return Container(
      color: Colors.black87.withOpacity(0.85),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF17192F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 18)],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (isFinal && verdict != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    verdict,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  "Punteggio attuale",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  "Tu: $scoreMe   |   Avversario: $scoreOpp",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                // ⏱️ SOLO se NON è finale mostri il countdown
                if (!isFinal) ...[
                  const SizedBox(height: 16),
                  Text(
                    "Prossimo round in $seconds...",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],

                // 🔁 SOLO se è finale mostri il bottone "Nuova partita"
                if (isFinal) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onNewMatch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A72E8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Nuova partita',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  final int delta;
  const _DeltaBadge(this.delta);

  @override
  Widget build(BuildContext context) {
    final txt = delta > 0 ? '+$delta' : '$delta';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        txt,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
