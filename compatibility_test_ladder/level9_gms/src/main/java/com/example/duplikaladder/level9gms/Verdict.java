package com.example.duplikaladder.level9gms;

/**
 * The five outcomes Level 9 is allowed to report.
 *
 * <p>PARTIAL and BLOCKED are separate on purpose. PARTIAL means the guest reached the
 * layer under test and got a worse answer than the host would; BLOCKED means the test
 * could not run at all, so it proves nothing either way. Collapsing them would let a
 * test that never executed be counted as evidence.
 */
public enum Verdict {
    PASS,
    PARTIAL,
    FAIL,
    BLOCKED,
    NOT_TESTED
}
