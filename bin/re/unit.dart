part of 'rainbowsend.dart';

class Unittype {
  String name;
  int buildcost, upkeepcost, movement, attack, defense, range;

  Unittype(this.name, this.buildcost, this.upkeepcost, this.movement, this.attack, this.defense, this.range);
}

class Unit extends Entity {
  static const int City = 0;
  static const int Settlers = 1;
  static const int Infantry = 2;
  static const int Tanks = 3;
  static const int Artillery = 4;
  static const int Ruins = 5;
  static const int Mechs = 6;
  static const int Scouts = 7;

  int type;
  Player player;
  int _hex;
  int movement, special;
  bool removed;

  Unit(super.id, super.name, this.type, this.player, int hex)
      : _hex = hex,
        movement = 0,
        special = 0,
        removed = false;

  bool isCity() => (type == City);
  bool isRuin() => (type == Ruins);

  Hex hex() {
    return $hexes[_hex];
  }

  String pid() {
    return '[${player.id}-$id]';
  }

  String namepid() {
    return '${this.name} ${pid()}';
  }

  String namepidtype() {
    return '${namepid()} (${Unittypes[type].name})';
  }

  int get attack => Unittypes[type].attack;
  int get defense => Unittypes[type].defense;
}

final Array<Unittype> Unittypes = Array.from([
  Unittype('city', 20, (-10), 0, 0, 0, 0),
  Unittype('settlers', 10, 1, 3, 0, 2, 0),
  Unittype('infantry', 10, 1, 3, 4, 4, 0),
  Unittype('tanks', 20, 2, 6, 8, 6, 0),
  Unittype('artillery', 20, 2, 3, 2, 4, 2),
  Unittype('ruins', 0, 0, 0, 0, 0, 0),
  Unittype('mechs', 0, 3, 6, 6, 6, 2),
  Unittype('scouts', 5, 1, 6, 0, 1, 0)
]);

final Array<Unit> $units = Array();

void deletecities() {
  $units.each((u) {
    u.player.units.clear();
    u.hex().units.clear();
  });
  $units.clear();
}

bool initcities() {
  $players.each((p) {
    final c = Unit(1, 'City', Unit.City, p, (-1));
    do {
      c._hex = (rand($hexes.length));
    } while (c.hex().isWater());
    addunit(c);
  });

  var more = true;
  while (more) {
    more = false;
    $units.each((c) {
      final r = nearestcity(c.hex(), c);
      final a = Array<Hex>();
      for (var d = 0; d < 6; d++) {
        final hex = displace(c.hex(), d);
        if (((hex == null) || hex.isWater())) {
          continue;
        }
        if ((nearestcity(hex, c) > r)) {
          a.add(hex);
        }
      }
      if (a.isEmpty) {
        return;
      }
      moveunit(c, a[rand(a.length)]);
      more = true;
    });
  }

  return $units.find((c) => (nearestcity(c.hex(), c) < ($cityseparation + 1))) == null;
}

void initunits() {
  for (var i = 0; i < 10; i++) {
    if (initcities()) {
      return;
    }
    deletecities();
  }
  throw ('Unable to place starting cities');
}

void addunit(Unit u) {
  $units.add(u);
  u.hex().units.add(u);
  final units = u.player.units;
  if ((units.isEmpty || (units.last().id < u.id))) {
    units.add(u);
  } else {
    var i = 0;
    while (((i < units.length) && (units[i].id > u.id))) {
      i += 1;
    }
    units.insert(i, u);
  }
}

int findunittype(String? s) {
  if (s == null) {
    return (-1);
  }
  final ut = Unittypes.detect((ut2) => ut2.name.startsWith(s.toLowerCase()))!;
  return Unittypes.index(ut);
}

Unit? findunit(Player p, int id) {
  return p.units.detect((u) => u.id == id);
}

int nearestcity(Hex h, [Unit? c]) {
  var r = 999999;
  $units.each((c2) {
    if (((c2 != c) && c2.isCity())) {
      r = min(r, distance(h, c2.hex()));
    }
  });
  return r;
}

void moveunit(Unit u, Hex hex) {
  u.hex().units.remove(u);
  u._hex = (hex.h);
  u.hex().units.add(u);
}

void removeunit(Unit u) {
  $units.remove(u);
  u.player.units.remove(u);
  u.player.removedunits.add(u);
  u.hex().units.remove(u);
  u.removed = true;
}
