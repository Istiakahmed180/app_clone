plugins { id("com.android.application") }

android {
    namespace = "com.example.duplikaladder.level9gms"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.duplikaladder.level9gms"
        // 23 matches the rest of the ladder; the Play services artefacts below all
        // declare 21 or lower, so nothing here raises it.
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }
    buildFeatures {
        // GuestIdentity stamps every run with its build type, read from BuildConfig.DEBUG,
        // so Debug and Release evidence cannot be mixed up after the fact.
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    signingConfigs { getByName("debug") }
    buildTypes {
        release {
            // Unlike the earlier ladder modules this one keeps minification ON. A GMS
            // client library is exactly the kind of reflection-heavy dependency that
            // behaves differently under R8, and Level 9 has to be able to tell an
            // R8 problem apart from a virtualization problem. Turning minification off
            // to make Release "pass" would destroy that distinction.
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Test B: the official availability API, which is what every real GMS-dependent
    // app calls first.
    implementation("com.google.android.gms:play-services-base:18.5.0")
    // Test D: SettingsClient.checkLocationSettings is an officially supported GoogleApi
    // call that needs no Google account and no runtime permission, so it exercises the
    // full client -> binder -> GMS path without authenticating anything.
    implementation("com.google.android.gms:play-services-location:21.3.0")
    // Test E: firebase-common alone. No google-services plugin and no
    // google-services.json, so nothing here can reach a Google backend; the point is
    // to observe library loading, its auto-installed ContentProvider, and the
    // configuration path.
    implementation("com.google.firebase:firebase-common:21.0.0")
}
