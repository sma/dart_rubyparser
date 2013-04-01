part of rainbowsend;

Array<String> parse(String line) {
  Array<String> a = new Array();
  var re = new RegExp(r'([\w,.+\-@/]+)|\"(.*?)\"|\#.*$');
  for (Match match in re.allMatches(line)) {
    if (match[1] != null) a.add(match[1]);
    if (match[2] != null) a.add(match[2]);
  }
  return a;
}