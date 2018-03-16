package com.mabeijianxi.jianxiffmpegcmd;

import android.app.Application;
import android.util.Log;

import com.tencent.bugly.crashreport.CrashReport;

/**
 * Created by ibqo on 2018/3/16.
 */

public class APP extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        CrashReport.initCrashReport(getApplicationContext());
        //CrashReport.testJavaCrash();
    }
}
