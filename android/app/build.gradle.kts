import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun googleMapsApiKey(): String {
    val directKey = project.findProperty("MAPS_API_KEY_ANDROID") as? String
    if (!directKey.isNullOrBlank()) return directKey

    val dartDefines = project.findProperty("dart-defines") as? String
    if (!dartDefines.isNullOrBlank()) {
        for (encoded in dartDefines.split(",")) {
            val define = try {
                String(Base64.getDecoder().decode(encoded))
            } catch (_: IllegalArgumentException) {
                continue
            }
            if (define.startsWith("MAPS_API_KEY_ANDROID=")) {
                val key = define.substringAfter("=")
                if (key.isNotBlank()) return key
            }
        }
    }

    val envFile = rootProject.file("../.env")
    if (envFile.exists()) {
        envFile.useLines { lines ->
            lines
                .map { it.trim() }
                .firstOrNull {
                    it.startsWith("MAPS_API_KEY_ANDROID=") &&
                        !it.startsWith("#")
                }
                ?.substringAfter("=")
                ?.trim()
                ?.takeIf { it.isNotBlank() }
                ?.let { return it }
        }
    }

    return ""
}

android {
    namespace = "com.example.stock_a_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.stock_a_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Keep the native Maps SDK key aligned with the key visible to Dart.
        // Prefer an explicit Gradle property, then Flutter dart-defines, then
        // the project .env file used during local development.
        manifestPlaceholders["MAPS_API_KEY_ANDROID"] = googleMapsApiKey()
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
