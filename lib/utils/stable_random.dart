
// stable_random.dart
// A simple, cross-platform consistent pseudo-random number generator (PRNG)
// and stable hashing utility.
// 
// Uses a Linear Congruential Generator (LCG) with parameters from 
// Numerical Recipes: a = 1664525, c = 1013904223, m = 2^32.

class StableRandom {
  int _state;

  StableRandom(int seed) : _state = seed;

  /// Generates the next random integer between 0 (inclusive) and [max] (exclusive).
  int nextInt(int max) {
    if (max <= 0) throw ArgumentError('max must be positive');
    
    // LCG Step: X_{n+1} = (a * X_n + c) % m
    // We use bitwise masking for modulo 2^32 to handle Dart's integer behavior consistent with 32-bit semantics if needed
    // But Dart ints are 64-bit on VM and double on JS (53-bit integer logic safe)
    // 1664525 * 2^32 is ~ 7 * 10^15, which fits in 53 bits (9 * 10^15), so it's safe on JS too.
    
    _state = (_state * 1664525 + 1013904223) & 0xFFFFFFFF;
    return _state.abs() % max;
  }

  /// Shuffles a list in place using the Fisher-Yates algorithm and this stable PRNG.
  void shuffle(List list) {
    for (int i = list.length - 1; i > 0; i--) {
      int n = nextInt(i + 1);
      var temp = list[i];
      list[i] = list[n];
      list[n] = temp;
    }
  }

  /// Generates a stable hash code for a string that is consistent across platforms.
  /// Standard String.hashCode in Dart is implementation-dependent.
  static int getStableHash(String val) {
    int h = 0;
    for (int i = 0; i < val.length; i++) {
        // Use 32-bit integer wrapping for consistency
      h = (31 * h + val.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return h;
  }
}
