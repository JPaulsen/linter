// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N annotate_object_instead_of_dynamic_to_indicate_any_object_is_accepted`

void bad1(Object objectArg) { // LINT
  if (objectArg is A) {
    objectArg.foo();
  }
}

void bad2(Object objectArg) { // LINT
  (objectArg as A).foo();
}

void bad3(dynamicArg) { // LINT
  print(dynamicArg.toString());
}

class A {
  void foo() {}
}
