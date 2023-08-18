package com.it_nomads.fluttersecurestorage;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;
import android.util.Base64;
import android.util.Log;

import androidx.annotation.RequiresApi;
import androidx.security.crypto.EncryptedSharedPreferences;
import androidx.security.crypto.MasterKeys;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.HashMap;
import java.util.Map;

public class FlutterSecureStorage {

    private final String TAG = "SecureStorageAndroid";
    private final Context applicationContext;
    protected Map<String, Object> options;
    private SharedPreferences preferences;
    private Boolean failedToUseEncryptedSharedPreferences = false;

    public FlutterSecureStorage(Context context) {
        applicationContext = context.getApplicationContext();
    }

    @SuppressWarnings({"ConstantConditions"})
    private boolean getUseEncryptedSharedPreferences() {
        return failedToUseEncryptedSharedPreferences;
    }

    boolean containsKey(String key) {
        ensureInitialized();

        return preferences.contains(key);
    }

    String read(String key) throws Exception {
        ensureInitialized();

        return  preferences.getString(key, null);
    }

    @SuppressWarnings("unchecked")
    public Map<String, String> readAll() throws Exception {
        ensureInitialized();

        return (Map<String, String>) preferences.getAll();
    }

    void write(String key, String value) throws Exception {
        ensureInitialized();

        SharedPreferences.Editor editor = preferences.edit();
        editor.putString(key, value);
        editor.apply();
    }

    public void delete(String key) {
        ensureInitialized();

        SharedPreferences.Editor editor = preferences.edit();
        editor.remove(key);
        editor.apply();
    }

    void deleteAll() {
        ensureInitialized();

        SharedPreferences.Editor editor = preferences.edit();
        editor.clear();
        editor.apply();
    }

    @SuppressWarnings({"ConstantConditions"})
    private void ensureInitialized() {
        // Check if already initialized.
        // TODO: Disable for now because this will break mixed usage of secureSharedPreference
        if (preferences != null) return;

        try {
            preferences = initializeEncryptedSharedPreferencesManager(applicationContext);
        } catch (Exception e) {
            Log.e(TAG, "EncryptedSharedPreferences initialization failed", e);
            failedToUseEncryptedSharedPreferences = true;
        }
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
}
