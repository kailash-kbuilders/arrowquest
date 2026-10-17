/// A coloured emitter that travels on the rail. It clears tiles of its own
/// colour and has a limited amount of ammo.
class Emitter {
  Emitter({required this.color, required this.ammo});

  /// Single-letter colour key, e.g. 'R'. See AppColors.tile.
  final String color;

  /// Remaining shots. Reaches 0 when the emitter is fully spent.
  int ammo;

  factory Emitter.fromJson(Map<String, dynamic> json) {
    return Emitter(
      color: json['color'] as String,
      ammo: (json['ammo'] as num).toInt(),
    );
  }

  Emitter copy() => Emitter(color: color, ammo: ammo);

  @override
  String toString() => 'Emitter($color, $ammo)';
}
