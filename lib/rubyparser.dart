// Copyright 2013 by Stefan Matthias Aust
library rubyparser;

import 'dart:io';

part 'scanner.dart';
part 'parser.dart';
part 'printer.dart';

void parse(File file) {
  final source = file.readAsStringSync();
  final parser = Parser(source);
  print("----------$file--------------------------------------------------");
  pp(parser.parse());
}
