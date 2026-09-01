# Flutter's own engine/embedding classes — keep them intact so the engine
# can still find its Java entry points after R8 runs.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Play Core split-install classes are referenced by Flutter's deferred-
# components support even though this app doesn't use deferred components —
# without this, R8 fails the build with "missing classes" for them.
-dontwarn com.google.android.play.core.**
