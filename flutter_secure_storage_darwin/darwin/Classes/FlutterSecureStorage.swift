//
//  FlutterSecureStorageManager.swift
//  flutter_secure_storage
//
//  Created by Julian Steenbakker on 22/08/2022.
//

import Foundation

class FlutterSecureStorage {
    private func parseAccessibleAttr(accessibility: String?) -> CFString {
        guard let accessibility = accessibility else {
            return kSecAttrAccessibleWhenUnlocked
        }

        switch accessibility {
        case "passcode":
            return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        case "unlocked":
            return kSecAttrAccessibleWhenUnlocked
        case "unlocked_this_device":
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case "first_unlock":
            return kSecAttrAccessibleAfterFirstUnlock
        case "first_unlock_this_device":
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        default:
            return kSecAttrAccessibleWhenUnlocked
        }
    }

    private func baseQuery(key: String?, groupId: String?, accountName: String?, synchronizable: Bool?, accessibility: String?, useDataProtectionKeyChain: Bool, returnData: Bool?) -> Dictionary<CFString, Any> {
        var keychainQuery: [CFString: Any] = [
            kSecClass : kSecClassGenericPassword
        ]

        if (accessibility != nil) {
            keychainQuery[kSecAttrAccessible] = parseAccessibleAttr(accessibility: accessibility)
        }
        
        //The data protection key affects operations only in macOS. Other platforms automatically behave as if the key is set to true, and ignore the key in the query dictionary.
        #if os(iOS)
        if #available(macOS 10.15, *) {
            keychainQuery[kSecUseDataProtectionKeychain] = useDataProtectionKeyChain
        }
        #endif

        if (key != nil) {
            keychainQuery[kSecAttrAccount] = key
        }

        
        if (groupId != nil) {
            keychainQuery[kSecAttrAccessGroup] = groupId
        }

        if (accountName != nil) {
            keychainQuery[kSecAttrService] = accountName
        }

        if (synchronizable != nil) {
            keychainQuery[kSecAttrSynchronizable] = synchronizable
        }

