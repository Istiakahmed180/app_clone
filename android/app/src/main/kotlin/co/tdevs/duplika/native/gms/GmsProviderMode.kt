package co.tdevs.duplika.native.gms

/**
 * What the operator has asked for. A *request*, never an assertion of availability.
 *
 * The resolver honours a mode only so far as the environment allows: no mode can make a
 * provider serve a capability it does not have. `REAL_GMS` on a device without Play services
 * yields [UnsupportedProvider] with a stated reason, not a Real GMS provider pretending.
 *
 * There is still no user-facing toggle. All four modes are implemented and honoured, and the
 * microG backend now genuinely works (device-verified; see
 * `docs/microg-container-spike.md`), but choosing it is currently an explicit native action
 * (`RealVirtualizationEngine.provisionMicroG`) rather than a UI switch. [AUTO] is the default
 * and reproduces exactly the behaviour Duplika had before this phase.
 */
enum class GmsProviderMode {

    /**
     * Pick the best backend that is genuinely available: Real GMS if the host has it, a
     * real microG implementation if one ever exists, otherwise unsupported. The default.
     */
    AUTO,

    /** Real GMS only. If the host does not have it, report unavailable — do not fall back. */
    REAL_GMS,

    /**
     * microG only: the bundled artefact provisioned into the container. Resolves to an
     * unsupported provider when no artefact is bundled.
     *
     * It does **not** silently fall back to Real GMS: someone who asked for microG and
     * quietly got Google's Play services instead has been given the opposite of what they
     * asked for, which for this particular choice is the whole point of asking.
     */
    MICROG,

    /**
     * Do not initialise optional Google service integrations at all.
     *
     * Note the scope: this governs what *Duplika* does, and Duplika's only Google-service
     * operations are host-presence reporting and container provisioning. It cannot and does
     * not stop a guest app from reaching the host's Play services through the engine — that
     * path does not run through this abstraction (see the audit). Treating DISABLED as
     * "guests get no Google services" would be wrong.
     */
    DISABLED,
    ;

    companion object {
        val DEFAULT: GmsProviderMode = AUTO

        /**
         * Parses a mode from configuration, falling back to [DEFAULT] for anything
         * unrecognised — including null and blank.
         *
         * Lenient on purpose: an unreadable mode must not break cloning, and AUTO is the
         * behaviour that was there before, so the failure mode is "as before" rather than
         * "no Google services".
         */
        fun parse(raw: String?): GmsProviderMode =
            entries.firstOrNull { it.name.equals(raw?.trim(), ignoreCase = true) } ?: DEFAULT
    }
}
