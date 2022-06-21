package com.it_nomads.fluttersecurestorage;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.Looper;
import android.util.Base64;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.security.crypto.EncryptedSharedPreferences;
import androidx.security.crypto.MasterKeys;

import com.it_nomads.fluttersecurestorage.ciphers.StorageCipher;
import com.it_nomads.fluttersecurestorage.ciphers.StorageCipher18Implementation;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.nio.charset.Charset;
import java.security.GeneralSecurityException;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class FlutterSecureStoragePlugin implements MethodCallHandler, FlutterPlugin {

    private static final String TAG = "FlutterSecureStoragePl";
    private MethodChannel channel;
    private SharedPreferences preferences;
    // Necessary for deferred initialization of storageCipher.
    private Context applicationContext;
    private HandlerThread workerThread;
    private Handler workerThreadHandler;
    private boolean resetOnError = false;

    public void initInstance(BinaryMessenger messenger, Context context) {
        try {
            applicationContext = context.getApplicationContext();
            preferences = initializeEncryptedSharedPreferencesManager(applicationContext);
            workerThread = new HandlerThread("com.it_nomads.fluttersecurestorage.worker");
            workerThread.start();
            workerThreadHandler = new Handler(workerThread.getLooper());

            channel = new MethodChannel(messenger, "plugins.it_nomads.com/flutter_secure_storage");
            channel.setMethodCallHandler(this);
        } catch (Exception e) {
            Log.e(TAG, "Registration failed", e);
        }
    }

    @SuppressWarnings("unchecked")
    private void ensureInitialized(Map<String, Object> arguments) {
        Map<String, Object> options = (Map<String, Object>) arguments.get("options");
        if (options != null) {
            resetOnError = resetOnError(options);
        }
    }

    private boolean resetOnError(Map<String, Object> arguments) {
        return arguments.containsKey("resetOnError") && arguments.get("resetOnError").equals("true");
    }

    private SharedPreferences initializeEncryptedSharedPreferencesManager(Context context) throws GeneralSecurityException, IOException {
        return EncryptedSharedPreferences.create(
                context.getPackageName() + "_preferences",
                MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC),
                context,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        );
    }

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        initInstance(binding.getBinaryMessenger(), binding.getApplicationContext());
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (channel != null) {
            workerThread.quitSafely();
            workerThread = null;

            channel.setMethodCallHandler(null);
            channel = null;
        }
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result rawResult) {
        MethodResultWrapper result = new MethodResultWrapper(rawResult);
        // Run all method calls inside the worker thread instead of the platform thread.
        workerThreadHandler.post(new MethodRunner(call, result));
    }

    @SuppressWarnings("unchecked")
    private String getKeyFromCall(MethodCall call) {
        Map<String, Object> arguments = (Map<String, Object>) call.arguments;
        return (String) arguments.get("key");
    }

    @SuppressWarnings("unchecked")
    private Map<String, String> readAll() throws Exception {
        return (Map<String, String>) preferences.getAll();
    }

    private void deleteAll() {
        preferences.edit().clear().apply();
    }

    private void write(String key, String value) throws Exception {
        SharedPreferences.Editor editor = preferences.edit();
        editor.putString(key, value);
        editor.apply();
    }

    private String read(String key) throws Exception {
        return preferences.getString(key, null);
    }

    private void delete(String key) {
        SharedPreferences.Editor editor = preferences.edit();
        editor.remove(key);
        editor.apply();
    }

    /**
     * MethodChannel.Result wrapper that responds on the platform thread.
     */
    static class MethodResultWrapper implements Result {

        private final Result methodResult;
        private final Handler handler = new Handler(Looper.getMainLooper());

        MethodResultWrapper(Result methodResult) {
            this.methodResult = methodResult;
        }

        @Override
        public void success(final Object result) {
            handler.post(() -> methodResult.success(result));
        }

        @Override
        public void error(final String errorCode, final String errorMessage, final Object errorDetails) {
            handler.post(() -> methodResult.error(errorCode, errorMessage, errorDetails));
        }

        @Override
        public void notImplemented() {
            handler.post(methodResult::notImplemented);
        }
    }

    /**
     * Wraps the functionality of onMethodCall() in a Runnable for execution in the worker thread.
     */
    class MethodRunner implements Runnable {
        private final MethodCall call;
        private final Result result;

        MethodRunner(MethodCall call, Result result) {
            this.call = call;
            this.result = result;
        }

        @Override
        @SuppressWarnings("unchecked")
        public void run() {
            try {
                switch (call.method) {
                    case "write": {
                        String key = getKeyFromCall(call);
                        Map<String, Object> arguments = (Map<String, Object>) call.arguments;
                        ensureInitialized(arguments);

                        String value = (String) arguments.get("value");

                        if (value != null) {
                            write(key, value);
                            result.success(null);
                        } else {
                            result.error("null", null, null);
                        }
                        break;
                    }
                    case "read": {
                        String key = getKeyFromCall(call);
                        Map<String, Object> arguments = (Map<String, Object>) call.arguments;
                        ensureInitialized(arguments);

                        if (preferences.contains(key)) {
                            String value = read(key);
                            result.success(value);
                        } else {
                            result.success(null);
                        }
                        break;
                    }
                    case "readAll": {
                        Map<String, Object> arguments = (Map<String, Object>) call.arguments;
                        ensureInitialized(arguments);

                        Map<String, String> value = readAll();
                        result.success(value);
                        break;
                    }
                    case "containsKey": {
                        String key = getKeyFromCall(call);
                        Map<String, Object> arguments = (Map<String, Object>) call.arguments;
                        ensureInitialized(arguments);

                        boolean containsKey = preferences.contains(key);
                        result.success(containsKey);
                        break;
                    }
                    case "delete": {
                        String key = getKeyFromCall(call);
                        Map<String, Object> arguments = (Map<String, Object>) call.arguments;
                        ensureInitialized(arguments);

                        delete(key);
                        result.success(null);
                        break;
                    }
                    case "deleteAll": {
                        Map<String, Object> arguments = (Map<String, Object>) call.arguments;
                        ensureInitialized(arguments);

                        deleteAll();
                        result.success(null);
                        break;
                    }
                    default:
                        result.notImplemented();
                        break;
                }

            } catch (Exception e) {
                if (resetOnError) {
                    deleteAll();
                    result.success("Data has been reset");
                } else {
                    StringWriter stringWriter = new StringWriter();
                    e.printStackTrace(new PrintWriter(stringWriter));
                    result.error("Exception encountered", call.method, stringWriter.toString());
                }
            }
        }
    }
}
