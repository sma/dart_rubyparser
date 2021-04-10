import 'dart:io';

import 'package:rubyparser/rubyparser.dart';

void main() {
  for (final file in Directory('rb').listSync().whereType<File>()) {
    parse(file);
  }
}
