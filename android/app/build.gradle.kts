import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "com.entrenous.enepl_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.entrenous.enepl_app"
        // Minimum SDK 21 for better compatibility
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

     signingConfigs {
         create("release") {
             if (hasReleaseKeystore) {
                 val storeFilePath = keystoreProperties["storeFile"]?.toString()
                 val storePasswordValue = keystoreProperties["storePassword"]?.toString()
                 val keyAliasValue = keystoreProperties["keyAlias"]?.toString()
                 val keyPasswordValue = keystoreProperties["keyPassword"]?.toString()

                 if (storeFilePath.isNullOrBlank() || storePasswordValue.isNullOrBlank() || keyAliasValue.isNullOrBlank() || keyPasswordValue.isNullOrBlank()) {
                     throw GradleException(
                         "key.properties is missing required fields: storeFile, storePassword, keyAlias, keyPassword"
                     )
                 }

                 storeFile = file(storeFilePath)
                 storePassword = storePasswordValue
                 keyAlias = keyAliasValue
                 keyPassword = keyPasswordValue
             }
         }
     }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
