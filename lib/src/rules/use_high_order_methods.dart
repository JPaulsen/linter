// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.use_high_order_methods;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r' ';

const _details = r'''

**DO** ...

**BAD:**
```

```

**GOOD:**
```

```

''';

class UseHighOrderMethods extends LintRule {
  _Visitor _visitor;
  UseHighOrderMethods() : super(
          name: 'use_high_order_methods',
            description: _desc,
            details: _details,
            group: Group.style){
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  visitForEachStatement(ForEachStatement node) {
    rule.reportLint(node);
  }
}
