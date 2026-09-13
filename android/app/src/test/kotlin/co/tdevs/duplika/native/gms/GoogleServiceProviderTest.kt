package co.tdevs.duplika.native.gms

import android.app.Application
import android.content.Context
import co.tdevs.duplika.native.EngineAvailability
import co.tdevs.duplika.native.EngineResult
import co.tdevs.duplika.native.VirtualizationEngineAdapter
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Unit tests for the Google service provider abstraction.
 *
 * Runs on the JVM with no device and no Robolectric — the provider layer touches no Android
 * framework type, which is why that is possible and why it is worth keeping true.
 *
 * The engine is a hand-written fake rather than a mocking framework: the surface under test
 * is two methods, and a fake that also *counts calls* lets the tests assert the thing that
 * actually matters for this phase — that Real GMS behaviour is unchanged, i.e. that the same
 * engine calls are made as before.
 */
class GoogleServiceProviderTest {

    /**
     * Records what the provider layer asked the engine, so a test can assert delegation
     * rather than just the returned value. Only the two GMS methods are meaningful; the
     * rest of the interface is unreachable from this layer and throws if touched, which
     * would fail loudly if the abstraction ever grew a dependency it should not have.
     */
    private class FakeEngine(
        private val gmsOnHost: Boolean,
        private val installOutcome: EngineResult<Unit> = EngineResult.ok(),
        private val throwOnIsSupported: Boolean = false,
    ) : VirtualizationEngineAdapter {

        var isGmsSupportedCalls = 0
        var installGmsCalls = 0
        var lastInstallUserId: Int? = null

        override fun isGmsSupported(): Boolean {
            isGmsSupportedCalls++
            if (throwOnIsSupported) throw IllegalStateException("engine unreachable")
            return gmsOnHost
        }

        override fun installGms(virtualUserId: Int): EngineResult<Unit> {
            installGmsCalls++
            lastInstallUserId = virtualUserId
            return installOutcome
        }

        // Everything below is outside this abstraction's scope. Throwing rather than
        // returning a default means a future accidental dependency fails the suite instead
        // of passing silently.
        override val backendName: String get() = unreachable()
        override fun attachBaseContext(application: Application, base: Context) = unreachable()
        override fun onCreate(application: Application) = unreachable()
        override fun checkAvailability(context: Context): EngineAvailability = unreachable()
        override fun initialize(context: Context): EngineResult<Unit> = unreachable()
        override fun installPackage(packageName: String, virtualUserId: Int): EngineResult<Unit> =
            unreachable()
        override fun installApkFiles(apkPaths: List<String>, virtualUserId: Int): EngineResult<Unit> =
            unreachable()
        override fun uninstallPackage(packageName: String, virtualUserId: Int): EngineResult<Unit> =
            unreachable()
        override fun clearPackageData(packageName: String, virtualUserId: Int): EngineResult<Unit> =
            unreachable()
        override fun clearPackageCache(packageName: String, virtualUserId: Int): EngineResult<Unit> =
            unreachable()
        override fun isPackageInstalled(packageName: String, virtualUserId: Int): Boolean =
            unreachable()
        override fun launch(packageName: String, virtualUserId: Int): EngineResult<Unit> =
            unreachable()
        override fun stop(packageName: String, virtualUserId: Int): EngineResult<Unit> = unreachable()
        override fun isRunning(packageName: String, virtualUserId: Int): Boolean = unreachable()
        override fun deleteVirtualUser(virtualUserId: Int): EngineResult<Unit> = unreachable()
        override fun listVirtualUserIds(): List<Int> = unreachable()
        override fun guestSharedPreferencesFile(
            packageName: String,
            virtualUserId: Int,
            preferenceName: String,
        ): java.io.File? = unreachable()

        private fun unreachable(): Nothing =
            throw AssertionError("the GMS provider layer must not call this engine method")
    }

    private fun resolver(
        engine: FakeEngine,
        microG: GoogleServiceProvider = MicroGProvider(),
        log: GmsProviderLog = GmsProviderLog.NONE,
    ) = GoogleServiceProviderResolver(RealGmsProvider(engine), microG, log)

