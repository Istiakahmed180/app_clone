package co.tdevs.duplika.native

import android.content.Context
import java.io.File

/**
 * Per-clone permission policy: which dangerous permissions a given container may **not** use.
 *
 * The model is a deny-list, so an untouched clone behaves exactly as before — everything the
 * host holds is available. The user narrows from there, one clone at a time.
 *
 * ## Why a deny-list, and what it does and does not do
 *
 * A guest runs under the host's UID, so Android checks the **host's** grants when a guest
 * reaches for the camera, the microphone or location. The hardware service makes that check in
 * `system_server` against the host UID, and no container can change what that process sees.
 * This policy therefore cannot be a hard sandbox: it is consulted by the engine's
 * permission-check hooks (see `IActivityManagerProxy$checkPermission`), so an app that asks
 * before it uses a permission is scoped per clone, while an app that skips the check is not.
 *
 * That is stated to the user in the UI rather than implied away. It is still worth having:
 * virtually every well-behaved permission request goes through the check.
 *
 * ## A plain file, not SharedPreferences
 *
 * The engine override runs inside a **guest process**, where the container redirects the app's
 * own storage — a `getSharedPreferences` read there comes back empty. A plain file under
 * [FILE_NAME], read by absolute path, is what the override can actually see. The file name and
 * the `"<userId> <permission>"` line format are a contract with that override, which cannot
 * reference this class (the AAR is compiled before the app). Keep the two in step.
 */
class ClonePermissionPolicy(private val context: Context) {

    private fun file(): File = File(context.applicationContext.filesDir, FILE_NAME)

    fun denied(virtualUserId: Int): Set<String> =
        readAll()[virtualUserId] ?: emptySet()

    fun setDenied(virtualUserId: Int, permission: String, denied: Boolean) {
        val all = readAll().toMutableMap()
        val current = (all[virtualUserId] ?: emptySet()).toMutableSet()
        if (denied) {
            current.add(permission)
        } else {
            current.remove(permission)
        }
        if (current.isEmpty()) {
            all.remove(virtualUserId)
        } else {
            all[virtualUserId] = current
        }
        writeAll(all)
    }

    private fun readAll(): Map<Int, Set<String>> {
        val target = file()
        if (!target.exists()) {
            return emptyMap()
        }
        val result = mutableMapOf<Int, MutableSet<String>>()
        return try {
            target.forEachLine { line ->
                val split = line.trim().split(' ')
                if (split.size == 2) {
                    val userId = split[0].toIntOrNull()
                    if (userId != null) {
                        result.getOrPut(userId) { mutableSetOf() }.add(split[1])
                    }
                }
            }
            result
        } catch (error: Exception) {
            Slog.w(Slog.ENGINE, "Could not read the clone permission policy: ${error.message}")
            emptyMap()
        }
    }

    private fun writeAll(all: Map<Int, Set<String>>) {
        val lines = all.entries
            .sortedBy { it.key }
            .flatMap { (userId, permissions) -> permissions.sorted().map { "$userId $it" } }
        try {
            file().writeText(lines.joinToString("\n"))
        } catch (error: Exception) {
            Slog.w(Slog.ENGINE, "Could not write the clone permission policy: ${error.message}")
        }
    }

    companion object {
        /** Shared with `IActivityManagerProxy$checkPermission`. */
        const val FILE_NAME = "clone_permissions.txt"
    }
}
