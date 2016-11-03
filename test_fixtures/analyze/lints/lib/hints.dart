library analyze_hints;

class BaseClass {
  void doSomeStuff(bool ifTrue) {

  }
}

class ExtendoClass extends BaseClass {
  void doSomeStuff(bool ifTrue) {
    // yuno @override?
  }
}