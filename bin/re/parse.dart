part of 'rainbowsend.dart';

Array<String> parse(String line) {
  final a = Array<String>();
  final re = RegExp(r'([\w,.+\-@/]+)|\"(.*?)\"|\#.*$');
  for (final match in re.allMatches(line)) {
    if (match[1] != null) a.add(match[1]!);
    if (match[2] != null) a.add(match[2]!);
  }
  return a;
}
