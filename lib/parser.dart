// Copyright 2013 by Stefan Matthias Aust
part of 'rubyparser.dart';

final class AST {
  const AST(this.type, this.map);
  final String type;
  final Map<String, dynamic> map;
  dynamic operator [](String key) => map[key];

  String get name => map['name'] as String;
  set name(String name) => map['name'] = name;

  @override
  String toString() => '$type${Map.of(map)..remove('type')}';
}

final class Parser extends Scanner {
  final locals = <Set<String>>[{}]; // tracks local variables

  /**
   * Constructs a new parser for the given [source] string.
   */
  Parser(super.source);

  /**
   * Parses the source and returns an AST node of type `block`.
   */
  AST parse() {
    final list = <AST>[];
    while (!atEnd()) {
      list.add(parseStmt());
    }
    return AST('block', {'list': list});
  }

  /**
   * Parses a single statement with an optional `if` or `unless` suffix.
   */
  AST parseStmt() {
    var stmt = parseSimpleStmt();
    if (!eol && at('if')) {
      final expr = parseExpr();
      stmt = AST('if', {
        'expr': expr,
        'then': AST('block', {
          'list': [stmt]
        }),
        'else': null
      });
    } else if (!eol && at('unless')) {
      final expr = parseExpr();
      stmt = AST('if', {
        'expr': AST('not', {'expr': expr}),
        'then': AST('block', {
          'list': [stmt]
        }),
        'else': null
      });
    }
    return stmt;
  }

  /**
   * Parses a single statement.
   *
   * Supports `module`, `class`, `def`, `if/elsif/else`, `while`, `break`, 
   * `next`, `return`, `for/in`, `case/when/else`, `alias`, `begin/end`, 
   * `begin/end while`, `begin/end until`, `attr_reader`, `attr_accessor`
   * and assignments.
   *
   * TODO: rescue and ensure inside of begin/end aren't correctly recognized.
   */
  AST parseSimpleStmt() {
    if (at('module')) {
      final name = parseName();
      return AST('module', {'name': name, 'block': parseBlock()});
    }
    if (at('class')) {
      return parseClassStmt();
    }
    if (at('def')) {
      return parseDefStmt();
    }
    if (at('if')) {
      return parseIfStmt();
    }
    if (at('while')) {
      return parseWhileStmt();
    }
    if (at('break')) {
      return AST('break', {});
    }
    if (at('next')) {
      return AST('next', {});
    }
    if (at('return')) {
      AST? expr;
      if (!eol && current != 'if' && current != 'unless') {
        expr = parseExpr();
      }
      return AST('return', {'expr': expr});
    }
    if (at('for')) {
      return parseForStmt();
    }
    if (at('case')) {
      return parseCaseStmt();
    }
    if (at('alias')) {
      final oldSym = parseSymbol();
      final newSym = parseSymbol();
      return AST('alias', {'old': oldSym, 'new': newSym});
    }
    if (at('attr_reader')) {
      return AST('attr_reader', {'list': parseSymbolList()});
    }
    if (at('attr_accessor')) {
      return AST('attr_accessor', {'list': parseSymbolList()});
    }
    if (at('begin')) {
      final block = parseBlock();
      if (!eol && at('while')) {
        final expr = parseExpr();
        return AST('dowhile', {'expr': expr, 'block': block});
      }
      if (!eol && at('until')) {
        final expr = parseExpr();
        return AST('dowhile', {
          'expr': AST('not', {'expr': expr}),
          'block': block
        });
      }
      return block;
    }
    if (at('rescue')) {
      // only inside begin
      return AST('rescue', {});
    }
    if (at('ensure')) {
      // only inside begin
      return AST('ensure', {});
    }
    return parseAssignment();
  }

  AST parseClassStmt() {
    final name = parseName();
    final superclass = at('<') ? parseExpr() : null;
    return AST('class', {'name': name, 'superclass': superclass, 'block': parseBlock()});
  }

  AST parseDefStmt() {
    locals.add({});
    var name = consume(); // name or operator
    String? classname;
    if (at('.')) {
      classname = name;
      name = consume(); // name or operator
    }
    var params = <AST>[];
    if (!eol && at('(')) {
      if (!at(')')) {
        params = parseParamList();
        expect(')');
      }
    }
    final block = parseBlock();
    locals.removeLast();
    return AST('def', {'name': name, 'classname': classname, 'params': params, 'block': block});
  }

