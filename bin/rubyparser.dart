// Copyright 2013 by Stefan Matthias Aust
library rubyparser;

import 'dart:io';

part 'scanner.dart';
part 'parser.dart';
part 'printer.dart';

void parse(File file) {
  var source = file.readAsStringSync();
  var parser = new Parser(source);
  print("----------$file--------------------------------------------------");
  pp(parser.parse());
}

void main() {
  for (var file in new Directory("rb").listSync()) {
    parse(file);
  }
}
