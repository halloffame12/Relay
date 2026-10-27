import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Permanent Play identity. The application ID is also the code namespace for
// this Android module, so keep MainActivity in the matching Kotlin package.
// This value is permanent after the first Play upload.
val relayDefaultApplicationId = "io.github.halloffame12.relay"
val relayNamespace = "io.github.halloffame12.relay"

// Release identity and signing are intentionally supplied from local,
// untracked configuration. Never commit a keystore, password, or the
// key.properties file. See docs/release-readiness.md.
val relayApplicationId =
    providers.gradleProperty("relay.applicationId").orNull
        ?.takeIf { it.isNotBlank() }
        ?: relayDefaultApplicationId
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val hasReleaseSigning = keystorePropertiesFile.exists()
val allowDebugReleaseSigning =
    providers.gradleProperty("relay.allowDebugReleaseSigning").orNull == "true"
val allowExampleApplicationId =
    providers.gradleProperty("relay.allowExampleApplicationId").orNull == "true"
val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("Release", ignoreCase = true)
}
val usingDebugReleaseSigning = allowDebugReleaseSigning && !hasReleaseSigning
val qaApplicationId =
    relayApplicationId.startsWith("com.example.") || relayApplicationId.endsWith(".qa")

if (releaseTaskRequested && relayApplicationId.startsWith("com.example.") &&
    !allowExampleApplicationId
) {
    throw GradleException(
        "Relay is still using the placeholder application ID " +
            "'$relayApplicationId'. Choose the permanent Play application ID " +
            "(it cannot be changed after the first upload) and set " +
            "relay.applicationId in an untracked Gradle property, or pass " +
            "-Prelay.applicationId=<unique.id>. For a non-uploadable local QA " +
            "bundle, pass -Prelay.allowExampleApplicationId=true as well."
    )
}

if (releaseTaskRequested && !hasReleaseSigning && !allowDebugReleaseSigning) {
    throw GradleException(
        "Release signing is not configured. Create android/key.properties from " +
            "android/key.properties.example and a backed-up upload keystore. " +
            "For a non-uploadable local QA bundle, pass " +
            "-Prelay.allowDebugReleaseSigning=true."
    )
}

if (releaseTaskRequested && allowDebugReleaseSigning && hasReleaseSigning) {
    throw GradleException(
        "Both a release keystore and the debug-signing QA override are configured. " +
            "Remove -Prelay.allowDebugReleaseSigning=true to build with the real " +
            "upload key, or remove android/key.properties to build a QA bundle."
    )
}

if (releaseTaskRequested && usingDebugReleaseSigning && !qaApplicationId) {
    throw GradleException(
        "Debug-signed release bundles must use a QA application ID. Use an ID " +
            "starting with 'com.example.' or ending with '.qa', for example " +
            "-Prelay.applicationId=${relayDefaultApplicationId}.qa. A debug-signed " +
            "bundle must never use the production application ID."
    )
}

android {
    namespace = relayNamespace
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Permanent Play package ID. Property overrides are for QA/CI only;
        // never upload a com.example.* or debug-signed bundle.
        applicationId = relayApplicationId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                val storeFilePath = keystoreProperties.getProperty("storeFile")
                    ?.takeIf { it.isNotBlank() }
                    ?: throw GradleException(
                        "Missing 'storeFile' in android/key.properties."
                    )
                storeFile = rootProject.file(storeFilePath)
                if (storeFile == null || !storeFile!!.exists()) {
                    throw GradleException(
                        "The release keystore configured in android/key.properties " +
                            "was not found at ${storeFile!!.absolutePath}."
                    )
                }
                storePassword = keystoreProperties.getProperty("storePassword")
                    ?.takeIf { it.isNotBlank() }
                    ?: throw GradleException(
                        "Missing 'storePassword' in android/key.properties."
                    )
                keyAlias = keystoreProperties.getProperty("keyAlias")
                    ?.takeIf { it.isNotBlank() }
                    ?: throw GradleException(
                        "Missing 'keyAlias' in android/key.properties."
                    )
                keyPassword = keystoreProperties.getProperty("keyPassword")
                    ?.takeIf { it.isNotBlank() }
                    ?: throw GradleException(
                        "Missing 'keyPassword' in android/key.properties."
                    )
            }
        }
    }

    buildTypes {
        release {
            signingConfig = when {
                hasReleaseSigning -> signingConfigs.getByName("release")
                usingDebugReleaseSigning -> signingConfigs.getByName("debug")
                else -> null
            }
            if (usingDebugReleaseSigning) {
                // Make a debug-signed release artifact unmistakably local QA.
                versionNameSuffix = "-qa"
            }
        }
    }
}

flutter {
    source = "../.."
}
