plugins { id("com.android.application") }

android {
    namespace = "com.example.duplikaladder.isosplit"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.duplikaladder.isosplit"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    signingConfigs { getByName("debug") }
    buildTypes {
        release {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    // Built in two passes, because AGP's manifest merger folds a declared dynamic feature's
    // components into the base APK — which would put the launcher in base.apk and destroy the
    // very thing this fixture exists to test.
    //
    //   pass 1 (-PwithFeature=1):  assemble the FEATURE apk — needs the link below to exist
    //   pass 2 (no property):      assemble the BASE apk — no feature, so nothing is merged in
    //
    // The result is Chrome's real shape: a base whose manifest declares no launcher, plus a
    // split whose manifest does. Both passes share identical resources and versionCode and are
    // signed with the same debug key, so `adb install-multiple` accepts them as one package.
    if (providers.gradleProperty("withFeature").isPresent) {
        dynamicFeatures += setOf(":level11_isosplit_feature")
    }
}
