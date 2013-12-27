part of rainbowsend;

class Terrain {
  static final Array<String> Terraintypes = new Array.from(["water","plain","forest","mountain"]);

  static const int Water = 0;
  static const int Plain = 1;
  static const int Forest = 2;
  static const int Mountain = 3;

  String name;
  int movementcost;

  Terrain(int name,int movementcost) {
    this.name = Terraintypes[name];
    this.movementcost = movementcost;
  }
}

class Hexevent {
  String event;
  Array<Player> players;
  Hexevent(String event) {
    this.event = event;
    this.players = new Array();
  }
}

class Hex {
  int h;
  int terrain;
  Array<Unit> units;
  Array<Hexevent> events;

  Hex(int h) {
    this.h = h;
    this.terrain = Terrain.Water;
    this.units = new Array();
    this.events = new Array();
  }

  bool isWater() {
    return (this.terrain == Terrain.Water);
  }

  int get x => h % $mapsizex;

  int get y => h ~/ $mapsizex;

  String get idstr => "[$x/$y]";

  String get nameid => "${Terrains[terrain].name} ${idstr}";

  void event(String message) {
    var he = new Hexevent("${$slot}: ${message}.");
    $players.each((p) {
      if (p.cansee(this)) {
        he.players.add(p);
      }
    });
    this.events.add(he);
  }
}

final Array<Terrain> Terrains = new Array.from([
  new Terrain(Terrain.Water,0),
  new Terrain(Terrain.Plain,1),
  new Terrain(Terrain.Forest,2),
  new Terrain(Terrain.Mountain,3)
]);

final Array<Hex> $hexes = new Array();

void allochexes() {
  $hexes.clear();
  for (int h = 0; h < $mapsizex * $mapsizey; h++) {
    $hexes.add(new Hex(h));
  }
}

bool offshore(Hex h) {
  if (h.isWater()) {
    for (int d = 0; d < 6; d++) {
      var h2 = displace(h,d);
      if ((h2 != null && (!h2.isWater()))) {
        return true;
      }
    }
  }
  return false;
}

void inithexes() {
  allochexes();
  var count = $hexes.length;
  $hexes[rand(count ~/ 2) + count ~/ 4].terrain = Terrain.Mountain;
  var n = count ~/ 2 - 1;
  for (int i = 0; i < n; i++) {
    var a = $hexes.select(offshore);
    var h = a[rand(a.length)];
    var j;
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
  var terrain = Terrain.Terraintypes.detect((String each) => each.startsWith(s));
  return Terrain.Terraintypes.index(terrain);
}

Hex findhex(String s) {
  var xy = s.split("/");
  var x = int.parse(xy[0]);
  var y = int.parse(xy[1]);
  if (onmap(x,y)) {
    return $hexes[xytoh(x,y)];
  } else {
    return null;
  }
}

bool onmap(int x,int y) {
  return ((((x >= 0) && (x < $mapsizex)) && (y >= 0)) && (y < $mapsizey));
}

int xytoh(int x,int y) {
  return ((y * $mapsizex) + x);
}

int htox(int h) {
  return (h % $mapsizex);
}

int htoy(int h) {
  return (h / $mapsizex).truncate();
}

Hex displace(Hex hex,int d) {
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
  if (onmap(x,y)) {
    return $hexes[xytoh(x,y)];
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

int distance(Hex h1,Hex h2) {
  var a1 = htoa(h1);
  var b1 = htob(h1);
  var a2 = htoa(h2);
  var b2 = htob(h2);
  var da = (a1 - a2);
  var db = (b1 - b2);
  var s = (sign(da) == sign(db));
  da = da.abs();
  db = db.abs();
  if (s) {
    return (da + db);
  } else {
    return max(da,db);
  }
}
