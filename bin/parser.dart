// Copyright 2013 by Stefan Matthias Aust
part of rubyparser;

class Parser extends Scanner {
  List<Set<String>> locals = [new Set()]; // tracks local variables

  Parser(String source) : super(source);

  /**
   * Parses the source.
   */
  Map parse() {
    var list = [];
    while (!atEnd()) {
      list.add(parseStmt());
    }
    return {'type': 'block', 'list': list};
  }

  /**
   * Parses a single statement with an optional `if` or `unless` suffix.
   */
  Map parseStmt() {
    var stmt = parseSimpleStmt();
    if (!eol && at("if")) {
      var expr = parseExpr();
      stmt = {
        'type': 'if',
        'expr': expr,
        'then': {'type': 'block', 'list': [stmt]},
        'else': null
      };
    } else if (!eol && at("unless")) {
      var expr = parseExpr();
      stmt = {
        'type': 'if',
        'expr': {'type': 'not', 'expr': expr},
        'then': {'type': 'block', 'list': [stmt]},
        'else': null
      };
    }
    return stmt;
  }

  /**
   * Parses a single statement.
   *
   * Supports module, class, def, if/elsif/else, while, break, next, return, alias, for/in, case/when/else,
   * begin/end, begin/end while, begin/end until, alias, attr_reader, attr_accessor and assignments.
   *
   * TODO: rescue and ensure inside of begin/end aren't correctly recognized.
   */
  Map parseSimpleStmt() {
    if (at("module")) {
      var name = parseName();
      return {'type': 'module', 'name': name, 'block': parseBlock()};
    }
    if (at("class")) {
      return parseClassStmt();
    }
    if (at("def")) {
      return parseDefStmt();
    }
    if (at("if")) {
      return parseIfStmt();
    }
    if (at("while")) {
      return parseWhileStmt();
    }
    if (at("break")) {
      return {'type': 'break'};
    }
    if (at("next")) {
      return {'type': 'next'};
    }
    if (at("return")) {
      var expr = null;
      if (!eol && current != "if" && current != "unless") {
        expr = parseExpr();
      }
      return {'type': 'return', 'expr': expr};
    }
    if (at("for")) {
      return parseForStmt();
    }
    if (at("case")) {
      return parseCaseStmt();
    }
    if (at("alias")) {
      var oldSym = parseSymbol();
      var newSym = parseSymbol();
      return {'type': 'alias', 'old': oldSym, 'new': newSym};
    }
    if (at("attr_reader")) {
      return {'type': 'attr_reader', 'list': parseSymbolList()};
    }
    if (at("attr_accessor")) {
      return {'type': 'attr_accessor', 'list': parseSymbolList()};
    }
    if (at("begin")) {
      var block = parseBlock();
      if (!eol && at("while")) {
        var expr = parseExpr();
        return {'type': 'dowhile', 'expr': expr, 'block': block};
      }
      if (!eol && at("until")) {
        var expr = parseExpr();
        return {'type': 'dowhile', 'expr': {'type': 'not', 'expr': expr}, 'block': block};
      }
      return block;
    }
    if (at("rescue")) { // only inside begin
      return {'type': 'rescue'};
    }
    if (at("ensure")) { // only inside begin
      return {'type': 'ensure'};
    }
    return parseAssignment();
  }

  Map parseClassStmt() {
    var name = parseName();
    var superclass;
    if (at("<")) {
      superclass = parseExpr();
    } else {
      superclass = null;
    }
    return {
      'type': 'class',
      'name': name,
      'superclass': superclass,
      'block': parseBlock()};
  }

  Map parseDefStmt() {
    locals.add(new Set());
    var name = consume(); // name or operator
    var classname = null;
    if (at(".")) {
      classname = name;
      name = consume(); // name or operator
    }
    var params = [];
    if (!eol && at("(")) {
      if (!at(")")) {
        params = parseParamList();
        expect(")");
      }
    }
    var block = parseBlock();
    locals.removeLast();
    return {
      'type': 'def',
      'name': name,
      'classname': classname,
      'params': params,
      'block': block};
  }

