// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.initialize_field_in_declaration_if_possible;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Initialize fields at their declaration when possible.';

const _details = r'''

**DO** initialize fields at their declaration when possible.

**BAD:**
```
class Folder {
  final String name;
  final List<Document> contents;

  Folder(this.name) : contents = [];
  Folder.temp() : name = 'temporary'; // Oops! Forgot contents.
}
```

**GOOD:**
```
class Folder {
  final String name;
  final List<Document> contents = [];

  Folder(this.name);
  Folder.temp() : name = 'temporary';
}
```

''';

Iterable<AssignmentExpression> _getAssignmentExpressionsInConstructorBody(
    ConstructorDeclaration node) {
  final body = node.body;
  final statements =
      (body is BlockFunctionBody) ? body.block.statements : <Statement>[];
  return statements
      .where((e) => e is ExpressionStatement)
      .map((e) => (e as ExpressionStatement).expression)
      .where((e) => e is AssignmentExpression)
      .map((e) => e as AssignmentExpression);
}

Iterable<ConstructorFieldInitializer>
    _getConstructorFieldInitializersInInitializers(
        ConstructorDeclaration node) {
  return node.initializers
      .where((e) => e is ConstructorFieldInitializer)
      .map((e) => (e as ConstructorFieldInitializer));
}

Iterable<ConstructorDeclaration> _getConstructors(ClassDeclaration node) {
  return node.members
      .where((e) => e is ConstructorDeclaration)
      .map((e) => e as ConstructorDeclaration);
}

List<FieldElement> _getFieldElements(ClassDeclaration node) {
  final fieldElements = <FieldElement>[];
  node.members.where((e) => e is FieldDeclaration).forEach((e) {
    (e as FieldDeclaration).fields.variables.forEach((e) {
      fieldElements.add(e.element);
    });
  });
  return fieldElements;
}

Iterable<Element> _getFieldElementsInParameters(
        ConstructorDeclaration constructor) =>
    constructor.parameters.parameters
        .where((e) => e is FieldFormalParameter)
        .map((e) =>
            ((e.identifier.bestElement) as FieldFormalParameterElement).field);

HashMap<Element, Literal> _getFieldLiteralMap(ClassDeclaration node) {
  final ans = new HashMap<Element, Literal>();
  _getFieldElements(node).forEach((e) => ans[e] = null);
  return ans;
}

HashMap<Element, AstNode> _getFieldNodeMap(ClassDeclaration node) {
  final ans = new HashMap<Element, AstNode>();
  node.members.where((e) => e is FieldDeclaration).forEach((e) {
    (e as FieldDeclaration).fields.variables.forEach((e) {
      ans[e.element] = e;
    });
  });
  return ans;
}

Element _getLeftElement(AssignmentExpression assignment) {
  final leftPart = assignment.leftHandSide;
  return leftPart is SimpleIdentifier
      ? leftPart.bestElement
      : leftPart is PropertyAccess ? leftPart.propertyName.bestElement : null;
}

Iterable<Element> _getOptionalFieldElementsInParameters(
        ConstructorDeclaration constructor) =>
    constructor.parameters.parameters
        .where((e) => e is DefaultFormalParameter)
        .map((e) => (e as DefaultFormalParameter).parameter)
        .where((e) => e is FieldFormalParameter)
        .map((e) =>
            ((e.identifier.bestElement) as FieldFormalParameterElement).field);

void _operateKeyAndValue(HashMap<Element, Literal> fieldLiteralMap, Element key,
    Expression expression) {
  if (key == null || expression == null || !fieldLiteralMap.containsKey(key)) {
    return;
  }
  if (expression is StringInterpolation) {
    fieldLiteralMap.remove(key);
  } else if (expression is AdjacentStrings) {
    fieldLiteralMap.remove(key);
  } else if (expression is Literal) {
    fieldLiteralMap[key] ??= expression;
    if (fieldLiteralMap[key] != expression) {
      fieldLiteralMap.remove(key);
    }
  } else {
    fieldLiteralMap.remove(key);
  }
}

class InitializeFieldInDeclarationIfPossible extends LintRule {
  _Visitor _visitor;
  InitializeFieldInDeclarationIfPossible()
      : super(
            name: 'initialize_field_in_declaration_if_possible',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  visitClassDeclaration(ClassDeclaration node) {
    final fieldLiteralMap = _getFieldLiteralMap(node);
    final fieldNodeMap = _getFieldNodeMap(node);
    final constructors = _getConstructors(node);
    for (var constructor in constructors) {
      _getFieldElementsInParameters(constructor)
          .forEach(fieldLiteralMap.remove);
      _getOptionalFieldElementsInParameters(constructor)
          .forEach(fieldLiteralMap.remove);
      _getAssignmentExpressionsInConstructorBody(constructor).forEach((e) {
        _operateKeyAndValue(
            fieldLiteralMap, _getLeftElement(e), e.rightHandSide);
      });
      _getConstructorFieldInitializersInInitializers(constructor).forEach((e) {
        _operateKeyAndValue(
            fieldLiteralMap, e.fieldName.bestElement, e.expression);
      });
    }
    fieldLiteralMap.keys
        .where((key) => fieldLiteralMap[key] != null)
        .map((key) => fieldNodeMap[key])
        .forEach(rule.reportLint);
  }
}
