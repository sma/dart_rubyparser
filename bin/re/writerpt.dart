part of 'rainbowsend.dart';

File? file;

void write(Object s) {
  file!.write('$s');
}

void writec(int n, String c) {
  for (var i = 0; i < n; i++) {
    file!.write(c);
  }
}

void space(int n) {
  writec(n, ' ');
}

void newline() {
  write('\n');
}

void writew(Object s, int width) {
  final ss = '$s';
  write(ss);
  space(width - ss.length);
}

void right(Object s, int width) {
  final ss = '$s';
  space(width - ss.length);
  write(ss);
}

int wrap(String s, int indent) {
  var i = indent;
  while (true) {
    // Find next word break

    var j = 0;
    while (j < s.length && s[j] != ' ') {
      j++;
    }

    // If we'll go over the 70 column mark
    // and are not already at the start of a line
    // then go to a new line

    if (i > indent && i + 1 + j > 70) {
      newline();
      space(indent);
      i = indent;
    }

    // If we're not at the start of a new line
    // then put a space before this word

    if (i > indent) {
      space(1);
      i++;
    }

    // Print this word

    i += j;
    file!.write(s.substring(0, j));
    s = s.substring(j);

    // If we're at the end of the string
    // then we're done

    if (s.isEmpty) {
      return i;
    }

    // Move on to the next word

    s = s.substring(1);
  }
}

void writeline(Object s) {
  write(s);
  newline();
}

void underline(String s) {
  writeline(s);
  writec(s.length, '-');
  newline();
  newline();
}

void item(String caption, int width, Object s) {
  space(2);
  write(caption);
  write(':');
  space(width + 2 - caption.length);
  writeline(s);
}

int countcities(Array<Unit> units) {
  return units.select((u) => u.isCity()).length;
}

void reportevent(String s) {
  space(2);
  final i = s.indexOf(' ') + 1;
  write(s.substring(0, i));
  wrap(s.substring(i), 2 + i);
  newline();
}

void reportevents(Entity e) {
  e.events.each(reportevent);
  if (!e.events.isEmpty) {
    newline();
  }
}

void reportheader(Player p) {
  write("Rainbow's End Turn ");
  write($turn);
  newline();
  writeline(p.nameid);
  newline();
}

void reporttotals() {
  var money = 0;
  $players.each((p) => money += p.money);
  final cities = countcities($units);

  writeline('Game totals');
  item('Players', 11, $players.length);
  item('Map size', 11, '${$mapsizex}x${$mapsizey}');
  item('Money', 11, money);
  item('Cities', 11, cities);
  item('Other units', 11, $units.length - cities);
  newline();
}

void reportgeneralorders(Player p) {
  if (p.events.isEmpty) {
    return;
  }
  writeline('General orders');
  reportevents(p);
}

void reportplayersummary(Player p) {
  writeline('Player summary');
  writeline('  number  relations  money  units');
  writeline('  ------  ---------  -----  -----');

  var totmoney = 0;
  var totunits = 0;

  $players.each((p2) {
    space(2);
    writew(p2.id, 8);
    if (p == p2) {
      writew('n/a', 9);
    } else if (p.friendly.contains(p2)) {
      writew('friendly', 9);
    } else {
      writew('hostile', 9);
    }
    right(p2.money, 7);
    right(p2.units.length, 7);
    newline();

    totmoney += p2.money;
    totunits += p2.units.length;
  });

  writeline('  ------  ---------  -----  -----');

  space(19);
  right(totmoney, 7);
  right(totunits, 7);
  newline();

  newline();
}

void reportplayerdetails(Player p) {
  underline('Player details');

  $players.each((p2) {
    final cities = countcities(p2.units);

    writeline(p2.nameid);
    item('Email', 11, p2.email != null ? p2.email! : 'None');
    if (p == p2) {
      item('Relations', 11, 'N/A');
    } else if (p.friendly.contains(p2)) {
      item('Relations', 11, 'Friendly');
    } else {
      item('Relations', 11, 'Hostile');
    }
    item('Money', 11, p2.money);
    item('Cities', 11, cities);
    item('Other units', 11, p2.units.length - cities);
    newline();
  });
}

void reportunitsummary(Player p, Player p2) {
  var found = false;
  for (var i = 0; i < p2.units.length; i++) {
    final u = p2.units[i];
    if (!p.cansee(u)) {
      continue;
    }

    found = true;
    break;
  }
  if (!found) {
    return;
  }

  write('Unit summary: ');
  writeline(p2.nameid);
  writeline('  number  type        x   y  group');
  writeline('  ------  ---------  --  --  -----');

  p2.units.each((u) {
    if (!p.cansee(u)) {
      return;
    }
    final h = u._hex;
    final x = htox(h);
    final y = htoy(h);

    space(2);
    writew(u.id, 8);
    writew(Unittypes[u.type].name, 9);
    right(x, 4);
    right(y, 4);
    write('  none');
    newline();
  });

  writeline('  ------  ---------  --  --  -----');
  newline();
}

