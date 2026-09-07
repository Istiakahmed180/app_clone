package com.example.duplikaladder.level6;

import android.content.Context;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

final class Level6Db extends SQLiteOpenHelper {
    Level6Db(Context c) { super(c, "level6.db", null, 1); }
    @Override public void onCreate(SQLiteDatabase db) { db.execSQL("CREATE TABLE state (id INTEGER PRIMARY KEY, value INTEGER NOT NULL)"); db.execSQL("INSERT INTO state(id,value) VALUES(1,0)"); }
    @Override public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) { }
    int incrementAndRead() { SQLiteDatabase db = getWritableDatabase(); db.execSQL("UPDATE state SET value=value+1 WHERE id=1"); return readValue(); }
    int readValue() { android.database.Cursor c = getReadableDatabase().rawQuery("SELECT value FROM state WHERE id=1", null); try { return c.moveToFirst() ? c.getInt(0) : -1; } finally { c.close(); } }
}
