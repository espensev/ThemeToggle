#include "RegistryManager.h"
#include "Types.h"

RegistryManager::RegistryManager() = default;

bool RegistryManager::ReadTheme(DWORD& systemValue, DWORD& appsValue, bool& hasSystem, bool& hasApps) {
    RegKey keyRead;
    LONG result = keyRead.Open(HKEY_CURRENT_USER, REG_KEY_PATH, KEY_READ);

    systemValue = 0;
    appsValue = 0;
    hasSystem = false;
    hasApps = false;

    if (result == ERROR_SUCCESS) {
        hasSystem = GetRegistryValue(keyRead, SYSTEM_VALUE_NAME, systemValue);
        hasApps = GetRegistryValue(keyRead, APPS_VALUE_NAME, appsValue);
        return true;
    }
    else if (result == ERROR_FILE_NOT_FOUND || result == ERROR_PATH_NOT_FOUND) {
        // Key doesn't exist - defaults to dark (0)
        return true;
    }

    return false;
}

bool RegistryManager::WriteTheme(DWORD value, DWORD prevSystem, bool hadSystem) {
    RegKey keyWrite;
    LONG result = keyWrite.CreateOrOpen(HKEY_CURRENT_USER, REG_KEY_PATH, KEY_WRITE);

    if (result != ERROR_SUCCESS || !keyWrite.IsValid()) {
        return false;
    }

    bool systemUpdated = false;
    if (!SetRegistryValue(keyWrite, SYSTEM_VALUE_NAME, value)) {
        return false;
    }
    systemUpdated = true;

    if (!SetRegistryValue(keyWrite, APPS_VALUE_NAME, value)) {
        if (systemUpdated) {
            RestoreValue(keyWrite, SYSTEM_VALUE_NAME, hadSystem, prevSystem);
        }
        return false;
    }

    // Transfer ownership to member variable for later flush
    // Nullify RegKey's handle to prevent double-close when destructor runs
    hKeyWrite = keyWrite.hKey;
    keyWrite.hKey = nullptr;  // Transfer ownership - prevent RegKey destructor from closing

    return true;
}

bool RegistryManager::Flush() {
    if (hKeyWrite) {
        LONG result = RegFlushKey(hKeyWrite);
        RegCloseKey(hKeyWrite);
        hKeyWrite = nullptr;
        return result == ERROR_SUCCESS;
    }
    return true;
}

bool RegistryManager::GetRegistryValue(HKEY hKey, const wchar_t* valueName, DWORD& outValue) {
    DWORD dataSize = sizeof(DWORD);
    DWORD type = 0;
    LONG result = RegQueryValueExW(hKey, valueName, nullptr, &type,
        reinterpret_cast<LPBYTE>(&outValue), &dataSize);
    return (result == ERROR_SUCCESS && type == REG_DWORD && dataSize == sizeof(DWORD));
}

bool RegistryManager::SetRegistryValue(HKEY hKey, const wchar_t* valueName, DWORD value) {
    LONG result = RegSetValueExW(hKey, valueName, 0, REG_DWORD,
        reinterpret_cast<const BYTE*>(&value), sizeof(DWORD));
    return result == ERROR_SUCCESS;
}

void RegistryManager::RestoreValue(HKEY hKey, const wchar_t* valueName, bool hadValue, DWORD value) {
    if (!hKey) {
        return;
    }

    if (hadValue) {
        SetRegistryValue(hKey, valueName, value);
    }
    else {
        RegDeleteValueW(hKey, valueName);
    }
}
