plugins { id("com.android.application") }

android {
    namespace = "com.example.duplikaladder.level10gms"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.duplikaladder.level10gms"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }
    buildFeatures { buildConfig = true }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    signingConfigs { getByName("debug") }
    buildTypes {
        release {
            // Same rule as Level 9: minification stays ON so an R8 problem can be told
            // apart from a virtualization problem. Never turned off to make a probe pass.
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
    // Availability + the GoogleApi client framework itself.
    implementation("com.google.android.gms:play-services-base:18.5.0")

    // P1 — the discriminator. AdvertisingIdClient is a plain bindService + AIDL call to
    // com.google.android.gms.ads.identifier.service.START. It does NOT go through the
    // GoogleApi client framework, needs no account, no API key and no permission. If this
    // succeeds while the GoogleApi-framework probes fail, the boundary is the framework's
    // caller validation and not GMS transport.
    implementation("com.google.android.gms:play-services-ads-identifier:18.0.1")

    // P2 — AppSet ID: a GoogleApi-framework client that also needs no account and no key.
    // Same "no credentials" property as P1 but reached through the framework, which is
    // what makes the pair a controlled comparison.
    implementation("com.google.android.gms:play-services-appset:16.0.2")

    // P3 — the Level 9 control, carried forward unchanged so Level 10 can be compared
    // directly against the Level 9 evidence.
    implementation("com.google.android.gms:play-services-location:21.3.0")

    // P5 — read-only account inspection. Used ONLY to observe that no account is present
    // and to classify account-bound APIs as a security boundary. No sign-in is attempted.
    implementation("com.google.android.gms:play-services-auth:21.2.0")
}
