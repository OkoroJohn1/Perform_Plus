# google_mlkit_text_recognition's plugin code references every script's
# options class (Chinese/Devanagari/Japanese/Korean) from a single shared
# `TextRecognizer.initialize` method, even though this app only ever
# requests `TextRecognitionScript.latin` (see result_slip_ocr_service.dart).
# Those other scripts' model artifacts aren't on the classpath at all, so
# R8 fails release minification with "missing class" errors unless told
# these are genuinely unused, not an accidental omission.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
