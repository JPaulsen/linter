// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N use_setters_to_change_a_property`

class A {
  // ignore: unused_field
  int _x = 0;
  void setX(int x) { // LINT
    this._x = x;
  }
}
