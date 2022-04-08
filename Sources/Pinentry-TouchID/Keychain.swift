import Foundation

/// Based on:  https://www.advancedswift.com/secure-private-data-keychain-swift/#keychain-delete-example

enum KeychainError: Error {
    // Attempted read for an item that does not exist.
    case itemNotFound
    
    // Attempted save to override an existing item.
    // Use update instead of save to update existing items
    case duplicateItem
    
    // A read of an item in any format other than Data
    case invalidItemFormat
    
    // Any operation result status than errSecSuccess
    case unexpectedStatus(OSStatus)
}

func savePassword(password: Data, service: String, account: String) throws {
    let query: [String: Any] = [
        // kSecAttrService,  kSecAttrAccount, and kSecClass
        // uniquely identify the item to save in Keychain
        kSecAttrService as String: service,
        kSecAttrAccount as String: account,
        kSecClass as String: kSecClassGenericPassword,
        
        // kSecAttrAccessible allows the item to be accessed
        // when the device is unlocked
        kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        
        // kSecAttrSynchronizable disallows synchronization
        kSecAttrSynchronizable as String: kCFBooleanFalse ?? false,
        
        // kSecValueData is the item value to save
        kSecValueData as String: password
    ]
    
    // SecItemAdd attempts to add the item identified by
    // the query to keychain
    let status = SecItemAdd(query as CFDictionary, nil)

    // errSecDuplicateItem is a special case where the
    // item identified by the query already exists. Throw
    // duplicateItem so the client can determine whether
    // or not to handle this as an error
    if status == errSecDuplicateItem {
        throw KeychainError.duplicateItem
    }

    // Any status other than errSecSuccess indicates the
    // save operation failed.
    guard status == errSecSuccess else {
        throw KeychainError.unexpectedStatus(status)
    }
}

func updatePassword(password: Data, service: String, account: String) throws {
    let query: [String: Any] = [
        // kSecAttrService,  kSecAttrAccount, and kSecClass
        // uniquely identify the item to update in Keychain
        kSecAttrService as String: service,
        kSecAttrAccount as String: account,
        kSecClass as String: kSecClassGenericPassword
    ]
    
    // attributes is passed to SecItemUpdate with
    // kSecValueData as the updated item value
    let attributes: [String: Data] = [
        kSecValueData as String: password
    ]
    
    // SecItemUpdate attempts to update the item identified
    // by query, overriding the previous value
    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

    // errSecItemNotFound is a special status indicating the
    // item to update does not exist. Throw itemNotFound so
    // the client can determine whether or not to handle
    // this as an error
    guard status != errSecItemNotFound else {
        throw KeychainError.itemNotFound
    }

    // Any status other than errSecSuccess indicates the
    // update operation failed.
    guard status == errSecSuccess else {
        throw KeychainError.unexpectedStatus(status)
    }
}

func readPassword(service: String, account: String) throws -> Data {
    let query: [String: Any] = [
        // kSecAttrService,  kSecAttrAccount, and kSecClass
        // uniquely identify the item to read in Keychain
        kSecAttrService as String: service,
        kSecAttrAccount as String: account,
        kSecClass as String: kSecClassGenericPassword,
        
        // kSecMatchLimitOne indicates keychain should read
        // only the most recent item matching this query
        kSecMatchLimit as String: kSecMatchLimitOne,

        // kSecReturnData is set to kCFBooleanTrue in order
        // to retrieve the data for the item
        kSecReturnData as String: kCFBooleanTrue ?? true
    ]

    // SecItemCopyMatching will attempt to copy the item
    // identified by query to the reference itemCopy
    var itemCopy: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &itemCopy)

    // errSecItemNotFound is a special status indicating the
    // read item does not exist. Throw itemNotFound so the
    // client can determine whether or not to handle
    // this case
    guard status != errSecItemNotFound else {
        throw KeychainError.itemNotFound
    }
    
    // Any status other than errSecSuccess indicates the
    // read operation failed.
    guard status == errSecSuccess else {
        throw KeychainError.unexpectedStatus(status)
    }

    // This implementation of KeychainInterface requires all
    // items to be saved and read as Data. Otherwise,
    // invalidItemFormat is thrown
    guard let password = itemCopy as? Data else {
        throw KeychainError.invalidItemFormat
    }

    return password
}

func deletePassword(service: String, account: String) throws {
    let query: [String: Any] = [
        // kSecAttrService,  kSecAttrAccount, and kSecClass
        // uniquely identify the item to delete in Keychain
        kSecAttrService as String: service,
        kSecAttrAccount as String: account,
        kSecClass as String: kSecClassGenericPassword
    ]

    // SecItemDelete attempts to perform a delete operation
    // for the item identified by query. The status indicates
    // if the operation succeeded or failed.
    let status = SecItemDelete(query as CFDictionary)

    // Any status other than errSecSuccess indicates the
    // delete operation failed.
    guard status == errSecSuccess else {
        throw KeychainError.unexpectedStatus(status)
    }
}
