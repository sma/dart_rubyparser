part of rainbowsend;

class Player extends Entity {
  var email, money, lastorders;
  List<Player> friendly;
  List<Unit> units = [];
  List<Unit> removedunits = [];

  bool cansee(o) {
    var h;
    if (o is Unit) {
      h = o.hex;
    } else {
      h = o;
    }
    return units.firstWhere((u) => distance(u.hex, h) < G_sightingdistance, orElse: () => null) != null;
  }

}

countplayers() {
  // TODO
}

allocplayers() {
  // TODO
}

readplayers() {
  // TODO
}

initplayers() {
  countplayers();
  allocplayers();
  readplayers();
}

findplayer(id) {
  return G_players.firstWhere((p) => p.id == id);
}

removeplayers() {
  // TODO
}
