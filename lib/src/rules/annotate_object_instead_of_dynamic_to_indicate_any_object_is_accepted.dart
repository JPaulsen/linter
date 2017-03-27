// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.annotate_object_instead_of_dynamic_to_indicate_any_object_is_accepted;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc =
    r'Annotate with Object instead of dynamic to indicate any object is accepted.';

const _details = r'''

**DO** annotate with Object instead of dynamic to indicate any object is accepted.

**BAD:**
```
void log(dynamicParameter) {
  print(dynamicParameter.toString());
}

bool convertToBool(Object arg) {
  if (arg is bool) return arg;
  if (arg is String) return arg == 'true';
  throw new ArgumentError('Cannot convert $arg to a bool.');
}
```

**GOOD:**
```
// Accepts any object.
void log(Object object) {
  print(object.toString());
}

// Only accepts bool or String, which can't be expressed in a type annotation.
bool convertToBool(arg) {
  if (arg is bool) return arg;
  if (arg is String) return arg == 'true';
  throw new ArgumentError('Cannot convert $arg to a bool.');
}
```

''';

Element _getLeftElementFromCastingExpression(AstNode node) {
  if (node is IsExpression) {
    return DartTypeUtilities.getCanonicalElementFromIdentifier(node.expression);
  }
  if (node is AsExpression) {
    return DartTypeUtilities.getCanonicalElementFromIdentifier(node.expression);
  }
  return null;
}

bool _isDynamic(FormalParameter parameter) =>
    parameter.element.type.name == 'dynamic';

bool _isNotNull(Object object) {
  return object != null;
}

bool _isObject(FormalParameter parameter) =>
    DartTypeUtilities.isClass(parameter.element.type, 'Object', 'dart.core');

class AnnotateObjectInsteadOfDynamicToIndicateAnyObjectIsAccepted
    extends LintRule {
  _Visitor _visitor;
  AnnotateObjectInsteadOfDynamicToIndicateAnyObjectIsAccepted()
      : super(
            name:
                'annotate_object_instead_of_dynamic_to_indicate_any_object_is_accepted',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _ElementBox {
  Element element;
  FormalParameter node;
  _ElementBox.fromElement(this.element);
  _ElementBox.fromParameter(this.node) {
    element = node.element;
  }
  @override
  int get hashCode => element.hashCode;

  @override
  operator ==(other) => other is _ElementBox && other.element == element;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    _visitFunctionBody(node.parameters?.parameters, node.body);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    _visitFunctionBody(node.functionExpression.parameters?.parameters,
        node.functionExpression.body);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    _visitFunctionBody(node.parameters?.parameters, node.body);
  }

  void _visitFunctionBody(
      NodeList<FormalParameter> parameters, FunctionBody body) {
    if (parameters == null) {
      return;
    }
    final objectParameters = parameters
        .where(_isObject)
        .map((e) => new _ElementBox.fromParameter(e))
        .toSet();
    final dynamicParameters = parameters
        .where(_isDynamic)
        .map((e) => new _ElementBox.fromParameter(e))
        .toSet();

    if (objectParameters.isEmpty && dynamicParameters.isEmpty) {
      return;
    }

    final castedElements = DartTypeUtilities
        .traverseNodesInDFS(body)
        .map(_getLeftElementFromCastingExpression)
        .where(_isNotNull)
        .map((e) => new _ElementBox.fromElement(e))
        .toSet();

    void reportLint(_ElementBox box) {
      rule.reportLint(box.node);
    }

    objectParameters.intersection(castedElements).forEach(reportLint);
    dynamicParameters.difference(castedElements).forEach(reportLint);
  }
}
