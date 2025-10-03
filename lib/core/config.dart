// ROUNDS
const int kRounds = 4; // scegli tu (1..16)
const int kMaxRounds = 16; // limite hard
const int kMaxSameTerrain = 4; // ogni terreno può uscire al massimo 4 volte

// TEMPI
const int kRoundSeconds = 60;
const int kRevealSeconds = 60;
const bool kEnableBetweenRoundsPause = true;
const int kBetweenRoundsPauseSeconds = 15;

// MANA
const int kBaseManaPerTurn = 5;
const int kMaxManaCap = 20;

// MANO
const int kHandSize = 5; // mano fissa a 5

// DIMENSIONI CARTE
const double kCardWidth = 150.0; // larghezza fissa delle carte in mano
const double kCardHeight = 210.0; // altezza fissa delle carte in mano

// DIMENSIONI CARTE SUL CAMPO
const double kFieldCardWidth = 120.0; // larghezza carte sul campo
const double kFieldCardHeight = 167.0;  // altezza carte sul campo

// (costi sprint/block fissi NON servono più: i costi ora sono per-carta)