part of rainbowsend;

String A(List<String> args, int index, String def) {
  return index < args.length ? args[index] : def;
}

bool cityarea(Hex h) {
  return (nearestcity(h) < $cityseparation);
}

void refreshunits() {
  $units.each((u) {
    u.movement = (Unittypes[u.type].movement);
    u.special = (1);
  });
}

bool has(Player p,int id) {
  return p.units.detect((u) => (u.id == id)) != null;
}

void nextid(Unit u) {
  while (has(u.player,u.id)) {
    u.id = ((u.id + 1));
  }
}

Array<String> Abbr = new Array.from(["n","ne","se","s","sw","nw"]);
Array<String> Full = new Array.from(["north","northeast","southeast","south","southwest","northwest"]);

int finddir(String s) {
  var dir = Abbr.index(s.toLowerCase());
  if (dir == -1) {
    dir = Full.index(s.toLowerCase());
  }
  return dir;
}

bool destroys(Unit u,Unit u2,[int attack=-1]) {
  if (attack == -1) attack = u.attack;
  var d = u2.defense;
  if (u2.hex().units.detect((uu) {
    return (uu.isCity() && (uu.player == u2.player));
  }) != null) {
    d += 2;
  }
  return (rand((attack + d)) < attack);
}

void build(Unit u, List<String> args) {
  var p = u.player;
  var type = findunittype(A(args, 0, ""));
  if ((args.length == 0) && (u.type == Unit.Settlers)) {
    var type = Unit.City;
  }
  if ((type < 0)) {
    u.event("Unit type not recognized");
    return;
  }
  switch (u.type) {
    case Unit.City:
      if ((type == Unit.City)) {
        u.event("Cities can only be built by settlers");
        return;
      }
      break;
    case Unit.Settlers:
      if ((type != Unit.City)) {
        u.event("Settlers can only build cities");
        return;
      }
      break;
    default:
      u.event("Only cities and settlers can build");
      return;
  }
  if (((type == Unit.City) && cityarea(u.hex()))) {
    u.event("Too close to an existing city");
    return;
  }
  var a1 = A(args, 1, "1");
  var a2 = A(args, 2, null);
  var id = int.parse(a1);
  if (((id < 1) || (id > 99999))) {
    id = 1;
  }
  if (new RegExp("^[A-Za-z]").hasMatch(a1) && a2 == null) {
    a2 = a1;
  }
  var name = a2 != null ? a2 : Unittypes[type].name;
  var cost = Unittypes[type].buildcost;
  if ((cost == 0)) {
    u.event("You cannot build this unit type");
    return;
  }
  if ((p.money < cost)) {
    u.event("Insufficient funds");
    return;
  }
  p.money = ((p.money - cost));
  var u2 = new Unit(id,name,type,p,u._hex);
  nextid(u2);
  addunit(u2);
  if ((u.type == Unit.Settlers)) {
    removeunit(u);
  }
  u.event("Built ${u2.nameid}");
  u2.event("Built in ${u2.hex().nameid}");
  u2.hex().event("${u2.namepidtype()} built");
}

void drop(Unit u) {
  if ((u.type == Unit.Ruins)) {
    u.event("You cannot drop ruins");
    return;
  }
  removeunit(u);
  u.event("Dropped");
  u.hex().event("${u.namepidtype()} dropped");
}

