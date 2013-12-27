part of rainbowsend;

class Order {
  static final Array<String> Ordertypes = new Array.from(["build","drop","email","explore","fire","friendly","give","group","hostile","move","name","null","quit","ungroup","wait"]);

  static const int Build = 0;
  static const int Drop = 1;
  static const int Email = 2;
  static const int Explore = 3;
  static const int Fire = 4;
  static const int Friendly = 5;
  static const int Give = 6;
  static const int Group = 7;
  static const int Hostile = 8;
  static const int Move = 9;
  static const int Name = 10;
  static const int Null = 11;
  static const int Quit = 12;
  static const int Ungroup = 13;
  static const int Wait = 14;

  int type;
  List<String> args;

  Order(int type, Array<String> args) {
    this.type = type;
    this.args = args.toList();
  }
}

const Maxorders = 100;

Array<String> read(File file) {
  while (true) {
    var line = file.gets();
    if (line == null) {
      return null;
    }
    var words = parse(line);
    if (!words.isEmpty) {
      return words;
    }
  }
}

int findtype(String s) {
  if (s == null) {
    return (-1);
  }
  var order = Order.Ordertypes.detect((each) => each.startsWith(s));
  return Order.Ordertypes.index(order);
}

void addorder(Entity e, Array<String> words) {
  var type = findtype(words[0]);
  if (type < 0) {
    e.quote(words.toList());
    e.event("Order not recognized");
    return;
  }
  if (e.orders.length >= Maxorders) {
    e.event("Maximum number of orders reached");
    return;
  }
  e.orders.add(new Order(type, words.sublist(1)));
}

void readorders() {
  var file = File.open("orders","r");
  if (file == null) throw ("Orders file not found");
  try {
    var words = read(file);
    while (words != null) {
      while ((words[0].toLowerCase() != "player")) {
        words = read(file);
        if (words == null) return;
      }
      var p = findplayer(int.parse(words[1]));
      if (p == null) {
        words = read(file);
        continue;
      }
      p.orders.clear();
      p.lastorders = (($turn + 1));
      p.units.each((u) {
        return u.orders.clear();
      });
      while (true) {
        words = read(file);
        if (words == null) return;
        var w = words[0].toLowerCase();
        if ((((w == "unit") || (w == "end")) || (w == "player"))) {
          break;
        }
        addorder(p,words);
      }
      while ((words[0].toLowerCase() == "unit")) {
        var u = findunit(p,int.parse(words[1]));
        var w;
        if (u == null) {
          p.quote(words.toList());
          p.event("You have no such unit");
          do {
            var words = read(file);
            if (words == null) return;
            w = words[0].toLowerCase();
          } while ((!(((w == "unit") || (w == "end")) || (w == "player"))));
          continue;
        }
        while (true) {
          words = read(file);
          if (words == null) return;
          w = words[0].toLowerCase();
          if ((((w == "unit") || (w == "end")) || (w == "player"))) {
            break;
          }
          addorder(u,words);
        }
      }
    }
  } finally {
    file.close();
  }
}

void adjustorders() {
  $players.each((p) {
    p.adjustorders();
  });
  $units.each((u) {
    u.adjustorders();
  });
}

void doorder(Entity e, Order o) {
  if (o.type == Order.Null) {
    return;
  }
  e.quote(<String>[Order.Ordertypes[o.type]]..addAll(o.args));
  if (e is Unit) {
    doorder2(e,o);
    return;
  }
  Player p = e;
  switch (o.type) {
    case Order.Email:
      email(p,o.args);
      break;
    case Order.Friendly:
      friendly(p,o.args);
      break;
    case Order.Give:
      give(p,o.args);
      break;
    case Order.Hostile:
      hostile(p,o.args);
      break;
    case Order.Name:
      name(p,o.args);
      break;
    case Order.Quit:
      quit(p);
      break;
    default:
      p.event("That order must be issued for a specific unit");
      break;
  }
}

void doorder2(Unit u, Order o) {
  switch (o.type) {
    case Order.Build:
      build(u,o.args.toList());
      break;
    case Order.Drop:
      drop(u);
      break;
    case Order.Email:
      email(u.player,o.args);
      break;
    case Order.Explore:
      explore(u,o.args);
      break;
    case Order.Fire:
      fire(u,o.args);
      break;
    case Order.Group:
      group(u,o.args);
      break;
    case Order.Move:
      move(u,o.args);
      break;
    case Order.Name:
      name(u,o.args);
      break;
    case Order.Quit:
      quit(u.player);
      break;
    case Order.Ungroup:
      ungroup(u,o.args);
      break;
    default:
      u.event("That order must be issued for your empire as a whole");
      break;
  }
}