  Map parseIfStmt() {
    var expr = parseExpr();
    at("then"); // skip optional then
    var thenBlock = null;
    var elseBlock = null;
    var list = [];
    while (!at("end")) {
      if (at("elsif")) {
        thenBlock = {'type': 'block', 'list': list};
        list = [parseIfStmt()];
        break;
      } else if (at("else")) {
        thenBlock = {'type': 'block', 'list': list};
        list = [];
      } else {
        list.add(parseStmt());
      }
    }
    if (thenBlock == null) {
      thenBlock = {'type': 'block', 'list': list};
    } else {
      elseBlock = {'type': 'block', 'list': list};
    }
    return {'type': 'if', 'expr': expr, 'then': thenBlock, 'else': elseBlock};
  }

  Map parseWhileStmt() {
    var expr = parseExpr();
    at("do"); // skip optional do
    return {'type': 'while', 'expr': expr, 'block': parseBlock()};
  }

  Map parseForStmt() {
    var target = parsePrimary(); // name of any kind
    trackLocal(target);
    expect("in");
    var expr = parseExpr();
    at("do"); // skip optional do
    return {'type': 'for', 'target': target, 'expr': expr, 'block': parseBlock()};
  }

  Map parseCaseStmt() {
    var expr = parseExpr();
    var whens = [];
    while (at("when")) {
      var whenExpr = parseExprAsList();
      var whenList = [];
      while (current != "when" && current != "else" && current != "end") {
        whenList.add(parseStmt());
      }
      whens.add({'type': 'when', 'exprList': whenExpr, 'block': {'type': 'block', 'list': whenList}});
    }
    if (at("else")) {
      whens.add({'type': 'when', 'exprList': [{'type': 'lit', 'value': true}], 'block': parseBlock()});
    } else {
      expect("end");
    }
    return {'type': 'case', 'expr': expr, 'whens': whens};
  }

  /**
   * Parses a simple expression, followed by an optional assignment or += or -= operator.
   * Also supports mass assignments. It collects all expressions separated by `,` into
   * a single list expression.
   */
  Map parseAssignment() {
    var expr = parseSimpleExpr();
    if (at(",")) {
      List<Map> targetList = [expr, parseSimpleExpr()];
      while (at(",")) {
        targetList.add(parseSimpleExpr());
      }
      if (at("=")) {
        targetList = targetList.map((expr) {
          if (expr['type'] == 'mcall' && expr['expr'] == null && expr['args'].length == 0) {
            locals.last.add(expr['name']);
            return {'type': 'var', 'name': expr['name']};
          } else {
            return expr;
          }
        }).toList();
        List<Map> exprList = parseExprAsList();
        return {'type': 'assignment', 'targetList': targetList, 'exprList': exprList};
      }
      return {'type': 'listexpr', 'list': targetList};
    }
    if (at("=")) {
      // `expr` might have become an implicit mcall but is simply a new local variable
      // or if it is an explicit mcall, it's really a setter and not an assignment
      // or if it is an array access, it's really a setter and not an assignment
      if (expr['type'] == 'mcall') {
        if (expr['expr'] == null && expr['args'].length == 0) {
          expr = {'type': 'var', 'name': expr['name']};
        } else if (expr['expr'] != null) {
          expr['name'] += "=";
          expr['args'].add(parseExpr());
          return expr;
        }
      }
      trackLocal(expr);
      List<Map> exprList = parseExprAsList();
      return {'type': 'assignment', 'targetList': [expr], 'exprList': exprList};
    }
    if (at("+=")) {
      if (expr['type'] == 'mcall') {
        return {
          'type': 'mcall',
          'expr': expr['expr'],
          'name': expr['name'] + "=",
          'args': [{'type': '+', 'left': expr, 'right': parseExpr()}]};
      }
      return {'type': '+=', 'target': expr, 'expr': parseExpr()};
    }
    if (at("-=")) {
      if (expr['type'] == 'mcall') {
        return {
          'type': 'mcall',
          'expr': expr['expr'],
          'name': expr['name'] + "=",
          'args': [{'type': '-', 'left': expr, 'right': parseExpr()}]};
      }
      return {'type': '-=', 'target': expr, 'expr': parseExpr()};
    }
    return expr;
  }

