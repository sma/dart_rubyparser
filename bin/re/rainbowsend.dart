library rainbowsend;

import 'dart:math';
import 'dart:io' as io;

part 'ai.dart';
part 'entity.dart';
part 'game.dart';
part 'map.dart';
part 'order.dart';
part 'parse.dart';
part 'player.dart';
part 'rules.dart';
part 'save.dart';
part 'unit.dart';
part 'writerpt.dart';

int $humanplayers = 0;
const $computerplayers = 2;
const $startingmoney = 50;
int $mapsizex = 25;
int $mapsizey = 25;
const $cityseparation = 3;
const $sightingdistance = 3;

/** Internal random number generator (see [rand]). */
var _rnd = Random();

/** Returns a random number between 0 and n (excluding). */
int rand(int n) {
  return _rnd.nextInt(n);
}

/** Returns true if the specified number is odd. */
bool odd(int x) {
  return (x % 2) == 1;
}

/** Returns true if the specified number is even. */
bool even(int x) {
  return (x % 2) == 0;
}

/** Returns -1 if the specified number is negativ,
 * +1 if the number is positive and 0 if it is zero. */
int sign(int x) {
  if (x < 0) return -1;
  if (x > 0) return 1;
  return 0;
}

/** An Array class compatible with Ruby's API. */
class Array<E> /*implements Iterable<E>*/ {
  late List<E> _elements;

  Array(/*[int length=0]*/) {
    //if (length == 0) {
      _elements = <E>[];
    //} else {
    //  _elements = List.filled(length, null);
    //}
  }

  factory Array.from(List<E> list) {
    final a = Array<E>();
    a._elements = list;
    return a;
  }

  int get length => _elements.length;

  bool get isEmpty => length == 0;

  void add(E element) {
    _elements.add(element);
  }

  void insert(int index, E element) {
    _elements.insert(index, element);
  }

  void each(void Function(E element) f) {
    _elements.forEach(f);
  }

  void each_with_index(void Function(E element, int index) f) {
    for (var index = 0; index < _elements.length; index++) {
      f(_elements[index], index);
    }
  }

  E? find(bool Function(E element) f) {
    for (final e in _elements) {
      if (f(e)) {
        return e;
      }
    }
    return null;
  }

  E? detect(bool Function(E element) f) {
    return find(f);
  }

  Array<F> collect<F>(F Function(E element) f) {
    final a = Array<F>();
    for (var e in _elements) {
      a.add(f(e));
    }
    return a;
  }

  Array<F> map<F>(F Function(E element) f) {
    return collect(f);
  }

  Array<E> select(bool Function(E element) f) {
    final a = Array<E>();
    for (var e in _elements) {
      if (f(e)) {
        a.add(e);
      }
    }
    return a;
  }

  int index(E element) {
    for (var i = 0; i < _elements.length; i++) {
      if (_elements[i] == element) {
        return i;
      }
    }
    return -1;
  }

  Array<E> shuffle() {
    final a = List.of(_elements);
    for (var i = a.length - 1; i > 0; i--) {
      final j = rand(i + 1);
      final t = a[i];
      a[i] = a[j];
      a[j] = t;
    };
    return Array.from(a);
  }

  E operator [](int index) {
    return _elements[index];
  }

  void operator []=(int index, E value) {
    _elements[index] = value;
  }

  E max() {
    if (_elements.isEmpty) {
      throw TypeError();
    }
    var e = _elements[0] as Comparable;
    for (var i = 1; i < _elements.length; i++) {
      final f = _elements[i] as Comparable;
      if (f.compareTo(e) > 0) {
        e = f;
      }
    }
    return e as E;
  }

  void clear() {
    _elements = [];
  }

  E last() {
    return _elements[_elements.length - 1];
  }

  void remove(E element) {
    _elements.remove(element);
  }

  Iterator<E> get iterator => _elements.iterator;

  bool contains(E element) {
    return _elements.contains(element);
  }

  Array<E> dup() {
    return Array.from(List.from(_elements));
  }

  Array<E> sublist(int start) {
    return Array.from(_elements.sublist(start));
  }

  List<E> toList() {
    return _elements;
  }

  void sort(int Function(E e1, E e2) cmp) {
    _elements.sort(cmp);
  }

  @override
  String toString() => 'Array$_elements';
}

/** A File class compatible with Ruby's API. */
class File {
  late List<String> _lines;
  late String? _name;
  late StringBuffer _b;
  late int _i = 0;

  File.forRead(this._lines);

  File.forWrite(String name) {
    _name = name;
    _b = StringBuffer();
  }

  static File? open(String name, [String mode='r']) {
    try {
      if (mode == 'w') return File.forWrite(name);
      return File.forRead(io.File(name).readAsLinesSync());
    } on io.IOException catch (_) {
      return null;
    }
  }

  String? gets() {
    return _i < _lines.length ? _lines[_i++] : null;
  }

  void each(void Function(String line) f) {
    var line = gets();
    while (line != null) {
      f(line);
      line = gets();
    }
  }

  void close() {
    if (_name != null) {
      io.File(_name!).writeAsStringSync(_b.toString());
    }
  }

  void write(String s) {
    _b.write(s);
  }
}

void main(List<String> arguments) {
  switch (arguments.isNotEmpty ? arguments[0] : null) {
    case '--new':
      newgame();
      break;
    case '--turn':
      runturn();
      break;
    case '--version':
      print("Rainbow's End version 1.3");
      print('Rules Copyright 2001 by Russell Wallace');
      print('Sourcecode Copyright 2001,2013 by Stefan Matthias Aust');
      print('This program is free software.');
      print('See license for details.');
      break;
    default:
      print('usage: ${io.Platform.script} {--new | --turn | --version}');
  }
}
