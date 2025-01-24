package com.it_nomads.fluttersecurestorage;

import android.content.Context;
import android.content.SharedPreferences;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.Base64;
import android.util.Log;

import androidx.annotation.NonNull;

import com.it_nomads.fluttersecurestorage.ciphers.StorageCipher;
import com.it_nomads.fluttersecurestorage.ciphers.StorageCipherFactory;
import com.it_nomads.fluttersecurestorage.crypto.EncryptedSharedPreferences;
import com.it_nomads.fluttersecurestorage.crypto.MasterKey;

import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.util.HashMap;
import java.util.Map;

public class FlutterSecureStorage {

    private static final String TAG = "SecureStorageAndroid";
    private static final Charset CHARSET = StandardCharsets.UTF_8;
    private static final String DEFAULT_PREF_NAME = "FlutterSecureStorage";
    private static final String DEFAULT_KEY_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIHNlY3VyZSBzdG9yYWdlCg";
    @NonNull
    private final Context applicationContext;
    @NonNull
    private final SharedPreferences encryptedPreferences;
    private final Map<String, Object> options;
    private String sharedPreferencesName = DEFAULT_PREF_NAME;
    private String preferencesKeyPrefix = DEFAULT_KEY_PREFIX;


    public FlutterSecureStorage(Context context, Map<String, Object> options) throws GeneralSecurityException, IOException {
        this.applicationContext = context.getApplicationContext();
        this.options = options;
        ensureOptions();
        encryptedPreferences = getEncryptedSharedPreferences();
    }

    public boolean containsKey(String key) {
        return encryptedPreferences.contains(addPrefixToKey(key));
    }

    public String read(String key) {
        return encryptedPreferences.getString(addPrefixToKey(key), null);
    }

    public void write(String key, String value) {
        encryptedPreferences.edit().putString(addPrefixToKey(key), value).apply();
    }

    public void delete(String key) {
        encryptedPreferences.edit().remove(addPrefixToKey(key)).apply();
    }

    public void deleteAll() {
        encryptedPreferences.edit().clear().apply();
    }

    public Map<String, String> readAll() {
        Map<String, String> result = new HashMap<>();
        Map<String, ?> allEntries = encryptedPreferences.getAll();
        for (Map.Entry<String, ?> entry : allEntries.entrySet()) {
            String key = entry.getKey();
            Object value = entry.getValue();
            if (key.startsWith(preferencesKeyPrefix) && value instanceof String) {
                String originalKey = key.replaceFirst(preferencesKeyPrefix + "_", "");
                result.put(originalKey, (String) value);
            }
        }
        return result;
    }

    private String addPrefixToKey(String key) {
        return preferencesKeyPrefix + "_" + key;
    }

    private void ensureOptions() {
        sharedPreferencesName = options.containsKey("sharedPreferencesName") && options.get("sharedPreferencesName") instanceof String
                ? (String) options.get("sharedPreferencesName")
                : DEFAULT_PREF_NAME;

        preferencesKeyPrefix = options.containsKey("preferencesKeyPrefix") && options.get("preferencesKeyPrefix") instanceof String
                ? (String) options.get("preferencesKeyPrefix")
                : DEFAULT_KEY_PREFIX;
    }

    private SharedPreferences getEncryptedSharedPreferences() throws GeneralSecurityException, IOException {
        try {
            final SharedPreferences encryptedPreferences = initializeEncryptedSharedPreferencesManager(applicationContext);
            migrateToEncryptedPreferences(encryptedPreferences);
            return encryptedPreferences;
        } catch (Exception e) {
            Log.w(TAG, "EncryptedSharedPreferences initialization failed, resetting storage", e);
            applicationContext.getSharedPreferences(sharedPreferencesName, Context.MODE_PRIVATE).edit().clear().apply();
            try {
                return initializeEncryptedSharedPreferencesManager(applicationContext);
            } catch (Exception f) {
                Log.e(TAG, "EncryptedSharedPreferences initialization after reset failed", e);
                throw f;
            }
        }
    }

    private SharedPreferences initializeEncryptedSharedPreferencesManager(Context context) throws GeneralSecurityException, IOException {
        MasterKey masterKey = new MasterKey.Builder(context)
                .setKeyGenParameterSpec(new KeyGenParameterSpec.Builder(
                        MasterKey.DEFAULT_MASTER_KEY_ALIAS,
                        KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                        .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                        .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                        .setKeySize(256)
                        .build())
                .build();

        return EncryptedSharedPreferences.create(
                context,
                sharedPreferencesName,
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        );
    }

    private void migrateToEncryptedPreferences(SharedPreferences target) {
        SharedPreferences source = applicationContext.getSharedPreferences(sharedPreferencesName, Context.MODE_PRIVATE);

        try {
            StorageCipher cipher = new StorageCipherFactory(source, options).getSavedStorageCipher(applicationContext);

            Map<String, ?> sourceEntries = source.getAll();
            if (sourceEntries.isEmpty()) return;

            int succesfull = 0;
            int failed = 0;
            for (Map.Entry<String, ?> entry : sourceEntries.entrySet()) {
                String key = entry.getKey();
                Object value = entry.getValue();
                if (key.startsWith(preferencesKeyPrefix) && value instanceof String) {
                    try {
                        String decryptedValue = decryptValue((String) value, cipher);
                        target.edit().putString(key, decryptedValue).apply();
                        source.edit().remove(key).apply();
                        succesfull++;
                    } catch (Exception e) {
                        Log.e(TAG, "Migration failed for key: " + key, e);
                        failed++;
                    }
                }
            }

            if (succesfull > 0) {
                Log.i(TAG, "Successfully migrated " + succesfull + " keys.");
            }
            if (failed > 0) {
                Log.i(TAG, "Failed to migrate " + failed + " keys.");
            }
        } catch(Exception e) {
            Log.e(TAG, "Migration failed due to initialisation error.", e);
        }
    }

    private String decryptValue(String value, StorageCipher cipher) throws Exception {
        byte[] data = Base64.decode(value, Base64.DEFAULT);
        return new String(cipher.decrypt(data), CHARSET);
    }
}
