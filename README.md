A Ruby Parser written in Dart
=============================

In 2013, even before the release of [Dart](https://dart.dev/) 1.0, I wrote a
parser for a large subset of Ruby. In 2021 I rediscovered this project and
ported it to sound null-safe Dart 2.12.

I used the parser to port some 1700 lines of Ruby to Dart, porting [an old
play by email game](https://github.com/sma/rainbowsend) for which I created
a Ruby version in 2001.

Details
-------
The `parse` method of class `Parser` creates an AST, now represented by a
class of the same name, but originally just a `Map`, where an required `type`
property denotes the type of the abstract syntax tree node and where depending
on that type there are other properties that contain strings, other AST nodes,
or list of such types. This is very dynamic and I didn't attempt to rewrite
this to use dedicated classes. It should be certainly possible. When Dart was
a dynamic language, it looked like a good idea to save the tideous work of
creating 100+ little classes, I guess.

Currently, there is only a _pretty printer_ that can emit the AST both in Ruby
syntax and in somewhat Dart-like syntax which I then probably used for manually
fixing the remaining syntax problems to get a working Dart application. I also
ported that converted code to sound null-safety, but I didn't checked whether
it still runs.

With the same technique the printer uses, one could also create a simple Ruby
interpreter which evaluates AST nodes recursively. It would require a bit of
runtime system because Ruby objects and classes behave differently as Dart
classes (at least if you don't use mirrors), if I recall correctly.

It has been a long time since I last used Ruby and therefore, I cannot really
tell how complete the parser is. Looking that the git history, it seems I
wrote it in just two days, so I doubt it will be complete.

For fun, I added a partial implementation of a AST evaluator, see `eval.dart`,
that is able to execute the fibonacci function and print its result. It
demonstrates nicely how slow the evaluator is.
