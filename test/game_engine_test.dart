import 'package:flutter_test/flutter_test.dart';
import 'package:hue_rush/engine/game_engine.dart';
import 'package:hue_rush/models/emitter.dart';
import 'package:hue_rush/models/level.dart';

Level _level({
  required List<String> tiles,
  required List<Emitter> emitters,
  int switchTokens = 1,
  int bufferSize = 5,
}) {
  return Level(
    id: 1,
    name: 'test',
    chapter: 'Rain',
    rows: tiles.length,
    cols: tiles.first.length,
    tiles: tiles
        .map((row) => row.split('').map<String?>((c) => c == '.' ? null : c).toList())
        .toList(),
    emitters: emitters,
    switchTokens: switchTokens,
    bufferSize: bufferSize,
  );
}

void main() {
  test('clearing every tile wins', () {
    final engine = GameEngine(
      _level(tiles: <String>['RR', 'RR'], emitters: <Emitter>[Emitter(color: 'R', ammo: 4)]),
    );
    for (var i = 0; i < 4; i++) {
      engine.fire();
    }
    expect(engine.tilesLeft, 0);
    expect(engine.won, isTrue);
  });

  test('a blocked emitter is parked and the game can still be won', () {
    final engine = GameEngine(
      _level(
        tiles: <String>['RR'],
        emitters: <Emitter>[
          Emitter(color: 'R', ammo: 1),
          Emitter(color: 'B', ammo: 2),
          Emitter(color: 'R', ammo: 1),
        ],
      ),
    );
    engine.fire(); // clears one red, first emitter spent
    engine.park(); // blue is blocked -> parked
    engine.fire(); // remaining red
    expect(engine.bufferUsed, 1);
    expect(engine.won, isTrue);
  });

  test('switch reverses the rail and spends a token', () {
    final engine = GameEngine(
      _level(
        tiles: <String>['RB'],
        emitters: <Emitter>[Emitter(color: 'R', ammo: 1), Emitter(color: 'B', ammo: 1)],
        switchTokens: 2,
      ),
    );
    expect(engine.front!.color, 'R');
    engine.switchDirection();
    expect(engine.front!.color, 'B');
    expect(engine.switchTokens, 1);
  });

  test('undo restores the previous state', () {
    final engine = GameEngine(
      _level(tiles: <String>['RB'], emitters: <Emitter>[Emitter(color: 'R', ammo: 1)]),
    );
    engine.fire();
    expect(engine.tilesLeft, 1);
    engine.undo();
    expect(engine.tilesLeft, 2);
    expect(engine.moves, 0);
  });

  test('filling the buffer ends the level', () {
    final engine = GameEngine(
      _level(
        tiles: <String>['RR'],
        emitters: <Emitter>[
          Emitter(color: 'R', ammo: 1),
          Emitter(color: 'B', ammo: 1),
          Emitter(color: 'G', ammo: 1),
        ],
        bufferSize: 2,
      ),
    );
    engine.fire(); // clears one red tile
    engine.park(); // blue parked
    engine.park(); // green parked -> buffer full, rail empty
    expect(engine.bufferUsed, 2);
    expect(engine.lost, isTrue);
  });
}
