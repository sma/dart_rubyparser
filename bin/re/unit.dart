part of rainbowsend;

class Unittype {
  String name;
  int buildcost,upkeepcost,movement,attack,defense,range;

  Unittype(name,buildcost,upkeepcost,movement,attack,defense,range) {
    this.name = name;
    this.buildcost = buildcost;
    this.upkeepcost = upkeepcost;
    this.movement = movement;
    this.attack = attack;
    this.defense = defense;
    this.range = range;
  }
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
  int movement,special;
  bool removed;

  Unit(int id, String name, int type, Player player, int hex) {
    this.id = id;
    this.name = name;
    this.type = type;
    this.player = player;
    this._hex = hex;
    this.removed = false;
    this.special = 0;
  }

  bool isCity() => (type == City);
  bool isRuin() => (type == Ruins);

  Hex hex() {
    return $hexes[_hex];
  }
  String pid() {
    return "[${player.id}-${id}]";
  }
  String namepid() {
    return "${this.name} ${pid()}";
  }
  String namepidtype() {
    return "${namepid()} (${Unittypes[type].name})";
  }
  int get attack => Unittypes[type].attack;
  int get defense => Unittypes[type].defense;
}

final Array<Unittype> Unittypes = new Array.from([
  new Unittype("city",20,(-10),0,0,0,0),
  new Unittype("settlers",10,1,3,0,2,0),
  new Unittype("infantry",10,1,3,4,4,0),
  new Unittype("tanks",20,2,6,8,6,0),
  new Unittype("artillery",20,2,3,2,4,2),
  new Unittype("ruins",0,0,0,0,0,0),
  new Unittype("mechs",0,3,6,6,6,2),
  new Unittype("scouts",5,1,6,0,1,0)]);

final Array<Unit> $units = new Array();

void deletecities() {
  $units.each((u) {
    u.player.units.clear();
    u.hex().units.clear();
  });
  $units.clear();
}

bool initcities() {
  $players.each((p) {
    var c = new Unit(1,"City",Unit.City,p,(-1));
    do {
      c._hex = (rand($hexes.length));
    } while (c.hex().isWater());
    addunit(c);
  });

  var more = true;
  while (more) {
    more = false;
    $units.each((c) {
      var r = nearestcity(c.hex(),c);
      var a = new Array();
      for (int d = 0; d < 6; d++) {
        var hex = displace(c.hex(),d);
        if (((hex == null) || hex.isWater())) {
          continue;
        }
        if ((nearestcity(hex,c) > r)) {
          a.add(hex);
        }
      }
      if (a.isEmpty) {
        return;
      }
      moveunit(c,a[rand(a.length)]);
      more = true;
    });
  }

  return $units.find((c) => (nearestcity(c.hex(),c) < ($cityseparation + 1))) == null;
}

void initunits() {
  for (int i = 0; i < 10; i++) {
    if (initcities()) {
      return;
    }
    deletecities();
  }
  throw("Unable to place starting cities");
}

void addunit(Unit u) {
  $units.add(u);
  u.hex().units.add(u);
  var units = u.player.units;
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

int findunittype(String s) {
  if (s == null) {
    return (-1);
  }
  var ut = Unittypes.detect((ut2) => ut2.name.startsWith(s.toLowerCase()));
  return Unittypes.index(ut);
}

Unit findunit(Player p,int id) {
  return p.units.detect((u) => u.id == id);
}

int nearestcity(Hex h,[c=null]) {
  var r = 999999;
  $units.each((c2) {
    if (((c2 != c) && c2.isCity())) {
      r = min(r,distance(h,c2.hex()));
    }
  });
  return r;
}

void moveunit(Unit u,Hex hex) {
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
