// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.unnecessary_brace_in_string_interps;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const desc = 'Avoid using braces in interpolation when not needed.';

const details = r'''
**AVOID** using braces in interpolation when not needed.

If you're just interpolating a simple identifier, and it's not immediately
followed by more alphanumeric text, the `{}` can and should be omitted.

**GOOD:**
```dart
print("Hi, $name!");
```

**BAD:**
```dart
print("Hi, ${name}!");
```
''';

final RegExp identifierPart = new RegExp(r'^[a-zA-Z0-9_]');

bool isIdentifierPart(Token token) =>
    token is StringToken && token.lexeme.startsWith(identifierPart);

bool _isInterpolationExpression(AstNode node) =>
    node is InterpolationExpression;

class UnnecessaryBraceInStringInterps extends LintRule {
  UnnecessaryBraceInStringInterps()
      : super(
            name: 'unnecessary_brace_in_string_interps',
            description: desc,
            details: details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  LintRule rule;
  Visitor(this.rule);

  @override
  visitStringInterpolation(StringInterpolation node) {
    node.elements
        .where(_isInterpolationExpression)
        .forEach(_visitInterpolationExpression);
  }

  void _visitInterpolationExpression(InterpolationExpression node) {
    final identifier = node.expression;
    if (identifier is SimpleIdentifier) {
      Token bracket = node.rightBracket;
      if (bracket != null &&
          !isIdentifierPart(bracket.next) &&
          identifier.name.indexOf('\$') == -1) {
        rule.reportLint(node);
      }
    }
  }
}
