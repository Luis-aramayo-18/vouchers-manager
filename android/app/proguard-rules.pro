# Reglas necesarias para evitar que R8 elimine las clases de ML Kit
# que son referenciadas internamente por el plugin google_mlkit_text_recognition.

# Mantener las opciones de los reconocedores de texto que R8 reportó como faltantes
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }

# Regla general recomendada para todas las dependencias de ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.firebase.ml.** { *; }
-keep class com.google.mlkit.vision.** { *; }

# ProGuard rules for Google ML Kit Text Recognition (needed when using specific language models)

# Keep the ML Kit interfaces and options that are called reflectively/dynamically.

-keep class com.google.mlkit.vision.text.TextRecognizerOptions {
*;
}

# Keep the base implementation classes for the language-specific options,
# even if you are not using all of them. R8 requires them for the initialize function.

-keep class com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions {
*;
}
-keep class com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder {
*;
}
-keep class com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions {
*;
}
-keep class com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder {
*;
}
-keep class com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions {
*;
}
-keep class com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder {
*;
}
-keep class com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions {
*;
}
-keep class com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder {
*;
}