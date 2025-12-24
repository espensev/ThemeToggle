#pragma once
#include <windows.h>

// Undocumented uxtheme.dll functions for instant theme refresh (Windows 11)
enum PreferredAppMode { Default, AllowDark, ForceDark, ForceLight, Max };
typedef DWORD(WINAPI* fnSetPreferredAppMode)(PreferredAppMode appMode);
typedef void (WINAPI* fnFlushMenuThemes)();
typedef void (WINAPI* fnRefreshImmersiveColorPolicyState)();

class UxThemeHelper {
public:
    UxThemeHelper();

    // Load undocumented APIs (call once at startup)
    void LoadApis();

    // Call APIs to sync theme instantly
    void SyncTheme(bool isDark);

private:
    fnSetPreferredAppMode SetPreferredAppMode = nullptr;
    fnFlushMenuThemes FlushMenuThemes = nullptr;
    fnRefreshImmersiveColorPolicyState RefreshImmersiveColorPolicyState = nullptr;
};
