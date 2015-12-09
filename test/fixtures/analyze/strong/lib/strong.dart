library analyze_strong;

import 'dart:collection';

class MyList extends ListBase<int> implements List {
   Object length;

   MyList(this.length);

   operator[](index) => "world";
   operator[]=(index, value) {}
}
