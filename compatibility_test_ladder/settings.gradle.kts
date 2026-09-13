import org.gradle.api.initialization.resolve.RepositoriesMode

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "compatibility_test_ladder"
include(
    ":level2", ":level3", ":level4", ":level6", ":level7fixture", ":level9_gms",
    ":level10_gms", ":storageprobe", ":usermanagerprobe", ":level12_isolatedservice",
    ":level11_isosplit",
)

// `level11_isosplit` is a dynamic-feature pair built in two passes. It declares
// `:level11_isosplit_feature` in `dynamicFeatures` only under `-PwithFeature=1`, so the
// feature module's `featureName` only resolves in that pass. Including it unconditionally
// made a plain `assembleDebug` fail on `:level11_isosplit_feature` (no feature name in the
// base's metadata). It is included under the same switch the base uses. See
// `level11_isosplit/build.gradle.kts`.
if (startParameter.projectProperties.containsKey("withFeature")) {
    include(":level11_isosplit_feature")
}
