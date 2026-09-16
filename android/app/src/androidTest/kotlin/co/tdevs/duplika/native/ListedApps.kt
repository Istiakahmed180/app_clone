package co.tdevs.duplika.native

/**
 * The package names in an [InstalledAppsProvider.listLaunchableApps] payload.
 *
 * The listing returns the apps alongside a count of the ones it left out, and every test
 * here wants only the first half of that.
 */
@Suppress("UNCHECKED_CAST")
fun Map<String, Any?>.listedPackageNames(): List<String> =
    (this["apps"] as? List<Map<String, Any?>> ?: emptyList())
        .mapNotNull { it["packageName"] as? String }
