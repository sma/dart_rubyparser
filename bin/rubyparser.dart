import 'dart:io';

import 'package:rubyparser/rubyparser.dart';

void main() {
  for (File file in Directory("rb").listSync()) {
    parse(file);
  }
}
