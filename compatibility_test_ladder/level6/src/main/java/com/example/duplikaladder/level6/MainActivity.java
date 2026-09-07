package com.example.duplikaladder.level6;

import android.Manifest;
import android.app.Activity;
import android.app.job.JobInfo;
import android.app.job.JobScheduler;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.sqlite.SQLiteDatabase;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

public class MainActivity extends Activity {
    private static final int PERMISSION_REQUEST = 601;
    private static final int OPEN_DOCUMENT = 602;
    private static final int CREATE_DOCUMENT = 603;
    private TextView status;
    private Level6Db db;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        db = new Level6Db(this);
        setContentView(buildUi());
        log("onCreate persistedCount=" + db.incrementAndRead());
        handleDeepLink(getIntent());
    }

    private View buildUi() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(40, 40, 40, 40);
        TextView title = new TextView(this);
        title.setText("Ladder Level 6\\nModern Android API probe");
        title.setTextSize(24);
        root.addView(title);
        status = new TextView(this);
        status.setText(permissionStatus());
        root.addView(status);
        add(root, "REQUEST RUNTIME PERMISSIONS", v -> requestRuntimePermissions());
        add(root, "POST LOCAL NOTIFICATION", v -> postNotification());
        add(root, "SCHEDULE JOB", v -> scheduleJob());
        add(root, "OPEN DOCUMENT", v -> startActivityForResult(new Intent(Intent.ACTION_OPEN_DOCUMENT).setType("text/plain").addCategory(Intent.CATEGORY_OPENABLE), OPEN_DOCUMENT));
        add(root, "CREATE DOCUMENT", v -> startActivityForResult(new Intent(Intent.ACTION_CREATE_DOCUMENT).setType("text/plain").putExtra(Intent.EXTRA_TITLE, "level6.txt"), CREATE_DOCUMENT));
        add(root, "OPEN EXPLICIT LINK ACTIVITY", v -> startActivity(new Intent(this, LinkActivity.class)));
        add(root, "OPEN IMPLICIT LINK ACTIVITY", v -> startActivity(new Intent("com.example.duplikaladder.level6.OPEN_LINK")));
        add(root, "READ SQLITE VALUE", v -> status.setText("SQLite value=" + db.readValue()));
        return root;
    }

    private void add(LinearLayout root, String label, View.OnClickListener listener) {
        Button b = new Button(this); b.setText(label); b.setOnClickListener(listener); root.addView(b);
    }

    private void requestRuntimePermissions() {
        if (Build.VERSION.SDK_INT >= 33) requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS, Manifest.permission.CAMERA}, PERMISSION_REQUEST);
        else requestPermissions(new String[]{Manifest.permission.CAMERA}, PERMISSION_REQUEST);
    }

    private String permissionStatus() {
        return "permission notification=" + (Build.VERSION.SDK_INT < 33 || checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED)
                + " camera=" + (checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED);
    }

    private void postNotification() {
        NotificationManager nm = getSystemService(NotificationManager.class);
        if (Build.VERSION.SDK_INT >= 26) nm.createNotificationChannel(new NotificationChannel("level6", "Level 6", NotificationManager.IMPORTANCE_DEFAULT));
        Intent tap = new Intent(this, MainActivity.class).setAction("com.example.duplikaladder.level6.NOTIFICATION_TAP");
        PendingIntent pi = PendingIntent.getActivity(this, 1, tap, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        android.app.Notification n = new android.app.Notification.Builder(this, "level6")
                .setSmallIcon(android.R.drawable.ic_dialog_info).setContentTitle("Level 6 notification").setContentText("Notification tap reached the guest").setContentIntent(pi).setAutoCancel(true).build();
        nm.notify(601, n); log("notification posted channel=level6");
    }

    private void scheduleJob() {
        JobInfo info = new JobInfo.Builder(601, new ComponentName(this, ProbeJobService.class)).setMinimumLatency(1000).setOverrideDeadline(5000).build();
        int result = getSystemService(JobScheduler.class).schedule(info); log("job schedule result=" + result);
    }

    private void handleDeepLink(Intent intent) {
        if (intent != null && intent.getData() != null) log("deepLink=" + intent.getData());
        if ("com.example.duplikaladder.level6.NOTIFICATION_TAP".equals(intent == null ? null : intent.getAction())) status.setText("notification tap reached guest");
    }

    @Override protected void onNewIntent(Intent intent) { super.onNewIntent(intent); setIntent(intent); handleDeepLink(intent); }
    @Override public void onRequestPermissionsResult(int r, String[] p, int[] g) { super.onRequestPermissionsResult(r, p, g); status.setText(permissionStatus()); log("permission result=" + r + " " + permissionStatus()); }
    @Override protected void onActivityResult(int r, int c, Intent data) { super.onActivityResult(r, c, data); log("document result request=" + r + " result=" + c + " uri=" + (data == null ? "null" : data.getData())); }
    private void log(String s) { android.util.Log.i("LadderLevel6", s); }
}