    // ---------------------------------------------------------------- RealGmsProvider

    @Test
    fun `real gms provider reports available and both capabilities when the host has gms`() {
        val provider = RealGmsProvider(FakeEngine(gmsOnHost = true))

        assertEquals(RealGmsProvider.NAME, provider.providerName)
        assertEquals(ProviderAvailability.AVAILABLE, provider.availability())
        assertEquals(
            setOf(GmsCapability.HOST_GMS_PRESENCE, GmsCapability.CONTAINER_GMS_PROVISIONING),
            provider.capabilities(),
        )
    }

    @Test
    fun `real gms provider reports no capabilities when the host has no gms`() {
        val provider = RealGmsProvider(FakeEngine(gmsOnHost = false))

        assertEquals(ProviderAvailability.UNAVAILABLE, provider.availability())
        assertTrue(provider.capabilities().isEmpty())
    }

    @Test
    fun `real gms provider delegates provisioning to the engine unchanged`() {
        val engine = FakeEngine(gmsOnHost = true)
        val provider = RealGmsProvider(engine)

        val result = provider.provisionContainerGms(virtualUserId = 7)

        assertTrue(result.isSuccess)
        // The behaviour-preservation assertion: exactly one engine install, for this user.
        assertEquals(1, engine.installGmsCalls)
        assertEquals(7, engine.lastInstallUserId)
    }

    @Test
    fun `real gms provider does not attempt provisioning when the host has no gms`() {
        val engine = FakeEngine(gmsOnHost = false)

        val result = RealGmsProvider(engine).provisionContainerGms(virtualUserId = 3)

        assertTrue(result is ProviderResult.Unavailable)
        // Preserves the original precondition: no install is attempted at all.
        assertEquals(0, engine.installGmsCalls)
    }

    @Test
    fun `real gms provider maps an engine failure to a structured error`() {
        val engine = FakeEngine(
            gmsOnHost = true,
            installOutcome = EngineResult.Failure("GMS_INSTALL_FAILED", "engine refused"),
        )

        val result = RealGmsProvider(engine).provisionContainerGms(virtualUserId = 1)

        assertTrue(result is ProviderResult.Error)
        val error = result as ProviderResult.Error
        assertEquals("GMS_INSTALL_FAILED", error.code)
        assertEquals("engine refused", error.message)
        assertEquals("ERROR", error.outcome)
    }

    @Test
    fun `real gms provider treats an unreadable engine as no gms rather than throwing`() {
        // A throw here would take out the clone during provider selection; declining is the
        // safe direction.
        val provider = RealGmsProvider(FakeEngine(gmsOnHost = true, throwOnIsSupported = true))

        assertEquals(ProviderAvailability.UNAVAILABLE, provider.availability())
        assertTrue(provider.capabilities().isEmpty())
    }

    // ----------------------------------------------------------------- MicroGProvider

    @Test
    fun `microg provider is a placeholder that reports not implemented and no capabilities`() {
        val provider = MicroGProvider()

        assertEquals(MicroGProvider.NAME, provider.providerName)
        assertEquals(ProviderAvailability.NOT_IMPLEMENTED, provider.availability())
        assertTrue(provider.capabilities().isEmpty())
    }

    @Test
    fun `microg provider returns not implemented for every capability`() {
        val provider = MicroGProvider()

        val presence = provider.hostGmsPresence()
        val provisioning = provider.provisionContainerGms(virtualUserId = 2)

        assertTrue(presence is ProviderResult.NotImplemented)
        assertTrue(provisioning is ProviderResult.NotImplemented)
        assertEquals("NOT_IMPLEMENTED", presence.outcome)
        // Never a plausible-looking default that could be mistaken for a real answer.
        assertFalse(presence.isSuccess)
        assertFalse(provisioning.isSuccess)
        assertEquals(
            MicroGProvider.IMPLEMENTATION_STATUS,
            provisioning.rawDiagnostics["implementationStatus"],
        )
    }

    // ------------------------------------------------------------ UnsupportedProvider

