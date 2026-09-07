import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

class AppScopes {
  const AppScopes._();

  static const String session = 'session';
}

class SessionScope {
  const SessionScope(this._locator);

  final GetIt _locator;

  bool get isOpen => _locator.hasScope(AppScopes.session);

  Future<void> open(void Function(GetIt scope) register) async {
    await close();
    _locator.pushNewScope(scopeName: AppScopes.session, init: register);
  }

  Future<void> close() async {
    if (isOpen) {
      await _locator.dropScope(AppScopes.session);
    }
  }
}
