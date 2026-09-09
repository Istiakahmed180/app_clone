package com.example.duplikaladder.level10gms;

/** One diagnostic's outcome: a verdict, a one-line summary, and the detail behind it. */
public final class TestResult {
    public final String id;
    public final String title;
    public final Verdict verdict;
    public final String summary;
    public final String detail;

    private TestResult(String id, String title, Verdict verdict, String summary, String detail) {
        this.id = id;
        this.title = title;
        this.verdict = verdict;
        this.summary = summary;
        this.detail = detail;
    }

    public static TestResult of(String id, String title, Verdict verdict, String summary, String detail) {
        return new TestResult(id, title, verdict, summary, detail);
    }

    public static TestResult notTested(String id, String title) {
        return new TestResult(id, title, Verdict.NOT_TESTED, "not run yet", "");
    }
}
