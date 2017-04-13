// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.recursive_getters;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Property getter recursivlely returns itself.';

const _details = r'''

**DON'T** Return the property itself in a getter body, this can be due to a typo.

**BAD:**
```
  int get field => field; // LINT
```

**BAD:**
```
  int get otherField {
    return otherField; // LINT
  }
```

**GOOD:**
```
  int get field => _field;
```

''';

class RecursiveGetters extends LintRule {
  _Visitor _visitor;

  RecursiveGetters()
      : super(
            name: 'recursive_getters',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class VerifyElementVisitor extends RecursiveAstVisitor {
  final ExecutableElement element;
  final LintRule rule;

  VerifyElementVisitor(this.element, this.rule);
  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.bestElement == element) {
      rule.reportLint(node);
    }
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // getters have null arguments, methods have parameters, could be empty.
    if (node.functionExpression.parameters != null) {
      return;
    }

    final element = node.element;
    _verifyElement(node.functionExpression, element);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // getters have null arguments, methods have parameters, could be empty.
    if (node.parameters != null) {
      return;
    }

    final element = node.element;
    _verifyElement(node.body, element);
  }

  void _verifyElement(AstNode node, ExecutableElement element) {
    final visitor = new VerifyElementVisitor(element, rule);
    node.accept(visitor);
  }
}
