// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N use_high_order_methods`

void main() {
  Iterable<String> iterable = ['1','2','3','4'];
  for (String string in iterable) { // LINT
    print(string);
  }

  iterable.forEach(print); // OK
}