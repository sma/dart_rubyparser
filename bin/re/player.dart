part of rainbowsend;

class Player extends Entity implements Comparable<Player> {
  String? email;
  late int money;
  late int lastorders;
  Array<Player> friendly = Array();
  Array<Unit> units = Array();
  Array<Unit> removedunits = Array();

  Player() : super(0, '');

  @override
  int compareTo(Player p) {
    var cmp = p.units.length - units.length;
    if (cmp == 0) {
      cmp = p.money - money;
      if (cmp == 0) {
        cmp = id - p.id;
      }
    }
    return cmp;
  }

  bool cansee(Object o) {
    final hex = o is Unit ? (o).hex() : (o as Hex);
    return units.detect((u) => (distance(u.hex(), hex) < $sightingdistance)) != null;
  }
}

Array<Player> $players = Array();

void countplayers() {
  final file = File.open('players');
  if (file == null) throw ('Players file not found');
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
  final file = File.open('players');
  if (file == null) throw ('Unable to open players file');
  try {
    $players.each_with_index((p, i) {
      if ((i < $humanplayers)) {
        Array<String> words;
        do {
          words = parse(file.gets()!);
        } while (words.isEmpty);
        p.name = ('Player');
        p.email = (words[0]);
      } else {
        p.name = ('Computer');
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
  $players = Array.from(List.generate($humanplayers + $computerplayers, (_) => Player()));
}

Player? findplayer(int id) {
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
