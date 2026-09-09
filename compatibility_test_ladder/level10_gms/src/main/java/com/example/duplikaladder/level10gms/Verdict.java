package com.example.duplikaladder.level10gms;

/**
 * The five outcomes Level 10 is allowed to report.
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
    /**
     * The probe reached its answer and the answer is that this feature cannot be provided
     * legitimately by a third-party container -- it needs an identity or integrity
     * guarantee only the platform can give. Distinct from FAIL: nothing here is a defect
     * to be fixed, and attempting to make it pass would mean spoofing something.
     */
    UNSUPPORTED,
    NOT_TESTED
}
