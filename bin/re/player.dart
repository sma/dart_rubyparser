part of rainbowsend;

class Player extends Entity implements Comparable<Player> {
  String email;
  int money;
  int lastorders;
  Array<Player> friendly;
  Array<Unit> units;
  Array<Unit> removedunits;

  Player() {
    this.friendly = new Array();
    this.units = new Array();
    this.removedunits = new Array();
  }

  int compareTo(Player p) {
    int cmp = p.units.length - units.length;
    if (cmp == 0) {
      cmp = p.money - money;
      if (cmp == 0) {
        cmp = id - p.id;
      }
    }
    return cmp;
  }

  bool cansee(o) {
    var hex = o is Unit ? (o as Unit).hex() : (o as Hex);
    return this.units.detect((u) => (distance(u.hex(), hex) < $sightingdistance)) != null;
  }
}

Array<Player> $players = new Array();

void countplayers() {
  var file = File.open("players");
  if (file == null) throw ("Players file not found");
  try {
    $humanplayers = 0;
    file.each((line) {
      if (parse(line).isEmpty) {
        return;
      }
      $humanplayers += 1;
    });
  } finally {
    file.close();
  }
}

void readplayers() {
  var file = File.open("players");
  if (file == null) throw("Unable to open players file");
  try {
    $players.each_with_index((p,i) {
      if ((i < $humanplayers)) {
        var words;
        do {
          words = parse(file.gets());
        } while (words.isEmpty);
        p.name = ("Player");
        p.email = (words[0]);
      } else {
        p.name = ("Computer");
        p.email = (null);
      }
      p.id = ((i + 1));
      p.money = $startingmoney;
      p.lastorders = (0);
    });
  } finally {
    file.close();
  }
}

void initplayers() {
  countplayers();
  allocplayers();
  readplayers();
}

void allocplayers() {
  $players = new Array($humanplayers + $computerplayers).map((_) => new Player());
}

Player findplayer(int id) {
  return $players.detect((p) => p.id == id);
}

void removeplayers() {
  $players = $players.select((p) {
    if (p.units.length > 0) {
      return true;
    } else {
      $players.each((pp) => pp.friendly.remove(p));
      return false;
    }
  });
}