import 'dart:async';
import 'dart:math';
import '../models/game_expression.dart';

/// Service to manage the face detection game state and logic
class GameService {
  // Game configuration
  final int totalRounds;
  final List<GameExpression> availableExpressions;

  // Game state - changed to track completed rounds instead of current round index
  int completedRounds = 0;
  int elapsedTimeInSeconds = 0;
  int countdownValue = 3;
  bool isGameStarted = false;
  bool isGameFinished = false;
  late GameExpression requiredExpression;

  // Track used expressions to avoid repetition
  final List<GameExpression> usedExpressions = [];

  // Timers
  Timer? gameTimer;
  Timer? countdownTimer;

  // Random generator for expressions
  final Random _random = Random();

  // Callbacks
  Function()? onGameCompleted;

  GameService({
    this.totalRounds = 1,
    this.availableExpressions = const [
      // GameExpression.senyum,
      GameExpression.netral,
      // GameExpression.marah,
      // GameExpression.sedih,
      // GameExpression.kaget,
      // GameExpression.ngantuk,
    ],
    this.onGameCompleted,
  }) {
    setRandomRequiredExpression();
  }

  /// Set a random expression as the required one
  void setRandomRequiredExpression() {
    // Get available expressions that haven't been used yet
    final List<GameExpression> availableUnusedExpressions =
        availableExpressions
            .where((expr) => !usedExpressions.contains(expr))
            .toList();

    // If no unused expressions left, reset (shouldn't happen in normal game flow)
    if (availableUnusedExpressions.isEmpty) {
      usedExpressions.clear();
      availableUnusedExpressions.addAll(availableExpressions);
    }

    requiredExpression =
        availableUnusedExpressions[_random.nextInt(
          availableUnusedExpressions.length,
        )];
    usedExpressions.add(requiredExpression);
  }

  /// Start the countdown before game begins
  void startCountdown(
    Function(int) onCountdownTick,
    Function onCountdownComplete,
  ) {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdownValue > 0) {
        onCountdownTick(countdownValue);
        countdownValue--;
      } else {
        countdownTimer?.cancel();
        isGameStarted = true;
        onCountdownComplete();
        startGameTimer();
      }
    });
  }

  /// Start the game timer to track elapsed time
  void startGameTimer([Function()? onTick]) {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isGameFinished) {
        elapsedTimeInSeconds++;
        if (onTick != null) onTick();
      }
    });
  }

  /// Clear all detection values and state for clean round transition
  void clearRoundState() {
    // Reset any detection counters or accumulated values here
    // This ensures clean state for the next round
  }

  /// Move to the next expression or finish the game
  bool nextExpression([Function()? onRoundTransition]) {
    completedRounds++;

    print('[GameService] Completed rounds: $completedRounds / $totalRounds');

    // Clear state before transitioning to next round
    clearRoundState();

    if (completedRounds >= totalRounds) {
      print('[GameService] Game should finish now!');
      finishGame();
      return true; // Game finished
    }

    // Optional callback for UI to handle round transition
    if (onRoundTransition != null) {
      onRoundTransition();
    }

    setRandomRequiredExpression();
    return false; // Game continues
  }

  /// Mark the game as finished and clean up
  void finishGame() {
    print('[GameService] finishGame() called - setting isGameFinished = true');
    isGameFinished = true;
    gameTimer?.cancel();
    countdownTimer?.cancel();

    // Trigger completion callback for popup
    if (onGameCompleted != null) {
      print('[GameService] Calling onGameCompleted callback');
      onGameCompleted!();
    } else {
      print('[GameService] Warning: onGameCompleted callback is null');
    }
  }

  /// Get game completion stats for sharing
  Map<String, dynamic> getGameStats() {
    return {
      'totalRounds': totalRounds,
      'completedRounds': completedRounds,
      'totalTime': elapsedTimeInSeconds,
      'averageTimePerRound':
          completedRounds > 0
              ? (elapsedTimeInSeconds / completedRounds).toStringAsFixed(1)
              : '0',
    };
  }

  /// Check if user is ready to share (must be smiling)
  bool canShare(bool isSmiling) {
    return isGameFinished && isSmiling;
  }

  /// Reset the game state for a new game
  void resetGame() {
    print('[GameService] Resetting game state completely');

    // Cancel all timers first
    gameTimer?.cancel();
    countdownTimer?.cancel();
    gameTimer = null;
    countdownTimer = null;

    // Reset all game state
    completedRounds = 0;
    elapsedTimeInSeconds = 0;
    countdownValue = 3;
    isGameStarted = false;
    isGameFinished = false;
    usedExpressions.clear();
    clearRoundState(); // Clear any detection state

    // Set new random expression
    setRandomRequiredExpression();

    print('[GameService] Game state reset complete');
  }

  /// Dispose timers and resources
  void dispose() {
    print('[GameService] Disposing all timers and resources');
    gameTimer?.cancel();
    countdownTimer?.cancel();
    gameTimer = null;
    countdownTimer = null;
  }
}
