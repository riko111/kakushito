import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application") // Apply the Android application plugin
    id("org.jetbrains.kotlin.android") // Apply the Kotlin Android plugin
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.isoffice.kakushito_mobile"
    compileSdk = flutter.compileSdkVersion
    //ndkVersion = flutter.ndkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        // JDK 17 のツールチェーンを使う（推奨）
        jvmToolchain(17)

        // bytecode のターゲットを 17 に
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
            // 必要なら追加:
            // freeCompilerArgs.addAll("-Xjvm-default=all")
            // languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_9)
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.isoffice.kakushito_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
