import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

/**
 * Release signing material, read from `android/key.properties` if it is present.
 *
 * The file is gitignored, along with `*.keystore` and `*.jks`, so the keystore and its
 * passwords never enter the repository. See `docs/RELEASE_BUILD.md` for how to create it.
 *
 * Absent on a fresh checkout, and that is the normal case: the build then falls back to the
 * debug key so `flutter run --release` still works for local testing. The fallback is
 * announced rather than silent — a release-signed build and a debug-signed one look
 * identical until Play rejects the upload.
 */
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use(::load)
}

val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "co.tdevs.duplika"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        // Stated rather than inherited. The diagnostics logger stamps every event with
        // the build type it was captured in, which it reads from BuildConfig.DEBUG, and
        // AGP's default for this feature has changed between major versions.
        buildConfig = true
    }

    defaultConfig {
        applicationId = "co.tdevs.duplika"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        // Declared only when the material exists. Creating it unconditionally would give a
        // fresh checkout a signing config pointing at a keystore that is not there, and the
        // failure would surface as an opaque Gradle error rather than the plain statement
        // below.
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "\n  Duplika: android/key.properties not found -- signing the release " +
                        "build with the DEBUG key.\n  Fine for local testing; Play Console " +
                        "will reject this artefact. See docs/RELEASE_BUILD.md.\n"
                )
                signingConfigs.getByName("debug")
            }

            // Pinned rather than inherited. AGP 9 turns release minification on by
            // default, which silently broke the virtualization engine: R8 deleted the
            // annotation-only hidden-API stubs it reflects on. Stating the value here
            // keeps that decision visible next to the rules that make it survivable.
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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

dependencies {
    // Vendored virtualization engine (NewBlackbox / Bcore, Apache-2.0).
    // Prebuilt AAR rather than a source subproject: Bcore's Gradle DSL predates
    // AGP 9, and its AIDL/ndkBuild steps are already compiled into the archive.
    implementation(files("libs/bcore.aar"))
    implementation(files("libs/black-reflection.jar"))

    // Runtime dependencies Bcore expects but an AAR cannot declare for itself.
    implementation("com.moandjiezana.toml:toml4j:0.7.2")
    implementation("com.github.tiann:FreeReflection:3.2.2")
    implementation("androidx.appcompat:appcompat:1.7.0")
    // FileProvider, used to hand exported diagnostics reports to the share sheet.
    // Declared explicitly because it is imported directly rather than pulled in only
    // as an appcompat transitive.
    implementation("androidx.core:core:1.13.1")
    implementation("com.google.android.material:material:1.12.0")

    // JVM unit tests. The GMS provider layer is deliberately free of Android framework
    // types so its selection logic can be tested without a device or Robolectric.
    testImplementation("junit:junit:4.13.2")

    androidTestImplementation("androidx.test:core-ktx:1.6.1")
    androidTestImplementation("androidx.test:runner:1.6.2")
    androidTestImplementation("androidx.test.ext:junit-ktx:1.2.1")
}