  AST parseIfStmt() {
    final expr = parseExpr();
    at('then'); // skip optional then
    AST? thenBlock;
    AST? elseBlock;
    var list = <AST>[];
    while (!at('end')) {
      if (at('elsif')) {
        thenBlock = AST('block', {'list': list});
        list = [parseIfStmt()];
        break;
      } else if (at('else')) {
        thenBlock = AST('block', {'list': list});
        list = <AST>[];
      } else {
        list.add(parseStmt());
      }
    }
    if (thenBlock == null) {
      thenBlock = AST('block', {'list': list});
    } else {
      elseBlock = AST('block', {'list': list});
    }
    return AST('if', {'expr': expr, 'then': thenBlock, 'else': elseBlock});
  }

  AST parseWhileStmt() {
    final expr = parseExpr();
    at('do'); // skip optional do
    return AST('while', {'expr': expr, 'block': parseBlock()});
  }

  AST parseForStmt() {
    final target = parsePrimary(); // name of any kind
    trackLocal(target);
    expect('in');
    final expr = parseExpr();
    at('do'); // skip optional do
    return AST('for', {'target': target, 'expr': expr, 'block': parseBlock()});
  }

  AST parseCaseStmt() {
    final expr = parseExpr();
    final whens = <AST>[];
    while (at('when')) {
      final whenExpr = parseExprAsList();
      final whenList = <AST>[];
      while (current != 'when' && current != 'else' && current != 'end') {
        whenList.add(parseStmt());
      }
      whens.add(AST('when', {
        'exprList': whenExpr,
        'block': AST('block', {'list': whenList})
      }));
    }
    if (at('else')) {
      whens.add(AST('when', {
        'exprList': [
          AST('lit', {'value': true}),
        ],
        'block': parseBlock(),
      }));
    } else {
      expect('end');
    }
    return AST('case', {'expr': expr, 'whens': whens});
  }

  /**
   * Parses a simple expression, followed by an optional `=` assignment or
   * `+=` or `-=` operator. Also supports mass assignments. It collects all 
   * expressions separated by `,` into a single list expression.
   */
  AST parseAssignment() {
    var expr = parseSimpleExpr();
    if (at(',')) {
      var targetList = <AST>[expr, parseSimpleExpr()];
      while (at(',')) {
        targetList.add(parseSimpleExpr());
      }
      if (at('=')) {
        targetList = targetList.map((expr) {
          if (expr.type == 'mcall' && expr['expr'] == null && (expr['args'] as List<AST>).isEmpty) {
            locals.last.add(expr.name);
            return AST('var', {'name': expr.name});
          } else {
            return expr;
          }
        }).toList();
        final exprList = parseExprAsList();
        return AST('assignment', {'targetList': targetList, 'exprList': exprList});
      }
      return AST('listexpr', {'list': targetList});
    }
    if (at('=')) {
      // `expr` might have become an implicit mcall but is simply a new local variable
      // or if it is an explicit mcall, it's really a setter and not an assignment
      // or if it is an array access, it's really a setter and not an assignment
      if (expr.type == 'mcall') {
        if (expr['expr'] == null && (expr['args'] as List<AST>).isEmpty) {
          expr = AST('var', {'name': expr.name});
        } else if (expr['expr'] != null) {
          expr.name += '=';
          (expr['args'] as List<AST>).add(parseExpr());
          return expr;
        }
      }
      trackLocal(expr);
      final exprList = parseExprAsList();
      return AST('assignment', {
        'targetList': [expr],
        'exprList': exprList
      });
    }
    if (at('+=')) {
      if (expr.type == 'mcall') {
        return AST('mcall', {
          'expr': expr['expr'],
          'name': '${expr.name}=',
          'args': [
            AST('+', {'left': expr, 'right': parseExpr()}),
          ]
        });
      }
      return AST('+=', {'target': expr, 'expr': parseExpr()});
    }
    if (at('-=')) {
      if (expr.type == 'mcall') {
        return AST('mcall', {
          'expr': expr['expr'],
          'name': '${expr.name}=',
          'args': <AST>[
            AST('-', {'left': expr, 'right': parseExpr()}),
          ]
        });
      }
      return AST('-=', {'target': expr, 'expr': parseExpr()});
    }
    return expr;
  }

