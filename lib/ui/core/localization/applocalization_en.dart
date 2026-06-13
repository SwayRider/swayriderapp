import 'applocalization.dart';

class AppLocalizationEn  extends AppLocalization {
  static const _en = <String, String>{
    'close': 'Close',
    'confirm': 'Confirm',
  };

  @override
  Map<String, String> get strings => _en;
}