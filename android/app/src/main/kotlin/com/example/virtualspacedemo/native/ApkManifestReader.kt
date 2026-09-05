package com.example.virtualspacedemo.native

import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.zip.ZipFile

/**
 * Reads declarations out of an APK's compiled `AndroidManifest.xml`.
 *
 * `PackageManager` can surface an archive's `<meta-data>`, but `<property>` elements are
 * only readable through `getProperty()`, which answers for installed packages alone. An APK
 * the user imported is by definition not installed, so without this the secure-environment
 * declaration could be missed entirely.
 *
 * Only Android's binary XML is decoded, and only enough of it to recover element names and
 * their `name`/`value` attributes. Nothing is executed and no hidden API is touched.
 */
object ApkManifestReader {

    data class Declaration(val element: String, val name: String, val value: String?)

    /**
     * Every `<meta-data>` and `<property>` declaration in the manifest.
     *
     * Returns an empty list for anything unreadable: a parse failure must never be able to
     * look like a positive declaration.
     */
    fun readDeclarations(apkPath: String): List<Declaration> = try {
        ZipFile(File(apkPath)).use { zip ->
            val entry = zip.getEntry(MANIFEST) ?: return emptyList()
            zip.getInputStream(entry).use { parse(it.readBytes()) }
        }
    } catch (error: Throwable) {
        Slog.w(Slog.INSTALL, "Could not read $MANIFEST from $apkPath: ${error.message}")
        emptyList()
    }

    /** True when [name] is declared with a truthy value. */
    fun declaresTrue(apkPath: String, names: Collection<String>): Boolean =
        readDeclarations(apkPath).any { declaration ->
            declaration.name in names && declaration.value.isTruthy()
        }

    private fun String?.isTruthy(): Boolean =
        this != null && (equals("true", ignoreCase = true) || this == "1")

    // -------------------------------------------------------------------------------
    // Binary XML decoding
    // -------------------------------------------------------------------------------

    private fun parse(bytes: ByteArray): List<Declaration> {
        val buffer = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN)
        if (buffer.remaining() < 8 || buffer.getShort(0).toInt() != TYPE_XML) {
            return emptyList()
        }

        var strings: List<String> = emptyList()
        val declarations = mutableListOf<Declaration>()

        var offset = buffer.getShort(2).toInt() // skip the file header
        while (offset + 8 <= bytes.size) {
            val chunkType = buffer.getShort(offset).toInt() and 0xFFFF
            val chunkSize = buffer.getInt(offset + 4)
            if (chunkSize <= 0 || offset + chunkSize > bytes.size) {
                break
            }

            when (chunkType) {
                TYPE_STRING_POOL -> strings = readStringPool(buffer, offset)
                TYPE_START_ELEMENT ->
                    readElement(buffer, offset, strings)?.let(declarations::add)
            }

            offset += chunkSize
        }