  /**
   * Parses a block of statements up to either `end` or the given [token].
   */
  AST parseBlock([String token = 'end']) {
    final list = <AST>[];
    while (!at(token)) {
      list.add(parseStmt());
    }
    return AST('block', {'list': list});
  }

  AST parseExpr() {
    return parseSimpleStmt(); // statements are expressions, too
  }

  /**
   * Parses an expression with the correct operator precedence.
   *
   *  - ternary if/then/else `?:`
   *  - range `..`, `...`
   *  - logical OR `||`
   *  - logical AND `&&`
   *  - equality, comparison and pattern matching `==`, `!=`, `<=>`, `===`, `=~`
   *  - comparisons `<`, `<=`, `>`, `>=`
   *  - bit shifting `<<`
   *  - addition `+` and subtraction `-`
   *  - multiplication `*`, division `/` and modulo `%`
   *  - unary operators `-`, `!`, `*`
   *  - index access `[]`
   *  - `::`name or `.`name
   *  - method and function calls (`mcall`)
   */
  AST parseSimpleExpr() {
    var expr = parseRange();
    if (at('?')) {
      final thenExpr = parseSimpleExpr();
      expect(':');
      final elseExpr = parseSimpleExpr();
      expr = AST('?:', {'expr': expr, 'then': thenExpr, 'else': elseExpr});
    }
    return expr;
  }

  AST parseRange() {
    var expr = parseOr();
    if (at('..')) {
      expr = AST('..', {'left': expr, 'right': parseOr()});
    }
    if (at('...')) {
      expr = AST('...', {'left': expr, 'right': parseOr()});
    }
    return expr;
  }

  AST parseOr() {
    var expr = parseAnd();
    while (at('||')) {
      expr = AST('||', {'left': expr, 'right': parseAnd()});
    }
    return expr;
  }

  AST parseAnd() {
    var expr = parseLogic();
    while (at('&&')) {
      expr = AST('&&', {'left': expr, 'right': parseLogic()});
    }
    return expr;
  }

  AST parseLogic() {
    var expr = parseComp();
    if (at('==')) {
      expr = AST('==', {'left': expr, 'right': parseComp()});
    }
    if (at('!=')) {
      expr = AST('!=', {'left': expr, 'right': parseComp()});
    }
    if (at('<=>')) {
      expr = AST('<=>', {'left': expr, 'right': parseComp()});
    }
    if (at('===')) {
      expr = AST('===', {'left': expr, 'right': parseComp()});
    }
    if (at('=~')) {
      expr = AST('=~', {'left': expr, 'right': parseComp()});
    }
    return expr;
  }

  AST parseComp() {
    var expr = parseShift();
    if (at('<')) {
      expr = AST('<', {'left': expr, 'right': parseShift()});
    }
    if (at('>')) {
      expr = AST('>', {'left': expr, 'right': parseShift()});
    }
    if (at('<=')) {
      expr = AST('<=', {'left': expr, 'right': parseShift()});
    }
    if (at('>=')) {
      expr = AST('>=', {'left': expr, 'right': parseShift()});
    }
    return expr;
  }

  AST parseShift() {
    var expr = parseTerm();
    while (at('<<')) {
      expr = AST('<<', {'left': expr, 'right': parseTerm()});
    }
    return expr;
  }

  AST parseTerm() {
    var expr = parseFactor();
    while (at('+')) {
      expr = AST('+', {'left': expr, 'right': parseFactor()});
    }
    while (at('-')) {
      expr = AST('-', {'left': expr, 'right': parseFactor()});
    }
    return expr;
  }

  AST parseFactor() {
    var expr = parseUnary();
    while (at('*')) {
      expr = AST('*', {'left': expr, 'right': parseUnary()});
    }
    while (at('/')) {
      expr = AST('/', {'left': expr, 'right': parseUnary()});
    }
    while (at('%')) {
      expr = AST('%', {'left': expr, 'right': parseUnary()});
    }
    return expr;
  }

