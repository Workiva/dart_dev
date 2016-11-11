library analyze_lints;

class BaseClass {
  void doSomeStuff(bool ifTrue) {

  }

  void doSomeOtherStuff() {

  }
}

class ExtendoClass extends BaseClass {
  void doSomeStuff(bool ifTrue) {
    // yuno @override?
  }

  @override
  void doSomeOtherStuff() {

  }
}