  /**
   * Parses a block of statements up to either `end` or the given token.
   */
  Map parseBlock([token="end"]) {
    var list = [];
    while (!at(token)) {
      list.add(parseStmt());
    }
    return {'type': 'block', 'list': list};
  }


  Map parseExpr() {
    return parseSimpleStmt(); // statements are expressions, too
  }

  /**
   * Parses an expression with the correct operator precedence.
   */
  Map parseSimpleExpr() {
    var expr = parseRange();
    if (at("?")) {
      var thenExpr = parseSimpleExpr();
      expect(":");
      var elseExpr = parseSimpleExpr();
      expr = {'type': '?:', 'expr': expr, 'then': thenExpr, 'else': elseExpr};
    }
    return expr;
  }

  Map parseRange() {
    var expr = parseOr();
    if (at("..")) {
      expr = {'type': '..', 'left': expr, 'right': parseOr()};
    }
    if (at("...")) {
      expr = {'type': '...', 'left': expr, 'right': parseOr()};
    }
    return expr;
  }

  Map parseOr() {
    var expr = parseAnd();
    while (at("||")) {
      expr = {'type': '||', 'left': expr, 'right': parseAnd()};
    }
    return expr;
  }

  Map parseAnd() {
    var expr = parseLogic();
    while (at("&&")) {
      expr = {'type': '&&', 'left': expr, 'right': parseLogic()};
    }
    return expr;
  }

  Map parseLogic() {
    var expr = parseComp();
    if (at("==")) {
      expr = {'type': '==', 'left': expr, 'right': parseComp()};
    }
    if (at("!=")) {
      expr = {'type': '!=', 'left': expr, 'right': parseComp()};
    }
    if (at("<=>")) {
      expr = {'type': '<=>', 'left': expr, 'right': parseComp()};
    }
    if (at("===")) {
      expr = {'type': '===', 'left': expr, 'right': parseComp()};
    }
    if (at("=~")) {
      expr = {'type': '=~', 'left': expr, 'right': parseComp()};
    }
    return expr;
  }

  Map parseComp() {
    var expr = parseShift();
    if (at("<")) {
      expr = {'type': '<', 'left': expr, 'right': parseShift()};
    }
    if (at(">")) {
      expr = {'type': '>', 'left': expr, 'right': parseShift()};
    }
    if (at("<=")) {
      expr = {'type': '<=', 'left': expr, 'right': parseShift()};
    }
    if (at(">=")) {
      expr = {'type': '>=', 'left': expr, 'right': parseShift()};
    }
    return expr;
  }

  Map parseShift() {
    var expr = parseTerm();
    while (at("<<")) {
      expr = {'type': '<<', 'left': expr, 'right': parseTerm()};
    }
    return expr;
  }

  Map parseTerm() {
    var expr = parseFactor();
    while (at("+")) {
      expr = {'type': '+', 'left': expr, 'right': parseFactor()};
    }
    while (at("-")) {
      expr = {'type': '-', 'left': expr, 'right': parseFactor()};
    }
    return expr;
  }

  Map parseFactor() {
    var expr = parseUnary();
    while (at("*")) {
      expr = {'type': '*', 'left': expr, 'right': parseUnary()};
    }
    while (at("/")) {
      expr = {'type': '/', 'left': expr, 'right': parseUnary()};
    }
    while (at("%")) {
      expr = {'type': '%', 'left': expr, 'right': parseUnary()};
    }
    return expr;
  }

