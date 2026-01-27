#pragma once
#include <windows.h>

// Undocumented uxtheme.dll
enum PreferredAppMode { Default, AllowDark, ForceDark, ForceLight, Max };
typedef DWORD(WINAPI* fnSetPreferredAppMode)(PreferredAppMode appMode);
typedef void (WINAPI* fnFlushMenuThemes)();
typedef void (WINAPI* fnRefreshImmersiveColorPolicyState)();

class UxThemeHelper {
public:
    UxThemeHelper();

    // Load APIs
    void LoadApis();

    // Sync theme
    void SyncTheme(bool isDark);

private:
    fnSetPreferredAppMode SetPreferredAppMode = nullptr;
    fnFlushMenuThemes FlushMenuThemes = nullptr;
    fnRefreshImmersiveColorPolicyState RefreshImmersiveColorPolicyState = nullptr;
};
