// Copyright 2013 by Stefan Matthias Aust
part of rubyparser;

class Scanner {
  Iterator<Match> matches;
  String current;
  bool eol;

  Scanner(String source) {
    var re = r'\n|;|[ \r\t]+|#.*$|('            // whitespace & comments
        r'\d+(?:\.\d+)?|'                       // numbers
        r'[@$]?\w+[?!]?|'                       // names
        r':(?:\w+|[-+*/%<>=!&|]+)|'             // symbols
        r'''"(?:\\.|[^"])*"|'(?:\\.|[^'])*'|''' // strings
        r'/ /|/[^/ ](?:\\.|[^/])*?/|'           // regular expression
        r'<=>|<<|=~|[-+*/%<>!=]=?|'             // operators
        r'::|&&|\|\||\.\.\.?|'                  // operators
        r'[.,()\[\]|{}?:]'                      // syntax
        r')|(.)';                               // catch illegal character
    matches = new RegExp(re, multiLine: true).allMatches(source).iterator;
    current = next();
    eol = true;
  }

  /**
   * Throws a scanner or parser error.
   */
  void error(String message) {
    throw message;
  }

  /**
   * Returns the next token or `null` on "end of input".
   * Sets [eol] to true if the a newline was seen.
   */
  String next() {
    if (matches.moveNext()) {
      if (matches.current[2] != null) {
        error("invalid character '«${matches.current[2]}»");
      }
      if (matches.current[1] != null) {
        return matches.current[1];
      }
      if (matches.current[0] == ';' || matches.current[0] == '\n') {
        eol = true;
      }
      return next();
    }
    return null;
  }

  /**
   * Returns `true` if the end of the input was reached and `false` otherwise.
   */
  bool atEnd() {
    return current == null;
  }

  /**
   * Returns `true` if the current token is equal to the given one and consumes it.
   * Otherwise the method returns `false` and doesn't consume the current token.
   */
  bool at(token) {
    if (current == token) {
      consume();
      return true;
    }
    return false;
  }

  /**
   * Consumes the current token if it equal to the given one or throws an error.
   */
  expect(token) {
    if (!at(token)) {
      error("expected ${token}, found ${current}");
    }
  }

  /**
   * Returns the current token and consumes it, setting the current token to the next one.
   * Also resets [eol].
   */
  String consume() {
    var value = current;
    eol = false;
    current = next();
    return value;
  }

  static final Set<String> KEYWORDS = new Set.from(
      'alias and begin break case class def defined? do else elsif end ensure false for if in module next nil '
      'not or redo rescue retry return self super then true undef unless until when while yield'.split(' '));

  /**
   * Returns `true` if the current token is a reserved keyword and `false` otherwise.
   */
  bool isKeyword() {
    return KEYWORDS.contains(current);
  }
}