  Map parseUnary() {
    if (at("-")) {
      return {'type': 'neg', 'expr': parseUnary()};
    }
    if (at("!")) {
      return {'type': 'not', 'expr': parseUnary()};
    }
    if (at("*")) {
      return {'type': 'splat', 'expr': parseUnary()};
    }
    return parsePostfix(parsePrimary());
  }

  /**
   * Parses a function application, an index operation, a dereference operation, a `::`
   * or a do/end or {} block. It tries to detect whether the application has omitted the
   * parenthesis.
   */
  Map parsePostfix(Map expr) {
    while (true) {
      if (eol) {
        break;
      }
      if (at("[")) {
        List<Map> args = parseExprAsList();
        expect("]");
        expr = {'type': '[]', 'expr': expr, 'args': args};
      } else if (at("::")) {
        expr = {'type': '::', 'expr': expr, 'name': parseName()};
      } else if (at(".")) {
        var name = parseName();
        List<Map> args;
        if (at("(")) {
          if (!at(")")) {
            args = parseExprAsList();
            expect(")");
          } else {
            args = [];
          }
        } else if (!eol && isPrimary()) {
          args = parseExprAsList();
        } else {
          args = [];
        }
        expr = {'type': 'mcall', 'expr': expr, 'name': name, 'args': args};
      } else if (at("(")) {
        if (expr['type'] != 'var') {
          error("expected var but found $expr");
        }
        List<Map> list;
        if (!at(")")) {
          list = parseExprAsList();
          expect(")");
        } else {
          list = [];
        }
        expr = {'type': 'mcall', 'expr': null, 'name': expr['name'], 'args': list};
      } else if (isPrimary()) {
        if (expr['type'] != 'var') {
          error("expected var but found $expr");
        }
        List<Map> list = parseExprAsList();
        expr = {'type': 'mcall', 'expr': null, 'name': expr['name'], 'args': list};
      } else if (at("do")) {
        expr = parseDoBlock(expr, "end");
      } else if (at("{")) {
        expr = parseDoBlock(expr, "}");
      } else {
        break;
      }
    }
    if (expr['type'] == 'var') {
      var name = expr['name'];
      if (!isLocal(name)) {
        expr = {'type': 'mcall', 'expr': null, 'name': name, 'args': []};
      }
    }
    return expr;
  }

  /**
   * Parses a `do/end` or `{...}` block.
   */
  Map parseDoBlock(Map expr, String token) {
    if (expr['type'] != 'mcall') {
      error("expected mcall but found $expr");
    }
    locals.add(new Set());
    List<Map> params;
    if (at("|")) {
      params = parseParamList();
      expect("|");
    } else {
      params = [];
    }
    expr['doblock'] = {'type': 'doblock', 'params': params, 'block': parseBlock(token)};
    locals.removeLast();
    return expr;
  }

  /**
   * Returns true if the the current token is the start of a primary expression.
   * It is either a constant, a pseudo variable, a litera or a name or symbol.
   */
  bool isPrimary() {
    if (atEnd()) {
      return false;
    }
    if (["nil", "true", "false", "self", "super", "["].contains(current)) {
      return true;
    }
    if (isKeyword()) {
      return false;
    }
    return new RegExp(r'''^(\d+|[:$@]?\w+|"|'|/.)''').hasMatch(current);
  }

