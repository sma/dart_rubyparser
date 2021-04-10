// Copyright 2013 by Stefan Matthias Aust
part of rubyparser;

class Scanner {
  Scanner(String source) : matches = RegExp(re, multiLine: true).allMatches(source).iterator {
    current = next();
  }

  final Iterator<Match> matches;
  String current = EOF;
  bool eol = false;

  static const EOF = '';

  static const re = r'\n|;|[ \r\t]+|#.*$|(' //   whitespace & comments
      r'\d+(?:\.\d+)?|' //                       numbers
      r'[@$]?\w+[?!]?|' //                       names
      r':(?:\w+|[-+*/%<>=!&|]+)|' //             symbols
      r'''"(?:\\.|[^"])*"|'(?:\\.|[^'])*'|''' // strings
      r'/ /|/[^/ ](?:\\.|[^/])*?/|' //           regular expression
      r'<=>|<<|=~|[-+*/%<>!=]=?|' //             operators
      r'::|&&|\|\||\.\.\.?|' //                  operators
      r'[.,()\[\]|{}?:]' //                      syntax
      r')|(.)'; //                               catch illegal character

  /**
   * Throws a scanner or parser error.
   */
  String error(String message) {
    return message;
  }

  /**
   * Returns the next token or `null` on "end of input".
   * Sets [eol] to true if the a newline was seen.
   */
  String next() {
    if (matches.moveNext()) {
      if (matches.current[2] != null) {
        throw error("invalid character '«${matches.current[2]}»");
      }
      if (matches.current[1] != null) {
        return matches.current[1]!;
      }
      if (matches.current[0] == ';' || matches.current[0] == '\n') {
        eol = true;
      }
      return next();
    }
    return EOF;
  }

  /**
   * Returns `true` if the end of the input was reached and `false` otherwise.
   */
  bool atEnd() {
    return current == EOF;
  }

  /**
   * Returns `true` if the current token is equal to the given one and consumes it.
   * Otherwise the method returns `false` and doesn't consume the current token.
   */
  bool at(String token) {
    if (current == token) {
      consume();
      return true;
    }
    return false;
  }

  /**
   * Consumes the current token if it equal to the given one or throws an error.
   */
  void expect(String token) {
    if (!at(token)) {
      throw error('expected $token, found $current');
    }
  }

  /**
   * Returns the current token and consumes it, setting the current token to the next one.
   * Also resets [eol].
   */
  String consume() {
    final value = current;
    eol = false;
    current = next();
    return value;
  }

  static final KEYWORDS =
      Set.of('alias and begin break case class def defined? do else elsif end ensure false for if in module next nil '
              'not or redo rescue retry return self super then true undef unless until when while yield'
          .split(' '));

  /**
   * Returns `true` if the current token is a reserved keyword and `false` otherwise.
   */
  bool isKeyword() {
    return KEYWORDS.contains(current);
  }
}