void email(Player p, List<String> args) {
  var email = args[0];
  if (((email == null) || (email == ""))) {
    p.event("New email address not given");
    return;
  }
  p.email = (email);
  p.event("Email address changed to $email");
}
void explore(Unit u, List<String> args) {
  if ((u.type != Unit.Settlers)) {
    u.event("Only settlers may explore");
    return;
  }
  var r = u.hex().units.detect((u2) {
    return u2.isRuin();
  });
  if ((r == null)) {
    u.event("Nothing found");
    return;
  }
  if (((r.player != u.player) && (!r.player.friendly.contains(u.player)))) {
    u.event("${r.namepidtype()} is not secured and must be captured first");
    return;
  }
  switch (rand(5)) {
    case 0:
      u.event("triggered a deadly explosion");
      r.hex().event("${u.nameid} died in an explosion while exploring ${r.namepidtype()}");
      removeunit(u);
      break;
    default:
      if ((r.special == 0)) {
        u.event("another unit already explored the ${r.name}");
        return;
      }
      r.special = (0);
      var hostile = (rand(6) == 0);
      var u2 = new Unit(1,"Ancient Battlemechs",Unit.Mechs,(hostile ? $players.last() : u.player),u._hex);
      nextid(u2);
      addunit(u2);
      u.event("${u.nameid} discovered a new unit ${u2.namepidtype()}");
      if (hostile) {
        u.event("wait, that unit is out of control!");
      }
      u2.event("Was discovered by ${u.namepidtype()}");
      r.hex().event("${u.namepidtype()} discovered ancient technology in ${r.namepidtype()}");
      break;
  }
}
void fire(Unit u, List<String> args) {
  var range = Unittypes[u.type].range;
  if ((range == 0)) {
    u.event("Not an indirect fire unit");
    return;
  }
  if ((u.special == 0)) {
    u.event("Already fired this turn");
    return;
  }
  var d = finddir(A(args, 0, ""));
  var hex;
  if ((d >= 0)) {
    hex = displace(u.hex(),d);
    if ((hex == null)) {
      u.event("Target hex is off the map");
      return;
    }
  } else {
    hex = findhex(A(args, 0, ""));
    if ((hex == null)) {
      u.event("Target hex not recognized");
      return;
    }
  }
  if ((distance(u.hex(),hex) > range)) {
    u.event("Target hex is out of range");
    return;
  }
  hex.units.each((u2) {
    if (((u2.player == u.player) || u.player.friendly.contains(u2.player))) {
      u.event("Friendly units in target area - fire mission aborted");
      return;
    }
  });
  if (hex.units.isEmpty) {
    u.event("No units in target area - fire mission aborted");
    return;
  }
  u.special = (0);
  u.event("Firing on ${hex.nameid}");
  hex.event("Incoming fire from ${u.namepidtype()} in ${u.hex().nameid}");
  hex.units.dup().each((u2) {
    if ((u2.type == Unit.City)) {
      u.event("${u2.namepidtype()} survived");
      u2.event("Incoming fire from ${u.namepidtype()} in ${u.hex().nameid} - survived");
      hex.event("${u2.namepidtype()} survived");
      return;
    }
    u2.player.friendly.remove(u.player);
    if ((!destroys(u,u2,2))) {
      u.event("${u2.namepidtype()} survived");
      u2.event("Incoming fire from ${u.namepidtype()} in ${u.hex().nameid} - survived");
      hex.event("${u2.namepidtype()} survived");
      return;
    }
    u.event("${u2.namepidtype()} destroyed");
    u2.event("Incoming fire from ${u.namepidtype()} in ${u.hex().nameid} - destroyed");
    hex.event("${u2.namepidtype()} destroyed");
    removeunit(u2);
  });
}
void friendly(Player p, List<String> args) {
  Player p2 = findplayer(int.parse(args[0]));
  if ((p2 == null)) {
    p.event("Player not recognized");
    return;
  }
  if ((!p.friendly.contains(p2))) {
    p.friendly.add(p2);
  }
  p.event("Declared ${p2.nameid} as friendly");
}
void give(Player p, List<String> args) {
  var p2 = findplayer(int.parse(args[1]));
  if (p2 == null) {
    p.event("Player not recognized");
    return;
  }
  var qty = min(max(int.parse(args[1]),1),p.money);
  p.money = ((p.money - qty));
  p2.money = ((p2.money + qty));
  p.event("Gave ${p2.nameid} ${qty} money");
  p2.event("${p.nameid} gave ${qty} money");
}
void group(Unit u, List<String> args) {
}
void hostile(Player p, List<String> args) {
  var p2 = findplayer(int.parse(args[1]));
  if (p2 == null) {
    p.event("Player not recognized");
    return;
  }
  p.friendly.remove(p2);
  p.event("Declared ${p2.nameid} as hostile");
}
void move(Unit u, List<String> args) {
  var d = finddir(A(args, 0, ""));
  var hex;
  if ((d >= 0)) {
    hex = displace(u.hex(),d);
    if ((hex == null)) {
      u.event("Destination is off the map");
      return;
    }
  } else {
    hex = findhex(A(args, 0, ""));
    if ((hex == null)) {
      u.event("Destination not recognized");
      return;
    }
  }
  if ((distance(u.hex(),hex) > 1)) {
    u.event("Destination is not an adjacent hex");
    return;
  }
  if (hex.isWater()) {
    u.event("Destination is a water hex");
    return;
  }
  var cost = Terrains[hex.terrain].movementcost;
  if ((u.movement < cost)) {
    u.event("Not enough movement points left");
    return;
  }
  var from = u.hex();
  u.movement = ((u.movement - cost));
  moveunit(u,hex);
  u.event("Moved from ${from.nameid} to ${hex.nameid}");
  from.event("${u.namepidtype()} moved to ${hex.idstr}");
  hex.event("${u.namepidtype()} arrived from ${from.idstr}");
}
void name(Entity e, List<String> args) {
  var name = args[0];
  if (((name == null) || (name == ""))) {
    e.event("New name not given");
    return;
  }
  e.name = (name);
  e.event("Name changed to $name");
}
void quit(Player p) {
  p.email = null;
}
void ungroup(Unit u, List<String> args) {
}
bool cantarget(Unit u,Unit u2) {
  return (!(((u2.isCity() || u2.isRuin()) || (u.player == u2.player)) || u.player.friendly.contains(u2.player)));
}
Unit findtarget(Unit u) {
  if ((u.attack == 0)) {
    return null;
  }
  var targets = u.hex().units.select((u2) {
    return cantarget(u,u2);
  });
  if (targets.isEmpty) {
    return null;
  }
  return targets[rand(targets.length)];
}
void combathex(Hex h) {
  h.units.shuffle().each((u) {
    if (u.removed) {
      return;
    }
    var u2 = findtarget(u);
    if (u2 == null) {
      return;
    }
    u2.player.friendly.remove(u.player);
    if ((!destroys(u,u2))) {
      u.event("Attacking ${u2.namepidtype()} without effect");
      u2.event("Attacked by ${u.namepidtype()} without effect");
      h.event("${u.namepidtype()} attacks ${u2.namepidtype()} without effect");
    } else {
      u.event("Attacking and destroying ${u2.namepidtype()}");
      u2.event("Destroyed by ${u.namepidtype()}");
      h.event("${u.namepidtype()} attacks and destroys ${u2.namepidtype()}");
      removeunit(u2);
    }
  });
}
void combat() {
  $hexes.each((h) {
    if ((!h.units.isEmpty)) {
      combathex(h);
    }
  });
}
void captureunit(Unit c, Hex h) {
  Array<Unit> a = h.units.shuffle();
  for (Unit u in a) {
    if ((u.attack == 0)) {
      continue;
    }
    if ((u.player == c.player)) {
      continue;
    }
    if (u.player.friendly.contains(c.player)) {
      continue;
    }
    if (h.units.detect((u2) {
      return (cantarget(u,u2) || ((u2.attack > 0) && cantarget(u2,u2)));
    }) != null) {
      continue;
    }
    var c2 = new Unit(1,c.name,c.type,u.player,h.h);
    nextid(c2);
    addunit(c2);
    u.event("Captured ${c.namepid()}");
    c.event("Captured by ${u.namepid()}");
    c2.event("Captured by ${u.namepid()}");
    h.event("${u.namepidtype()} captured ${c.namepid()} - now designated ${c2.pid()}");
    if (c2.isRuin()) {
      c2.event("Send settlers to EXPLORE the ruins");
    }
    removeunit(c);
    break;
  };
}
void capturehex(Hex h) {
  Unit c = h.units.detect((u) {
    return u.isCity();
  });
  if (c != null) {
    captureunit(c,h);
  }
  c = h.units.detect((u) {
    return u.isRuin();
  });
  if (c != null) {
    captureunit(c,h);
  }
}
void capture() {
  $hexes.each((h) {
    if ((!h.units.isEmpty)) {
      capturehex(h);
    }
  });
}
void income() {
  $units.each((u) {
    var income = (-Unittypes[u.type].upkeepcost);
    if ((income > 0)) {
      u.player.money = ((u.player.money + income));
    }
  });
}
void upkeep() {
  $players.each((p) {
    p.units.dup().each((u) {
      var upkeep = Unittypes[u.type].upkeepcost;
      if ((upkeep < 0)) {
        return;
      }
      if ((p.money >= upkeep)) {
        p.money = ((p.money - upkeep));
      } else {
        removeunit(u);
      }
    });
  });
}