    @Test
    fun `unsupported provider fails deterministically without throwing`() {
        val provider = UnsupportedProvider("host has no Play services")

        assertEquals(ProviderAvailability.UNAVAILABLE, provider.availability())
        assertTrue(provider.capabilities().isEmpty())

        val presence = provider.hostGmsPresence()
        val provisioning = provider.provisionContainerGms(virtualUserId = 4)

        assertTrue(presence is ProviderResult.Unavailable)
        assertTrue(provisioning is ProviderResult.Unavailable)
        // The reason travels with the result, so a caller learns why.
        assertEquals("host has no Play services", (presence as ProviderResult.Unavailable).reason)
        assertEquals(GmsCapability.HOST_GMS_PRESENCE, presence.capability)
        assertEquals(GmsCapability.CONTAINER_GMS_PROVISIONING, provisioning.capability)
    }

    // ------------------------------------------------------------------- AUTO mode

    @Test
    fun `auto selects real gms when the host has gms`() {
        val provider = resolver(FakeEngine(gmsOnHost = true)).resolve(GmsProviderMode.AUTO)

        assertEquals(RealGmsProvider.NAME, provider.providerName)
    }

    @Test
    fun `auto falls back to unsupported when nothing is available`() {
        val provider = resolver(FakeEngine(gmsOnHost = false)).resolve(GmsProviderMode.AUTO)

        assertEquals(UnsupportedProvider.NAME, provider.providerName)
    }

    @Test
    fun `auto never selects the microg placeholder`() {
        // The placeholder must be unselectable even when Real GMS is unavailable, or AUTO
        // would prefer a backend that cannot serve anything.
        val provider = resolver(FakeEngine(gmsOnHost = false), microG = MicroGProvider())
            .resolve(GmsProviderMode.AUTO)

        assertEquals(UnsupportedProvider.NAME, provider.providerName)
    }

    @Test
    fun `auto would select a microg implementation that genuinely works`() {
        // Proves the abstraction can hold a second backend -- the point of the phase --
        // without Real GMS changing. This stand-in is a test double, not a microG
        // implementation.
        val workingMicroG = object : GoogleServiceProvider {
            override val providerName = "MICROG_TEST_DOUBLE"
            override fun availability() = ProviderAvailability.AVAILABLE
            override fun capabilities() = setOf(GmsCapability.HOST_GMS_PRESENCE)
            override fun hostGmsPresence() = ProviderResult.Success(
                providerName, GmsCapability.HOST_GMS_PRESENCE, true,
            )
            override fun provisionContainerGms(virtualUserId: Int) =
                ProviderResult.Unsupported(
                    providerName, GmsCapability.CONTAINER_GMS_PROVISIONING, "not offered",
                )
        }

        val provider = resolver(FakeEngine(gmsOnHost = false), microG = workingMicroG)
            .resolve(GmsProviderMode.AUTO)

        assertEquals("MICROG_TEST_DOUBLE", provider.providerName)
    }

    // -------------------------------------------------------------- explicit modes

    @Test
    fun `real gms mode selects real gms when available`() {
        val provider = resolver(FakeEngine(gmsOnHost = true)).resolve(GmsProviderMode.REAL_GMS)

        assertEquals(RealGmsProvider.NAME, provider.providerName)
    }

    @Test
    fun `real gms mode reports unavailable rather than falling back`() {
        val provider = resolver(FakeEngine(gmsOnHost = false)).resolve(GmsProviderMode.REAL_GMS)

        assertEquals(UnsupportedProvider.NAME, provider.providerName)
        val result = provider.hostGmsPresence()
        assertTrue(result is ProviderResult.Unavailable)
        assertTrue((result as ProviderResult.Unavailable).reason.contains("Real GMS was requested"))
    }

    @Test
    fun `microg mode does not silently fall back to real gms`() {
        // Someone who asked for microG and quietly got Google's Play services has been
        // given the opposite of what they asked for.
        val provider = resolver(FakeEngine(gmsOnHost = true)).resolve(GmsProviderMode.MICROG)

        assertEquals(UnsupportedProvider.NAME, provider.providerName)
        val reason = (provider.hostGmsPresence() as ProviderResult.Unavailable).reason
        assertTrue(reason.contains("microG"))
        assertTrue(reason.contains(MicroGProvider.IMPLEMENTATION_STATUS))
    }