  AST parseUnary() {
    if (at('-')) {
      return AST('neg', {'expr': parseUnary()});
    }
    if (at('!')) {
      return AST('not', {'expr': parseUnary()});
    }
    if (at('*')) {
      return AST('splat', {'expr': parseUnary()});
    }
    return parsePostfix(parsePrimary());
  }

  /**
   * Parses a function application, an index operation, a dereference 
   * operation, a `::`, or a `do/end` or `{}` block. The method tries to 
   * detect whether the application has omitted the parenthesis.
   * Returns a `[]`, `::`, `mcall`, or some other expression node.
   */
  AST parsePostfix(AST expr) {
    while (true) {
      if (eol) {
        break;
      }
      if (at('[')) {
        final args = parseExprAsList();
        expect(']');
        expr = AST('[]', {'expr': expr, 'args': args});
      } else if (at('::')) {
        expr = AST('::', {'expr': expr, 'name': parseName()});
      } else if (at('.')) {
        // <expr>.name(foo, ...) or <expr>.name foo, ...
        final name = parseName();
        List<AST> args;
        if (at('(')) {
          if (!at(')')) {
            args = parseExprAsList();
            expect(')');
          } else {
            args = [];
          }
        } else if (!eol && isPrimary()) {
          args = parseExprAsList();
        } else {
          args = [];
        }
        expr = AST('mcall', {'expr': expr, 'name': name, 'args': args});
      } else if (at('(')) {
        // <expr>(foo, ...)
        if (expr.type != 'var') {
          throw error('expected var but found $expr');
        }
        List<AST> list;
        if (!at(')')) {
          list = parseExprAsList();
          expect(')');
        } else {
          list = [];
        }
        expr = AST('mcall', {'expr': null, 'name': expr.name, 'args': list});
      } else if (isPrimary()) {
        // <expr> foo, ...
        if (expr.type != 'var') {
          throw error('expected var but found $expr');
        }
        final list = parseExprAsList();
        expr = AST('mcall', {'expr': null, 'name': expr.name, 'args': list});
      } else if (at('do')) {
        // <expr> do ... end
        expr = parseDoBlock(expr, 'end');
      } else if (at('{')) {
        // <expr> { ... }
        expr = parseDoBlock(expr, '}');
      } else {
        break;
      }
    }
    if (expr.type == 'var') {
      // for variables that aren't local vars assume a method call
      final name = expr.name;
      if (!isLocal(name)) {
        expr = AST('mcall', {'expr': null, 'name': name, 'args': <AST>[]});
      }
    }
    return expr;
  }

  /**
   * Parses a `do/end` or `{...}` block, based on [token].
   * Returns [expr] with an additional `doblock` node.
   */
  AST parseDoBlock(AST expr, String token) {
    if (expr.type != 'mcall') {
      throw error('expected mcall but found $expr');
    }
    locals.add({});
    List<AST> params;
    if (at('|')) {
      params = parseParamList();
      expect('|');
    } else {
      params = [];
    }
    return AST(expr.type, {
      ...expr.map,
      'doblock': AST('doblock', {'params': params, 'block': parseBlock(token)})
    });
  }

  /**
   * Returns true if the the current token is the start of a primary expression.
   * It is either a constant, a pseudo variable, a literal, a name, or a symbol.
   */
  bool isPrimary() {
    if (atEnd()) {
      return false;
    }
    if (const {'nil', 'true', 'false', 'self', 'super', '['}.contains(current)) {
      return true;
    }
    if (isKeyword()) {
      return false;
    }
    return RegExp(r'''^(\d+|[:$@]?\w+|"|'|/.)''').hasMatch(current);
  }

