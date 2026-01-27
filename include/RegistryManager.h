#pragma once
#include <windows.h>
#include "Types.h"

class RegistryManager {
public:
    RegistryManager() = default;

    // Read theme values
    RegistryStatus ReadTheme(DWORD& systemValue, DWORD& appsValue, bool& hasSystem, bool& hasApps);

    // Write values with rollback support
    bool WriteTheme(DWORD value, DWORD prevSystem, bool hadSystem);

    // Flush to disk
    bool Flush();

private:
    static constexpr const wchar_t* REG_KEY_PATH = L"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize";
    static constexpr const wchar_t* SYSTEM_VALUE_NAME = L"SystemUsesLightTheme";
    static constexpr const wchar_t* APPS_VALUE_NAME = L"AppsUseLightTheme";

    RegKey keyWrite_;

    bool GetRegistryValue(HKEY hKey, const wchar_t* valueName, DWORD& outValue);
    bool SetRegistryValue(HKEY hKey, const wchar_t* valueName, DWORD value);
    void RestoreValue(HKEY hKey, const wchar_t* valueName, bool hadValue, DWORD value);
};