        return declarations
    }

    private fun readElement(
        buffer: ByteBuffer,
        chunkOffset: Int,
        strings: List<String>,
    ): Declaration? {
        // chunk header (8) + lineNumber (4) + comment (4) + namespace (4)
        val nameIndex = buffer.getInt(chunkOffset + 20)
        val element = strings.getOrNull(nameIndex) ?: return null
        if (element != "meta-data" && element != "property") {
            return null
        }

        val attributeStart = buffer.getShort(chunkOffset + 24).toInt() and 0xFFFF
        val attributeSize = buffer.getShort(chunkOffset + 26).toInt() and 0xFFFF
        val attributeCount = buffer.getShort(chunkOffset + 28).toInt() and 0xFFFF
        if (attributeSize < ATTRIBUTE_SIZE) {
            return null
        }

        var name: String? = null
        var value: String? = null

        for (index in 0 until attributeCount) {
            // attributeStart is measured from the attrExt structure, which begins after the
            // 8-byte chunk header plus lineNumber and comment (16 bytes in total).
            val at = chunkOffset + 16 + attributeStart + index * attributeSize
            if (at + ATTRIBUTE_SIZE > buffer.capacity()) {
                break
            }

            // Namespace is ignored on purpose: only the local names matter here, and
            // matching the android namespace URI adds nothing for this decision.
            val attributeName = strings.getOrNull(buffer.getInt(at + 4)) ?: continue
            val decoded = decodeValue(buffer, at, strings)

            when (attributeName) {
                "name" -> name = decoded
                "value" -> value = decoded
            }
        }

        return name?.let { Declaration(element, it, value) }
    }

    private fun decodeValue(buffer: ByteBuffer, attributeOffset: Int, strings: List<String>): String? {
        val rawIndex = buffer.getInt(attributeOffset + 8)
        // typedValue: size (2) + res0 (1) + dataType (1) + data (4)
        val dataType = buffer.get(attributeOffset + 15).toInt() and 0xFF
        val data = buffer.getInt(attributeOffset + 16)

        return when (dataType) {
            TYPE_STRING -> strings.getOrNull(if (rawIndex >= 0) rawIndex else data)
            TYPE_INT_BOOLEAN -> (data != 0).toString()
            TYPE_INT_DEC, TYPE_INT_HEX -> data.toString()
            else -> strings.getOrNull(rawIndex)
        }
    }

    private fun readStringPool(buffer: ByteBuffer, chunkOffset: Int): List<String> {
        val stringCount = buffer.getInt(chunkOffset + 8)
        val flags = buffer.getInt(chunkOffset + 16)
        val stringsStart = buffer.getInt(chunkOffset + 20)
        val utf8 = (flags and FLAG_UTF8) != 0

        val offsetsStart = chunkOffset + buffer.getShort(chunkOffset + 2).toInt()
        val dataStart = chunkOffset + stringsStart

        return (0 until stringCount).map { index ->
            runCatching {
                val at = dataStart + buffer.getInt(offsetsStart + index * 4)
                if (utf8) readUtf8(buffer, at) else readUtf16(buffer, at)
            }.getOrDefault("")
        }
    }

    private fun readUtf8(buffer: ByteBuffer, offset: Int): String {
        // Two length fields precede the bytes: character count, then byte count. Either may
        // be stored across two bytes when the high bit is set.
        var at = offset
        at += if (buffer.get(at).toInt() and 0x80 != 0) 2 else 1
        val byteLength = if (buffer.get(at).toInt() and 0x80 != 0) {
            val high = buffer.get(at).toInt() and 0x7F
            val low = buffer.get(at + 1).toInt() and 0xFF
            at += 2
            (high shl 8) or low
        } else {
            val length = buffer.get(at).toInt() and 0xFF
            at += 1
            length
        }

        val bytes = ByteArray(byteLength)
        for (i in 0 until byteLength) {
            bytes[i] = buffer.get(at + i)
        }
        return String(bytes, Charsets.UTF_8)
    }

    private fun readUtf16(buffer: ByteBuffer, offset: Int): String {
        var at = offset
        var length = buffer.getShort(at).toInt() and 0xFFFF
        at += 2
        if (length and 0x8000 != 0) {
            length = ((length and 0x7FFF) shl 16) or (buffer.getShort(at).toInt() and 0xFFFF)
            at += 2
        }

        val chars = CharArray(length)
        for (i in 0 until length) {
            chars[i] = buffer.getShort(at + i * 2).toInt().toChar()
        }
        return String(chars)
    }

    private const val MANIFEST = "AndroidManifest.xml"
    private const val ATTRIBUTE_SIZE = 20

    private const val TYPE_XML = 0x0003
    private const val TYPE_STRING_POOL = 0x0001
    private const val TYPE_START_ELEMENT = 0x0102

    private const val TYPE_STRING = 0x03
    private const val TYPE_INT_DEC = 0x10
    private const val TYPE_INT_HEX = 0x11
    private const val TYPE_INT_BOOLEAN = 0x12

    private const val FLAG_UTF8 = 1 shl 8
}