  /**
   * Parses a constant like `nil`, `true`, or `false`, a pseudo variable 
   * like `self` or `super`, an array constructor, a number, a string, or a
   * regular expression, an instance variable, a global variable or a local
   * variable (which might actually be an implicit method call).
   * Returns a `lit`, `relit`, `self`, `array`, `return`, `const`, `symbol`,
   * `var`, `instvar`, `globalvar`, or some other expression node.
   */
  AST parsePrimary() {
    if (at('(')) {
      final expr = parseExpr();
      expect(')');
      return expr;
    }
    if (at('nil')) {
      return AST('lit', {'value': null});
    }
    if (at('true')) {
      return AST('lit', {'value': true});
    }
    if (at('false')) {
      return AST('lit', {'value': false});
    }
    if (at('self')) {
      return AST('self', {});
    }
    if (at('super')) {
      //return AST({'type': 'super'});
      return AST('var', {'name': 'super'}); // TODO so it can be mcalled
    }
    if (at('[')) {
      var list = <AST>[];
      if (!at(']')) {
        list = parseExprAsList();
        expect(']');
      }
      return AST('array', {'args': list});
    }

    if (at('return')) {
      // TODO return as expression? Really?
      return AST('return', {'expr': null});
    }

    if (atEnd()) {
      throw error('unexpected end of input');
    }
    if (isKeyword()) {
      throw error('unexpected keyword $current');
    }
    if (RegExp(r'^\d+').hasMatch(current)) {
      return AST('lit', {'value': double.parse(consume())});
    }
    if (RegExp(r'^[A-Z]').hasMatch(current)) {
      return AST('const', {'name': consume()});
    }
    if (RegExp(r'^[a-z_]').hasMatch(current)) {
      return AST('var', {'name': consume()});
    }
    if (current[0] == '"' || current[0] == "'") {
      final v = consume();
      return AST('lit', {'value': v.substring(1, v.length - 1)});
    }
    if (current[0] == '/' && current.length > 1) {
      final v = consume();
      return AST('relit', {'value': v.substring(1, v.length - 1)});
    }
    if (current[0] == '@') {
      return AST('instvar', {'name': consume().substring(1)});
    }
    if (current[0] == '\$') {
      return AST('globalvar', {'name': consume().substring(1)});
    }
    if (current[0] == ':') {
      return AST('symbol', {'name': consume().substring(1)});
    }
    throw error('expected primary but found $current');
  }

  /**
   * Parses a single expression or a comma-separated list of expressions.
   * Returns a list of expression nodes.
   */
  List<AST> parseExprAsList() {
    final expr = parseExpr();
    if (expr.type == 'listexpr') {
      return expr['list'] as List<AST>;
    }
    return [expr];
  }

  /**
   * Parses a non-empty parameter list.
   * Returns a list of `param` or `restparam` nodes.
   */
  List<AST> parseParamList() {
    final list = <AST>[];
    list.add(parseParam());
    while (at(',')) {
      list.add(parseParam());
    }
    return list;
  }

  /**
   * Parses a parameter with an optional initializer or `*` indicating a rest parameter.
   * Returns a `param` or `restparam` nodes.
   */
  AST parseParam() {
    if (at('*')) {
      final name = parseName();
      locals.last.add(name);
      return AST('restparam', {'name': name});
    }
    final name = parseName();
    locals.last.add(name);
    final init = at('=') ? parseExpr() : null;
    return AST('param', {'name': name, 'init': init});
  }

  /**
   * Parses and returns a comma-separated list of symbols.
   */
  List<String> parseSymbolList() {
    final list = <String>[];
    list.add(parseSymbol());
    while (at(',')) {
      list.add(parseSymbol());
    }
    return list;
  }

  /**
   * Parses and returns a symbol or signals an error.
   * (Symbols starts with a `:`)
   */
  String parseSymbol() {
    if (RegExp(r'^:.').hasMatch(current)) {
      return consume().substring(1);
    }
    throw error('expected symbol but found $current');
  }

  /**
   * Parses and returns a name or signals an error.
   * (Names start with a letter)
   */
  String parseName() {
    if (RegExp(r'^\w').hasMatch(current)) {
      return consume();
    }
    throw error('expected name but found $current');
  }

  /**
   * Tracks a local variable if the given AST node is one.
   */
  void trackLocal(AST ast) {
    if (ast.type == 'var') {
      locals.last.add(ast.name);
    }
  }

  /**
   * Returns true if the name is a known local variable.
   * Used to distinguish local variable access from implicit method calls without parentheses.
   */
  bool isLocal(String name) {
    return locals.reversed.any((names) => names.contains(name));
  }
}
