import java.io.File
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val releaseStoreFile: File? =
    if (keystorePropertiesFile.exists()) {
        val path = keystoreProperties.getProperty("storeFile")?.trim().orEmpty()
        if (path.isEmpty()) null else file(path)
    } else {
        null
    }

val useReleaseSigning = releaseStoreFile != null && releaseStoreFile.isFile

android {
    namespace = "com.tantawii.icu_connect"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.tantawii.icu_connect"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (useReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storePassword = keystoreProperties["storePassword"] as String
                storeFile = releaseStoreFile
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (useReleaseSigning) {
                    signingConfigs.getByName("release")
                } else {
                    when {
                        keystorePropertiesFile.exists() ->
                            logger.lifecycle(
                                "Warning: Keystore not found at ${releaseStoreFile?.absolutePath ?: "(invalid storeFile)"}. " +
                                    "Release bundle uses debug signing. Add the .jks file next to android/app/build.gradle.kts " +
                                    "or fix storeFile in android/key.properties (see android/key.properties.example).",
                            )
                        else ->
                            logger.lifecycle(
                                "Warning: android/key.properties missing — release uses debug signing. " +
                                    "Copy android/key.properties.example for Play Store signing.",
                            )
                    }
                    signingConfigs.getByName("debug")
                }
        }
    }
}

flutter {
    source = "../.."
}
