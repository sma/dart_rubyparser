part of rainbowsend;

class Save {
  static File file;

  static void write_s(String s) {
    file.write('"$s"');
  }
  static void write_n(Object o) {
    file.write('$o');
  }
  static void space([int n=1]) {
    for (int i = 0; i < n; i++) {
      file.write(" ");
    }
  }
  static void newline() {
    file.write("\n");
  }
  static void comment(String c) {
    file.write("# $c\n");
  }
  static void write(Object o, String c) {
    write_n(o);
    space(2);
    comment(c);
  }

  static void save() {
    file = File.open("game","w");
    if (file == null) throw ("Unable to create save game file");
    try {
      write($turn,"turn");
      write($players.length,"players");
      comment("number, name, email, money, last orders");
      $players.each((p) {
        write_n(p.id);
        space();
        write_s(p.name);
        space();
        write_s(p.email);
        space();
        write_n(p.money);
        space();
        write_n(p.lastorders);
        newline();
      });
      newline();
      write("${$mapsizex} ${$mapsizey}","map size");
      comment("terrain");
      $hexes.each((h) {
        write_n(h.terrain);
        newline();
      });
      newline();
      write($units.length,"units");
      comment("number, name, type, player, hex");
      $units.each((u) {
        write_n(u.id);
        space();
        write_s(u.name);
        space();
        write_n(u.type);
        space();
        write_n(u.player.id);
        space();
        write_n(u._hex);
        newline();
      });
      newline();
      var n = 0;
      $players.each((p) => n += p.friendly.length);
      write(n,"friendly");
      comment("player, other");
      $players.each((p) {
        p.friendly.each((p2) {
          write_n(p.id);
          space();
          write_n(p2.id);
          newline();
        });
      });
    } finally {
      file.close();
    }
  }

  static Array<String> read() {
    var words;
    do {
      var line = file.gets();
      if (line == null) {
        return null;
      }
      words = parse(line);
    } while (words.isEmpty);
    return words;
  }

  static void load() {
    file = File.open("game","r");
    if (file == null) throw ("Save game file not found");
    try {
      var words = read();
      $turn = int.parse(words[0]);
      words = read();
      int n = int.parse(words[0]);
      $players = new Array<Player>();
      for (int i = 0; i < n; i++) {
        $players.add(new Player());
      }
      $players.each((p) {
        words = read();
        p.id = int.parse(words[0]);
        p.name = (words[1]);
        p.email = (words[2]);
        if ((p.email == "null")) {
          p.email = null;
        }
        p.money = int.parse(words[3]);
        p.lastorders = int.parse(words[4]);
      });
      words = read();
      $mapsizex = int.parse(words[0]);
      $mapsizey = int.parse(words[1]);
      allochexes();
      $hexes.each((h) {
        words = read();
        h.terrain = int.parse(words[0]);
      });
      words = read();
      n = int.parse(words[0]);
      for (int i = 0; i < n; i++) {
        words = read();
        addunit(new Unit(int.parse(words[0]),words[1],int.parse(words[2]),findplayer(int.parse(words[3])),int.parse(words[4])));
      }
      words = read();
      n = int.parse(words[0]);
      for (int i = 0; i < n; i++) {
        words = read();
        var p = findplayer(int.parse(words[0]));
        var p2 = findplayer(int.parse(words[1]));
        p.friendly.add(p2);
      }
    } finally {
      file.close();
    }
  }
}
