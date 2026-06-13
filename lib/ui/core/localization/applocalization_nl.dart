import 'applocalization.dart';

class AppLocalizationNl extends AppLocalization {
  static const _nl = <String, String>{
    'close': 'Sluiten',
    'confirm': 'Bevestigen',
  };

  @override
  Map<String, String> get strings => _nl;
}