  /**
   * Parses a constant like nil, true or false, a pseudo variable like self or super,
   * an array constructor, a number, a string or regular expression, an instance variable,
   * a global variable or a local variable (which might really be an implicit method call).
   */
  Map parsePrimary() {
    if (at("(")) {
      var expr = parseExpr();
      expect(")");
      return expr;
    }
    if (at("nil")) {
      return {'type': 'lit', 'value': null};
    }
    if (at("true")) {
      return {'type': 'lit', 'value': true};
    }
    if (at("false")) {
      return {'type': 'lit', 'value': false};
    }
    if (at("self")) {
      return {'type': 'self'};
    }
    if (at("super")) {
      //return {'type': 'super'};
      return {'type': 'var', 'name': 'super'}; // TODO so it can be mcalled
    }
    if (at("[")) {
      List<Map> list = [];
      if (!at("]")) {
        list = parseExprAsList();
        expect("]");
      }
      return {'type': 'array', 'args': list};
    }

    if (at("return")) { // TODO return as expression? Really?
      return{'type': 'return', 'expr': null};
    }

    if (atEnd()) {
      error("unexpected end of input");
    }
    if (isKeyword()) {
      error("unexpected keyword $current");
    }
    if (new RegExp(r"^\d+").hasMatch(current)) {
      return {'type': 'lit', 'value': double.parse(consume())};
    }
    if (new RegExp(r"^[A-Z]").hasMatch(current)) {
      return {'type': 'const', 'name': consume()};
    }
    if (new RegExp(r"^[a-z_]").hasMatch(current)) {
      return {'type': 'var', 'name': consume()};
    }
    if (current[0] == '"' || current[0] == "'") {
      return {'type': 'lit', 'value': consume().slice(1, -1)};
    }
    if (current[0] == '/' && current.length > 1) {
      return {'type': 'relit', 'value': consume().slice(1, -1)};
    }
    if (current[0] == '@') {
      return {'type': 'instvar', 'name': consume().slice(1)};
    }
    if (current[0] == '\$') {
      return {'type': 'globalvar', 'name': consume().slice(1)};
    }
    if (current[0] == ':') {
      return {'type': 'symbol', 'name': consume().slice(1)};
    }
    error("expected primary but found ${current}");
  }

  /**
   * Parses a single expression or a comma-separated list of expressions.
   */
  List<Map> parseExprAsList() {
    var expr = parseExpr();
    if (expr['type'] == 'listexpr') {
      return expr['list'];
    }
    return [expr];
  }

  /**
   * Parses a non-empty parameter list.
   */
  List<Map> parseParamList() {
    List<Map> list = [];
    list.add(parseParam());
    while (at(",")) {
      list.add(parseParam());
    }
    return list;
  }

  /**
   * Parses a parameter with an optional initializer or `*` indicating a rest parameter.
   */
  Map parseParam() {
    if (at("*")) {
      var name = parseName();
      locals.last.add(name);
      return {'type': 'restparam', 'name': name};
    }
    var name = parseName();
    locals.last.add(name);
    var init = null;
    if (at("=")) {
      init = parseExpr();
    }
    return {'type': 'param', 'name': name, 'init': init};
  }

  /**
   * Parses a comma-separated list of symbols.
   */
  List<String> parseSymbolList() {
    var list = [];
    list.add(parseSymbol());
    while (at(",")) {
      list.add(parseSymbol());
    }
    return list;
  }

  /**
   * Parses a symbol or signals an error.
   */
  String parseSymbol() {
    if (new RegExp(r"^:.").hasMatch(current)) {
      return consume().slice(1);
    }
    error("expected symbol but found ${current}");
  }

  /**
   * Parses a name or signals an error.
   */
  String parseName() {
    if (new RegExp(r"^\w").hasMatch(current)) {
      return consume();
    }
    error("expected name but found ${current}");
  }

  /**
   * Tracks a local variable if the given AST node is one.
   */
  void trackLocal(Map ast) {
    if (ast['type'] == 'var') {
      locals.last.add(ast['name']);
    }
  }

  /**
   * Returns true, if the name is a known local variable.
   * Used to distinguish local variable access from implicit method calls without parentheses.
   */
  bool isLocal(String name) {
    for (int i = locals.length - 1; i >= 0; --i) {
      if (locals[i].contains(name)) {
        return true;
      }
    }
    return false;
  }
}
