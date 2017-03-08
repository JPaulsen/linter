// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N initialize_field_in_declaration_if_possible`

class Folder {
  int a, b;
  String name;
  final List contents; // LINT

  Folder(this.name) : contents = [];

}

class Folder2 {
  int a, b;
  String name = 'temporary';
  final List contents = [];

  Folder2(name) : this.name = name;
  Folder2.foo();
  Folder2.bar();
}

class Folder3 {
  String name;
  List contents; // LINT

  Folder3(this.name) {
    contents = [];
  }

}
