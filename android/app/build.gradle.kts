import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Assinatura de release (Fase A, item 28-31). android/key.properties nunca
// e versionado (ver .gitignore) -- cada maquina/CI que gera release precisa
// do proprio arquivo, apontando pro keystore real. Ver docs/android_signing.md.
val keystorePropertiesFile = rootProject.file("key.properties")
val hasKeystoreProperties = keystorePropertiesFile.exists()
val keystoreProperties = Properties()
if (hasKeystoreProperties) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "com.lucasdiogof.fifaqueue"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications (canal queue_alerts da Etapa 7) usa APIs
        // de java.time que so existem nativamente no Android 26+. O desugaring
        // faz o app rodar nos minSdk mais baixos sem isso quebrar.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.lucasdiogof.fifaqueue"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasKeystoreProperties) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Sem key.properties, cai no debug signing (mantem `flutter run
            // --release` funcionando em dev) -- mas o check no
            // gradle.taskGraph abaixo impede que uma build de release de
            // verdade (assembleRelease/bundleRelease) saia assinada com a
            // chave de debug em silencio.
            signingConfig = if (hasKeystoreProperties) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

gradle.taskGraph.whenReady {
    val requestedRelease = allTasks.any { it.name.contains("Release") }
    if (requestedRelease && !hasKeystoreProperties) {
        throw GradleException(
            "Build de release pedida sem android/key.properties -- isso " +
                "assinaria o APK/AAB com a chave de debug, que a Play Store " +
                "rejeita. Gere um keystore e crie key.properties antes de " +
                "continuar (veja docs/android_signing.md). Builds de debug " +
                "continuam funcionando normalmente sem esse arquivo."
        )
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
