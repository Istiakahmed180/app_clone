package com.example.duplikaladder.level3;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public final class DetailActivity extends Activity {
    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        WebView web = new WebView(this);
        web.setWebViewClient(new WebViewClient());
        web.getSettings().setJavaScriptEnabled(false);
        web.loadDataWithBaseURL(null, "<h1>Level 3 WebView</h1><p>WebView activity reached.</p>", "text/html", "UTF-8", null);
        setContentView(web);
    }
}