        if (returnData != nil) {
            keychainQuery[kSecReturnData] = returnData
        }
        return keychainQuery
    }

    internal func containsKey(key: String, groupId: String?, accountName: String?, useDataProtectionKeyChain: Bool) -> Result<Bool, OSSecError> {
        // The accessibility parameter has no influence on uniqueness.
        func queryKeychain(synchronizable: Bool) -> OSStatus {
           let keychainQuery = baseQuery(key: key, groupId: groupId, accountName: accountName, synchronizable: synchronizable, accessibility: nil, useDataProtectionKeyChain: useDataProtectionKeyChain, returnData: false)
           return SecItemCopyMatching(keychainQuery as CFDictionary, nil)
       }

       let statusSynchronizable = queryKeychain(synchronizable: true)
       if statusSynchronizable == errSecSuccess {
           return .success(true)
       } else if statusSynchronizable != errSecItemNotFound {
           return .failure(OSSecError(status: statusSynchronizable))
       }

       let statusNonSynchronizable = queryKeychain(synchronizable: false)
       switch statusNonSynchronizable {
       case errSecSuccess:
           return .success(true)
       case errSecItemNotFound:
           return .success(false)
       default:
           return .failure(OSSecError(status: statusNonSynchronizable))
       }
    }

    internal func readAll(groupId: String?, accountName: String?, synchronizable: Bool?, accessibility: String?, useDataProtectionKeyChain: Bool) -> FlutterSecureStorageResponse {
        var keychainQuery = baseQuery(key: nil, groupId: groupId, accountName: accountName, synchronizable: synchronizable, accessibility: accessibility, useDataProtectionKeyChain: useDataProtectionKeyChain, returnData: true)

        keychainQuery[kSecMatchLimit] = kSecMatchLimitAll
        keychainQuery[kSecReturnAttributes] = true

        var ref: AnyObject?
        let status = SecItemCopyMatching(
            keychainQuery as CFDictionary,
            &ref
        )

        if (status == errSecItemNotFound) {
            // readAll() returns all elements, so return nil if the items does not exist
            return FlutterSecureStorageResponse(status: errSecSuccess, value: nil)
        }

        var results: [String: String] = [:]

        if (status == noErr) {
            (ref as! NSArray).forEach { item in
                let key: String = (item as! NSDictionary)[kSecAttrAccount] as! String
                let value: String = String(data: (item as! NSDictionary)[kSecValueData] as! Data, encoding: .utf8) ?? ""
                results[key] = value
            }
        }

        return FlutterSecureStorageResponse(status: status, value: results)
    }

    internal func read(key: String, groupId: String?, accountName: String?, useDataProtectionKeyChain: Bool) -> FlutterSecureStorageResponse {
        // Function to retrieve a value considering the synchronizable parameter.
        func readValue(synchronizable: Bool?) -> FlutterSecureStorageResponse {
            let keychainQuery = baseQuery(key: key, groupId: groupId, accountName: accountName, synchronizable: synchronizable, accessibility: nil, useDataProtectionKeyChain: useDataProtectionKeyChain, returnData: true)

            var ref: AnyObject?
            let status = SecItemCopyMatching(
                keychainQuery as CFDictionary,
                &ref
            )

            // Return nil if the key is not found.
            if status == errSecItemNotFound {
                return FlutterSecureStorageResponse(status: errSecSuccess, value: nil)
            }

            var value: String? = nil

            if status == noErr, let data = ref as? Data {
                value = String(data: data, encoding: .utf8)
            }

            return FlutterSecureStorageResponse(status: status, value: value)
        }

        // First, query without synchronizable, then with synchronizable if no value is found.
        let responseWithoutSynchronizable = readValue(synchronizable: nil)
        return responseWithoutSynchronizable.value != nil ? responseWithoutSynchronizable : readValue(synchronizable: true)
    }

    internal func deleteAll(groupId: String?, accountName: String?, synchronizable: Bool?, accessibility: String?, useDataProtectionKeyChain: Bool) -> FlutterSecureStorageResponse {
        let keychainQuery = baseQuery(key: nil, groupId: groupId, accountName: accountName, synchronizable: synchronizable, accessibility: accessibility, useDataProtectionKeyChain: useDataProtectionKeyChain, returnData: nil)
        let status = SecItemDelete(keychainQuery as CFDictionary)

        if (status == errSecItemNotFound) {
            // deleteAll() deletes all items, so return nil if the items does not exist
            return FlutterSecureStorageResponse(status: errSecSuccess, value: nil)
        }

        return FlutterSecureStorageResponse(status: status, value: nil)
    }

    internal func delete(key: String, groupId: String?, accountName: String?, synchronizable: Bool?, accessibility: String?, useDataProtectionKeyChain: Bool) -> FlutterSecureStorageResponse {
        let keychainQuery = baseQuery(key: key, groupId: groupId, accountName: accountName, synchronizable: synchronizable, accessibility: accessibility, useDataProtectionKeyChain: useDataProtectionKeyChain, returnData: true)
        let status = SecItemDelete(keychainQuery as CFDictionary)

        // Return nil if the key is not found
        if (status == errSecItemNotFound) {
            return FlutterSecureStorageResponse(status: errSecSuccess, value: nil)
        }

        return FlutterSecureStorageResponse(status: status, value: nil)
    }

    internal func write(key: String, value: String, groupId: String?, accountName: String?, synchronizable: Bool?, accessibility: String?, useDataProtectionKeyChain: Bool) -> FlutterSecureStorageResponse {
        var keyExists: Bool = false

        // Check if the key exists but without accessibility.
        // This parameter has no effect on the uniqueness of the key.
        switch containsKey(key: key, groupId: groupId, accountName: accountName, useDataProtectionKeyChain: useDataProtectionKeyChain) {
            case .success(let exists):
                keyExists = exists
                break;
            case .failure(let err):
                return FlutterSecureStorageResponse(status: err.status, value: nil)
        }

        var keychainQuery = baseQuery(key: key, groupId: groupId, accountName: accountName, synchronizable: synchronizable, accessibility: accessibility, useDataProtectionKeyChain: useDataProtectionKeyChain, returnData: nil)

        if (keyExists) {
            // Entry exists, try to update it. Change of kSecAttrAccessible not possible via update.
            var update: [CFString: Any?] = [
                kSecValueData: value.data(using: String.Encoding.utf8),
                kSecAttrSynchronizable: synchronizable
            ]

            if #available(macOS 10.15, *) {
                update[kSecUseDataProtectionKeychain] = useDataProtectionKeyChain
            }

            let status = SecItemUpdate(keychainQuery as CFDictionary, update as CFDictionary)

            if status == errSecSuccess {
                return FlutterSecureStorageResponse(status: status, value: nil)
            }
            
            // Update failed, possibly due to different kSecAttrAccessible.
            // Delete the entry for all possible kSecAttrAccessible and create
            // a new one with the provided kSecAttrAccessible in the next step.
            delete(key: key, groupId: groupId, accountName: accountName, synchronizable: synchronizable, accessibility: nil, useDataProtectionKeyChain: useDataProtectionKeyChain)
            delete(key: key, groupId: groupId, accountName: accountName, synchronizable: synchronizable, accessibility: "passcode", useDataProtectionKeyChain: useDataProtectionKeyChain)
            delete(key: key, groupId: groupId, accountName: accountName, synchronizable: synchronizable, accessibility: "unlocked", useDataProtectionKeyChain: useDataProtectionKeyChain)
            delete(key: key, groupId: groupId, accountName: accountName, synchronizable: synchronizable, accessibility: "unlocked_this_device", useDataProtectionKeyChain: useDataProtectionKeyChain)
            delete(key: key, groupId: groupId, accountName: accountName, synchronizable: synchronizable, accessibility: "first_unlock", useDataProtectionKeyChain: useDataProtectionKeyChain)
            delete(key: key, groupId: groupId, accountName: accountName, synchronizable: synchronizable, accessibility: "first_unlock_this_device", useDataProtectionKeyChain: useDataProtectionKeyChain)
        }

        // Entry does not exist or was deleted, create a new entry.
        keychainQuery[kSecValueData] = value.data(using: String.Encoding.utf8)
        if #available(macOS 10.15, *) {
            keychainQuery[kSecUseDataProtectionKeychain] = useDataProtectionKeyChain
        }


        let status = SecItemAdd(keychainQuery as CFDictionary, nil)

        return FlutterSecureStorageResponse(status: status, value: nil)
    }
}

struct FlutterSecureStorageResponse {
    var status: OSStatus?
    var value: Any?
}

struct OSSecError: Error {
    var status: OSStatus
}
