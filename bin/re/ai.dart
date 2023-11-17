part of 'rainbowsend.dart';

var $moneythreshold = Unittypes.collect((ut) => ut.buildcost).max();

void _decideorders(Player p) {
  p.units.each((u) {
    if (u.isCity()) {
      if (p.money >= $moneythreshold) {
        int i;
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
          default:
            throw Error();
        }
        final ut = Unittypes[i];
        u.orders.add(Order(Order.Build, Array.from([ut.name])));
      } else {
        if (rand(3) > 0) {
          final ut = Unittypes[Unit.Infantry];
          u.orders.add(Order(Order.Build, Array.from([ut.name])));
        }
      }
    } else {
      _combatorders(u);
    }
  });
}

void _combatorders(Unit u) {
  final targets = $units.select((u2) {
    return (distance(u.hex(),u2.hex()) < $sightingdistance);
  });
  if ((Unittypes[u.type].range > 0)) {
    targets.map((u2) => u2.hex()).shuffle().each((hex) {
      if ((hex != u.hex())) {
        u.orders.add(Order(Order.Fire,Array.from(['${hex.x}/${hex.y}'])));
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