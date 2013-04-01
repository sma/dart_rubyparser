part of rainbowsend;

var $moneythreshold = Unittypes.collect((ut) => ut.buildcost).max();

void _decideorders(Player p) {
  p.units.each((u) {
    if (u.isCity()) {
      if (p.money >= $moneythreshold) {
        var i;
        switch (rand(3)) {
          case 0:
            i = Unit.Tanks;
            break;
          case 1:
            i = Unit.Artillery;
            break;
          case 2:
            i = Unit.Infantry;
            break;
        }
        var ut = Unittypes[i];
        u.orders.add(new Order(Order.Build, new Array.from([ut.name])));
      } else {
        if (rand(3) > 0) {
          var ut = Unittypes[Unit.Infantry];
          u.orders.add(new Order(Order.Build, new Array.from([ut.name])));
        }
      }
    } else {
      _combatorders(u);
    }
  });
}

void _combatorders(Unit u) {
  var targets = $units.select((u2) {
    return (distance(u.hex(),u2.hex()) < $sightingdistance);
  });
  if ((Unittypes[u.type].range > 0)) {
    targets.map((u2) => u2.hex()).shuffle().each((hex) {
      if ((hex != u.hex())) {
        u.orders.add(new Order(Order.Fire,new Array.from(["${hex.x}/${hex.y}"])));
      }
    });
  }
}

void decideorders() {
  $players.each((p) {
    if (p.email == null || p.lastorders < $turn - 1) {
      _decideorders(p);
    }
  });
}