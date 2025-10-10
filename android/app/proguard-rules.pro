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
