part of rainbowsend;

class Terrain {
  static final Array<String> Terraintypes = Array.from(['water', 'plain', 'forest', 'mountain']);

  static const int Water = 0;
  static const int Plain = 1;
  static const int Forest = 2;
  static const int Mountain = 3;

  String name;
  int movementcost;

  Terrain(int name, this.movementcost) : name = Terraintypes[name];
}

class Hexevent {
  String event;
  Array<Player> players;

  Hexevent(this.event) : players = Array();
}

class Hex {
  int h;
  int terrain;
  Array<Unit> units;
  Array<Hexevent> events;

  Hex(this.h)
      : terrain = Terrain.Water,
        units = Array(),
        events = Array();

  bool isWater() {
    return (terrain == Terrain.Water);
  }

  int get x => h % $mapsizex;

  int get y => h ~/ $mapsizex;

  String get idstr => '[$x/$y]';

  String get nameid => '${Terrains[terrain].name} $idstr';

  void event(String message) {
    final he = Hexevent('${$slot}: $message.');
    $players.each((p) {
      if (p.cansee(this)) {
        he.players.add(p);
      }
    });
    events.add(he);
  }
}

final Array<Terrain> Terrains = Array.from(
    [Terrain(Terrain.Water, 0), Terrain(Terrain.Plain, 1), Terrain(Terrain.Forest, 2), Terrain(Terrain.Mountain, 3)]);

final Array<Hex> $hexes = Array();

void allochexes() {
  $hexes.clear();
  for (var h = 0; h < $mapsizex * $mapsizey; h++) {
    $hexes.add(Hex(h));
  }
}

bool offshore(Hex h) {
  if (h.isWater()) {
    for (var d = 0; d < 6; d++) {
      final h2 = displace(h, d);
      if ((h2 != null && (!h2.isWater()))) {
        return true;
      }
    }
  }
  return false;
}

void inithexes() {
  allochexes();
  final count = $hexes.length;
  $hexes[rand(count ~/ 2) + count ~/ 4].terrain = Terrain.Mountain;
  final n = count ~/ 2 - 1;
  for (var i = 0; i < n; i++) {
    final a = $hexes.select(offshore);
    final h = a[rand(a.length)];
    int j;
    switch (rand(4)) {
      case 0:
        j = Terrain.Mountain;
        break;
      case 1:
        j = Terrain.Forest;
        break;
      default:
        j = Terrain.Plain;
        break;
    }
    h.terrain = j;
  }
}

int findterrain(String s) {
  final terrain = Terrain.Terraintypes.detect((String each) => each.startsWith(s))!;
  return Terrain.Terraintypes.index(terrain);
}

Hex? findhex(String s) {
  final xy = s.split('/');
  final x = int.parse(xy[0]);
  final y = int.parse(xy[1]);
  if (onmap(x, y)) {
    return $hexes[xytoh(x, y)];
  } else {
    return null;
  }
}

bool onmap(int x, int y) {
  return ((((x >= 0) && (x < $mapsizex)) && (y >= 0)) && (y < $mapsizey));
}

int xytoh(int x, int y) {
  return ((y * $mapsizex) + x);
}

int htox(int h) {
  return (h % $mapsizex);
}

int htoy(int h) {
  return (h / $mapsizex).truncate();
}

Hex? displace(Hex hex, int d) {
  var x = hex.x;
  var y = hex.y;
  switch (d) {
    case 0:
      y -= 1;
      break;
    case 1:
      if (even(x)) {
        y -= 1;
      }
      x += 1;
      break;
    case 2:
      if (odd(x)) {
        y += 1;
      }
      x += 1;
      break;
    case 3:
      y += 1;
      break;
    case 4:
      if (odd(x)) {
        y += 1;
      }
      x -= 1;
      break;
    case 5:
      if (even(x)) {
        y -= 1;
      }
      x -= 1;
      break;
  }
  if (onmap(x, y)) {
    return $hexes[xytoh(x, y)];
  } else {
    return null;
  }
}

int htoa(Hex h) {
  return (h.x + 1) ~/ 2 + h.y;
}

int htob(Hex h) {
  return h.x ~/ 2 - h.y;
}

int distance(Hex h1, Hex h2) {
  final a1 = htoa(h1);
  final b1 = htob(h1);
  final a2 = htoa(h2);
  final b2 = htob(h2);
  var da = (a1 - a2);
  var db = (b1 - b2);
  final s = (sign(da) == sign(db));
  da = da.abs();
  db = db.abs();
  if (s) {
    return (da + db);
  } else {
    return max(da, db);
  }
}
