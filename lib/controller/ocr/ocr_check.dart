export 'ocr_check_stub.dart'
  if (dart.library.io) 'ocr_check_mobile.dart'
  if (dart.library.html) 'ocr_check_web_windows.dart';
