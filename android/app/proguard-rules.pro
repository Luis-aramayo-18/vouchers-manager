# Reglas necesarias para Google ML Kit Text Recognition.
# Estas reglas aseguran que los idiomas de reconocimiento que no estás
# usando directamente (como chino, japonés, etc.) no sean eliminados
# por R8/ProGuard.

# Mantener todos los módulos de idiomas de reconocimiento de texto
# aunque no se inicialicen explícitamente en Dart.
-keep class com.google.mlkit.vision.text.** { *; }

# Mantener las opciones específicas de reconocimiento de idiomas
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }

# Mantener las clases base del TextRecognizer
-keep class com.google.mlkit.vision.text.TextRecognizer { *; }
