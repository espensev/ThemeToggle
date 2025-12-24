#pragma once
#include <windows.h>

class RegistryManager {
public:
    RegistryManager();

    // Read current theme values
    bool ReadTheme(DWORD& systemValue, DWORD& appsValue, bool& hasSystem, bool& hasApps);

    // Write theme values, reverting to previous state if a partial failure occurs
    bool WriteTheme(DWORD value, DWORD prevSystem, bool hadSystem);

    // Flush registry changes to disk
    bool Flush();

private:
    static constexpr const wchar_t* REG_KEY_PATH = L"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize";
    static constexpr const wchar_t* SYSTEM_VALUE_NAME = L"SystemUsesLightTheme";
    static constexpr const wchar_t* APPS_VALUE_NAME = L"AppsUseLightTheme";

    HKEY hKeyWrite = nullptr;

    bool GetRegistryValue(HKEY hKey, const wchar_t* valueName, DWORD& outValue);
    bool SetRegistryValue(HKEY hKey, const wchar_t* valueName, DWORD value);
    void RestoreValue(HKEY hKey, const wchar_t* valueName, bool hadValue, DWORD value);
};