    @Test
    fun `disabled mode selects unsupported even when real gms is available`() {
        val engine = FakeEngine(gmsOnHost = true)

        val provider = resolver(engine).resolve(GmsProviderMode.DISABLED)

        assertEquals(UnsupportedProvider.NAME, provider.providerName)
        // Nothing was provisioned, and the engine was never asked to install.
        provider.provisionContainerGms(virtualUserId = 9)
        assertEquals(0, engine.installGmsCalls)
    }

    @Test
    fun `disabled mode states that guest access is unaffected`() {
        // DISABLED governs Duplika's own operations; it cannot stop a guest reaching the
        // host's Play services through the engine, and the reason must say so.
        val provider = resolver(FakeEngine(gmsOnHost = true)).resolve(GmsProviderMode.DISABLED)

        val reason = (provider.hostGmsPresence() as ProviderResult.Unavailable).reason
        assertTrue(reason.contains("guest"))
    }

    // ------------------------------------------------------------------ determinism

    @Test
    fun `selection is deterministic for the same mode and environment`() {
        val resolver = resolver(FakeEngine(gmsOnHost = true))

        val names = (1..5).map { resolver.resolve(GmsProviderMode.AUTO).providerName }

        assertEquals(1, names.distinct().size)
        assertEquals(RealGmsProvider.NAME, names.first())
    }

    @Test
    fun `mode parsing is lenient and defaults to auto`() {
        assertEquals(GmsProviderMode.AUTO, GmsProviderMode.parse("AUTO"))
        assertEquals(GmsProviderMode.REAL_GMS, GmsProviderMode.parse("real_gms"))
        assertEquals(GmsProviderMode.MICROG, GmsProviderMode.parse(" microg "))
        assertEquals(GmsProviderMode.DISABLED, GmsProviderMode.parse("DISABLED"))
        // An unreadable mode must not break cloning; AUTO is the pre-existing behaviour.
        assertEquals(GmsProviderMode.AUTO, GmsProviderMode.parse(null))
        assertEquals(GmsProviderMode.AUTO, GmsProviderMode.parse(""))
        assertEquals(GmsProviderMode.AUTO, GmsProviderMode.parse("nonsense"))
    }

    // ------------------------------------------------------------------ diagnostics

    @Test
    fun `selection is logged with the reasoning`() {
        val lines = mutableListOf<String>()
        resolver(FakeEngine(gmsOnHost = true), log = { lines.add(it) })
            .resolve(GmsProviderMode.AUTO)

        assertEquals(1, lines.size)
        val line = lines.single()
        assertTrue(line.contains("requestedProvider=AUTO"))
        assertTrue(line.contains("selectedProvider=REAL_GMS"))
        assertTrue(line.contains("availability=AVAILABLE"))
        assertTrue(line.contains("HOST_GMS_PRESENCE"))
        // The line must answer "why this provider?".
        assertTrue(line.contains("reason="))
    }

    @Test
    fun `diagnostics redact anything that looks like a secret`() {
        // A guard against a future call site, not a description of today's data.
        val result = ProviderResult.Success(
            provider = "TEST",
            capability = GmsCapability.HOST_GMS_PRESENCE,
            value = true,
            diagnostics = mapOf(
                "virtualUserId" to "3",
                "oauthToken" to "ya29.SHOULD-NEVER-APPEAR",
                "accountEmail" to "someone@example.com",
                "advertisingId" to "abcd-1234",
            ),
        )

        val redacted = result.redactedDiagnostics

        assertEquals("3", redacted["virtualUserId"])
        assertNotNull(redacted["oauthToken"])
        assertFalse(redacted["oauthToken"]!!.contains("ya29"))
        assertFalse(redacted["accountEmail"]!!.contains("example.com"))
        assertFalse(redacted["advertisingId"]!!.contains("abcd"))
    }
}
