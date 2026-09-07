package com.example.duplikaladder.storageprobe;

import android.app.Activity;
import android.app.AppOpsManager;
import android.content.Context;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Process;
import android.os.StatFs;
import android.os.storage.StorageManager;
import android.os.storage.StorageVolume;
import android.util.Log;
import android.widget.ScrollView;
import android.widget.TextView;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;

public final class MainActivity extends Activity {
    private static final String TAG = "StorageProbe";
    private static final String STATE_FILE = "probe-state.txt";

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        String report = collectReport();
        TextView text = new TextView(this);
        text.setText(report);
        text.setTextIsSelectable(true);
        text.setPadding(28, 36, 28, 36);
        setContentView(new ScrollView(this) {{ addView(text); }});
        Log.i(TAG, report);
    }

    private String collectReport() {
        StringBuilder out = new StringBuilder();
        line(out, "Storage Probe 1.0");
        line(out, "process=" + ApplicationIdentity.processName());
        line(out, "uid=" + Process.myUid() + " pid=" + Process.myPid());
        line(out, "package=" + getPackageName());
        line(out, "sdk=" + Build.VERSION.SDK_INT);
        line(out, "externalStorageState=" + safe(() -> Environment.getExternalStorageState()));
        line(out, "externalStorageDirectory=" + safe(() -> Environment.getExternalStorageDirectory().getAbsolutePath()));
        line(out, "isExternalStorageManager=" + safe(() -> Boolean.toString(Environment.isExternalStorageManager())));
        line(out, "filesDir=" + describe(getFilesDir()));
        line(out, "cacheDir=" + describe(getCacheDir()));
        line(out, "externalFilesDir=" + describe(getExternalFilesDir(null)));
        line(out, "externalCacheDir=" + describe(getExternalCacheDir()));
        File[] media = getExternalMediaDirs();
        line(out, "externalMediaDirs.count=" + (media == null ? "null" : media.length));
        if (media != null) for (int i = 0; i < media.length; i++) line(out, "externalMediaDirs[" + i + "]=" + describe(media[i]));
        appendVolumes(out);
        appendWrite(out, "internal", getFilesDir());
        appendWrite(out, "cache", getCacheDir());
        appendWrite(out, "externalFiles", getExternalFilesDir(null));
        if (getExternalFilesDir(null) != null) {
            appendWriteAt(out, "externalFiles.medialibThumbnails", new File(getExternalFilesDir(null), "medialib/thumbnails"));
        }
        appendWrite(out, "externalCache", getExternalCacheDir());
        if (media != null) for (int i = 0; i < media.length; i++) appendWrite(out, "externalMedia[" + i + "]", media[i]);
        File stateFile = new File(getFilesDir(), STATE_FILE);
        int launches = readCounter(stateFile) + 1;
        try { writeText(stateFile, Integer.toString(launches)); }
        catch (Throwable t) { line(out, "internalPersistence.write=EXCEPTION " + exception(t)); }
        line(out, "internalPersistence.launches=" + launches);
        try { writeText(new File(getFilesDir(), "last-report.txt"), out.toString()); }
        catch (Throwable t) { line(out, "internalPersistence.report=EXCEPTION " + exception(t)); }
        return out.toString();
    }

    private void appendVolumes(StringBuilder out) {
        try {
            StorageManager sm = getSystemService(StorageManager.class);
            List<StorageVolume> volumes = sm == null ? null : sm.getStorageVolumes();
            line(out, "storageVolumes.count=" + (volumes == null ? "null" : volumes.size()));
            if (volumes != null) for (int i = 0; i < volumes.size(); i++) {
                StorageVolume v = volumes.get(i);
                String path = "unsupported";
                if (Build.VERSION.SDK_INT >= 30) path = String.valueOf(v.getDirectory());
                line(out, "storageVolume[" + i + "]=" + path + ",primary=" + v.isPrimary() + ",removable=" + v.isRemovable() + ",state=" + v.getState());
            }
        } catch (Throwable t) { line(out, "storageVolumes=EXCEPTION " + exception(t)); }
    }

    private void appendWrite(StringBuilder out, String label, File root) {
        if (root == null) { line(out, label + ".path=null"); return; }
        appendWriteAt(out, label, new File(root, "storage-probe"));
    }

    private void appendWriteAt(StringBuilder out, String label, File dir) {
        File file = new File(dir, "probe.txt");
        String value = "probe-" + System.currentTimeMillis();
        boolean mkdir = false, write = false, read = false;
        String error = "";
        try { mkdir = dir.exists() || dir.mkdirs(); writeText(file, value); write = true; read = value.equals(readText(file)); }
        catch (Throwable t) { error = exception(t); }
        line(out, label + ".path=" + dir.getAbsolutePath());
        line(out, label + ".exists=" + dir.exists() + ",readable=" + dir.canRead() + ",writable=" + dir.canWrite());
        line(out, label + ".mkdir=" + mkdir + ",write=" + write + ",read=" + read + (error.isEmpty() ? "" : ",error=" + error));
    }

    private static String describe(File f) { return f == null ? "null" : f.getAbsolutePath() + " exists=" + f.exists() + " readable=" + f.canRead() + " writable=" + f.canWrite(); }
    private static String safe(ThrowingSupplier<String> s) { try { return s.get(); } catch (Throwable t) { return "EXCEPTION " + exception(t); } }
    private static String exception(Throwable t) { return t.getClass().getName() + ":" + String.valueOf(t.getMessage()); }
    private static void line(StringBuilder b, String s) { b.append(s).append('\n'); }
    private static void writeText(File f, String text) throws Exception { File parent = f.getParentFile(); if (parent != null) parent.mkdirs(); try (FileOutputStream o = new FileOutputStream(f)) { o.write(text.getBytes(StandardCharsets.UTF_8)); } }
    private static String readText(File f) throws Exception { byte[] b = new byte[(int) f.length()]; try (FileInputStream i = new FileInputStream(f)) { int n = i.read(b); return new String(b, 0, Math.max(0, n), StandardCharsets.UTF_8); } }
    private static int readCounter(File f) { try { return Integer.parseInt(readText(f).trim()); } catch (Throwable ignored) { return 0; } }
    private interface ThrowingSupplier<T> { T get() throws Throwable; }

    private static final class ApplicationIdentity {
        static String processName() {
            if (Build.VERSION.SDK_INT >= 28) return ApplicationIdentityHolder.name;
            return "api<28";
        }
    }
    private static final class ApplicationIdentityHolder {
        static final String name = android.app.Application.getProcessName();
    }
}
