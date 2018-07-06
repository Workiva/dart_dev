/// Throws an Exception if the current Dart process is not running in checked
/// mode.
void assertCheckedModeEnabled() {
  bool checked = false;
  try {
    dynamic s = 'not an int';
    int i = s;
  } catch (_) {
    checked = true;
  }
  if (!checked) {
    throw new Exception('Dart is not running in checked mode!');
  }
}
