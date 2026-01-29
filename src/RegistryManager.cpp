#include "RegistryManager.h"
#include "Types.h"

RegistryStatus RegistryManager::ReadTheme(DWORD& systemValue, DWORD& appsValue, bool& hasSystem, bool& hasApps) {
    systemValue = 0;
    appsValue = 0;
    hasSystem = false;
    hasApps = false;

    RegKey keyRead;
    LONG result = keyRead.Open(HKEY_CURRENT_USER, REG_KEY_PATH, KEY_READ);

    if (result == ERROR_SUCCESS) {
        hasSystem = GetRegistryValue(keyRead.Get(), SYSTEM_VALUE_NAME, systemValue);
        hasApps = GetRegistryValue(keyRead.Get(), APPS_VALUE_NAME, appsValue);
        return RegistryStatus::Success;
    }

    if (result == ERROR_FILE_NOT_FOUND || result == ERROR_PATH_NOT_FOUND) {
        return RegistryStatus::KeyNotFound;
    }

    if (result == ERROR_ACCESS_DENIED) {
        return RegistryStatus::AccessDenied;
    }
    return RegistryStatus::OtherError;
}

bool RegistryManager::WriteTheme(DWORD value, DWORD prevSystem, bool hadSystem) {
    RegKey keyWrite;
    LONG result = keyWrite.CreateOrOpen(HKEY_CURRENT_USER, REG_KEY_PATH, KEY_WRITE);

    if (result != ERROR_SUCCESS || !keyWrite.IsValid()) {
        return false;
    }

    if (!SetRegistryValue(keyWrite.Get(), SYSTEM_VALUE_NAME, value)) {
        return false;
    }

    if (!SetRegistryValue(keyWrite.Get(), APPS_VALUE_NAME, value)) {
        RestoreValue(keyWrite.Get(), SYSTEM_VALUE_NAME, hadSystem, prevSystem);
        return false;
    }

    // Transfer ownership for flush
    keyWrite_ = std::move(keyWrite);
    return true;
}

bool RegistryManager::Flush() {
    if (!keyWrite_.IsValid()) return true;

    LONG result = RegFlushKey(keyWrite_.Get());
    // Unconditional close
    keyWrite_.Close();

    return result == ERROR_SUCCESS;
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
