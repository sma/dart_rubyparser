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
var _rnd = new Random();

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
  List<E> _elements;

  Array([int length=0]) {
    if (length == 0) {
      _elements = [];
    } else {
      _elements = new List.filled(length, null);
    }
  }

  factory Array.from(List<E> list) {
    var a = new Array();
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

  void each(void f(E element)) {
    _elements.forEach(f);
  }

  void each_with_index(void f(E element, int index)) {
    for (int index = 0; index < _elements.length; index++) {
      f(_elements[index], index);
    }
  }

  E find(bool f(E element)) {
    for (E e in _elements) {
      if (f(e)) {
        return e;
      }
    }
    return null;
  }

  E detect(bool f(E element)) {
    return find(f);
  }

  Array<dynamic> collect(dynamic f(E element)) {
    var a = new Array();
    for (E e in _elements) {
      a.add(f(e));
    }
    return a;
  }

  Array<dynamic> map(dynamic f(E element)) {
    return collect(f);
  }

  Array<E> select(bool f(E element)) {
    Array<E> a = new Array();
    for (E e in _elements) {
      if (f(e)) {
        a.add(e);
      }
    }
    return a;
  }

  int index(E element) {
    for (int i = 0; i < _elements.length; i++) {
      if (_elements[i] == element) {
        return i;
      }
    }
    return -1;
  }

  Array<E> shuffle() {
    var a = new List.from(_elements);
    for (int i = a.length - 1; i > 0; i--) {
      var j = rand(i + 1);
      var t = a[i];
      a[i] = a[j];
      a[j] = t;
    };
    return new Array.from(a);
  }

  E operator [](int index) {
    return _elements[index];
  }

  void operator []=(int index, E value) {
    _elements[index] = value;
  }

  E max() {
    if (_elements.isEmpty) {
      return null;
    }
    int e = _elements[0];
    for (int i = 1; i < _elements.length; i++) {
      int f = _elements[i];
      if (f > e) {
        e = f;
      }
    }
    return e;
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
    return new Array.from(new List.from(_elements));
  }

  Array<E> sublist(int start) {
    return new Array.from(_elements.sublist(start));
  }

  List toList() {
    return _elements;
  }

  void sort(int cmp(E e1, E e2)) {
    _elements.sort(cmp);
  }

  toString() => "Array$_elements";
}

/** A File class compatible with Ruby's API. */
class File {
  List<String> _lines;
  String _name;
  StringBuffer _b;
  int _i = 0;

  File.forRead(this._lines);

  File.forWrite(String name) {
    this._name = name;
    this._b = new StringBuffer();
  }

  static File open(String name, [String mode="r"]) {
    try {
      if (mode == "w") return new File.forWrite(name);
      return new File.forRead(new io.File(name).readAsLinesSync());
    } on io.IOException catch (e) {
      return null;
    }
  }

  String gets() {
    return _i < _lines.length ? _lines[_i++] : null;
  }

  void each(void f(String line)) {
    var line = gets();
    while (line != null) {
      f(line);
      line = gets();
    }
  }

  void close() {
    if (_name != null) {
      new io.File(_name).writeAsStringSync(_b.toString());
    }
  }

  write(String s) {
    _b.write(s);
  }
}

void main(List<String> arguments) {
  switch (arguments.length > 0 ? arguments[0] : null) {
    case "--new":
      newgame();
      break;
    case "--turn":
      runturn();
      break;
    case "--version":
      print("Rainbow's End version 1.3");
      print("Rules Copyright 2001 by Russell Wallace");
      print("Sourcecode Copyright 2001,2013 by Stefan Matthias Aust");
      print("This program is free software.");
      print("See license for details.");
      break;
    default:
      print("usage: ${io.Platform.script} {--new | --turn | --version}");
  }
}