void reportunitdetails(Player p) {
  underline('Unit details');

  var i = 0;
  var j = 0;
  while (i < p.units.length || j < p.removedunits.length) {
    final ui = i < p.units.length ? p.units[i] : null;
    final uj = j < p.removedunits.length ? p.removedunits[j] : null;

    Unit u;
    if (ui == null) {
      u = uj!;
      j++;
    } else if (uj == null) {
      u = ui;
      i++;
    } else if (ui.id < uj.id) {
      u = ui;
      i++;
    } else {
      u = uj;
      j++;
    }

    writeline(u.nameid);
    reportevents(u);

    if (u.removed) {
      continue;
    }

    item('Type', 12, Unittypes[u.type].name.toUpperCase());
    item('Location', 12, u.hex().nameid);
    item('Grouped with', 12, 'None');
    newline();
  }
}

void reporthexsummary(Player p) {
  if (p.units.isEmpty) {
    return;
  }

  writeline('Hex summary');
  writeline('   x   y  terrain   city');
  writeline('  --  --  --------  ----');

  for (var y = 0; y < $mapsizey; y++) {
    for (var x = 0; x < $mapsizex; x++) {
      final h = xytoh(x, y);
      final hex = $hexes[h];
      if (!p.cansee(hex)) {
        continue;
      }
      final t = hex.terrain;

      right(x, 4);
      right(y, 4);
      space(2);
      writew(Terrains[t].name, 10);
      if (t == 0) {
        writeline('n/a');
        continue;
      }
      if (cityarea(hex)) {
        writeline('yes');
      } else {
        writeline('no');
      }
    }
  }

  writeline('  --  --  --------  ----');
  newline();
}

void _reporthexdetails(Player p, Hex hex) {
  var found = false;
  for (var i = 0; i < hex.events.length; i++) {
    final he = hex.events[i];
    if (he.players.contains(p)) {
      found = true;
      break;
    }
  }

  if (p.cansee(hex)) {
    for (var i = 0; i < $units.length; i++) {
      final u = $units[i];
      if (u.hex() == hex) {
        found = true;
        break;
      }
    }
  }

  if (!found) {
    return;
  }

  writeline(hex.nameid);

  found = false;
  for (var i = 0; i < hex.events.length; i++) {
    final he = hex.events[i];
    if (he.players.contains(p)) {
      reportevent(he.event);
      found = true;
    }
  }
  if (found) {
    newline();
  }

  if (!p.cansee(hex)) {
    return;
  }

  found = false;
  $players.each((p2) {
    p2.units.each((u) {
      if (u.hex() != hex) {
        return;
      }

      space(2);
      if (p2 == p) {
        write('* ');
      } else {
        write('- ');
      }
      writeline(u.namepidtype());

      found = true;
    });
  });
  if (found) {
    newline();
  }

  String s;
  if (cityarea(hex)) {
    s = 'Yes';
  } else {
    s = 'No';
  }
  if (hex.terrain == 0) {
    s = 'N/A';
  }
  item('City area', 9, s);
  newline();
}

void reporthexdetails(Player p) {
  underline('Hex details');

  $hexes.each((h) => _reporthexdetails(p, h));
}

void templateitem(String caption, int n, String co) {
  write(caption);
  write(' ');
  write(n);
  write('  # ');
  writeline(co);
  newline();
}

void reporttemplate(Player p) {
  if (p.units.isEmpty) {
    return;
  }

  underline('Order template');

  templateitem('player', p.id, p.name);
  p.units.each((u) {
    templateitem('unit', u.id, '${u.name} in ${u.hex().nameid}');
  });
  writeline('end');
}

void report(Player p) {
  file = File.open('${p.id}.txt', 'w');
  if (file == null) {
    throw ('Unable to create report file');
  }

  reportheader(p);
  reporttotals();
  reportgeneralorders(p);
  reportplayersummary(p);
  reportplayerdetails(p);
  $players.each((pp) => reportunitsummary(p, pp));
  reportunitdetails(p);
  reporthexsummary(p);
  reporthexdetails(p);
  reporttemplate(p);
  if (p.units.isEmpty) {
    write('Unfortunately your empire has been eliminated from the game.\n'
        'Hope you enjoyed playing; condolences on your ill fortune,\n'
        'and better luck next time.\n');
  }
  file!.close();
}

void writereports() {
  final players = $players.dup();
  players.sort((Player p1, Player p2) {
    var n = p2.units.length - p1.units.length;
    if (n != 0) {
      return n;
    }
    n = p2.money - p1.money;
    if (n != 0) {
      return n;
    }
    return p1.id - p2.id;
  });
  players.each(report);
}
