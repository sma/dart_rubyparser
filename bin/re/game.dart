part of rainbowsend;

int $turn = 0;
int $slot = 0;

void newgame() {
  $turn = 0;
  initplayers();
  inithexes();
  initunits();
  writereports();
  Save.save();
}

void playerorders() {
  for ($slot = 1; $slot <= Maxorders; $slot++) {
    var si = ($slot - 1);
    $players.each((p) {
      if ((si < p.orders.length)) {
        doorder(p,p.orders[si]);
      }
    });
  }
}
void unitorders_(int phase) {
  var si = ($slot - 1);
  $units.shuffle().each((u) {
    if ((u.removed || (si >= u.orders.length))) {
      return;
    }
    var o = u.orders[si];
    switch (o.type) {
      case Order.Build:
      case Order.Drop:
        if ((phase != 2)) {
          return;
        }
        break;
      case Order.Move:
        if ((phase != 1)) {
          return;
        }
        break;
      default:
        if ((phase != 0)) {
          return;
        }
        break;
    }
    doorder(u,o);
  });
}

void unitorders() {
  for ($slot = 1; $slot <= Maxorders; $slot++) {
    unitorders_(0);
    unitorders_(1);
    combat();
    capture();
    unitorders_(2);
  }
}

void runturn() {
  $slot = 0;
  Save.load();
  readorders();
  decideorders();
  adjustorders();
  $turn += 1;
  refreshunits();
  playerorders();
  unitorders();
  income();
  upkeep();
  writereports();
  removeplayers();
  Save.save();
}

