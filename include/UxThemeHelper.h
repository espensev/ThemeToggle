#pragma once
#include <windows.h>

// Undocumented uxtheme.dll exports (ordinal-only)
enum class PreferredAppMode { Default, AllowDark, ForceDark, ForceLight, Max };
typedef DWORD(WINAPI* fnSetPreferredAppMode)(PreferredAppMode appMode);
typedef void (WINAPI* fnFlushMenuThemes)();
typedef void (WINAPI* fnRefreshImmersiveColorPolicyState)();

class UxThemeHelper {
public:
    UxThemeHelper();
    ~UxThemeHelper();

    UxThemeHelper(const UxThemeHelper&) = delete;
    UxThemeHelper& operator=(const UxThemeHelper&) = delete;

    // Load APIs
    void LoadApis();

    // Sync theme
    void SyncTheme(bool isDark);

    // Diagnostics
    bool HasSetPreferredAppMode() const { return SetPreferredAppMode != nullptr; }
    bool HasFlushMenuThemes() const { return FlushMenuThemes != nullptr; }
    bool HasRefreshImmersiveColorPolicyState() const { return RefreshImmersiveColorPolicyState != nullptr; }
    bool IsFullyLoaded() const { return HasSetPreferredAppMode() && HasFlushMenuThemes() && HasRefreshImmersiveColorPolicyState(); }

private:
    HMODULE hUxThemeLoaded = nullptr;  // Non-null if we called LoadLibraryW
    fnSetPreferredAppMode SetPreferredAppMode = nullptr;
    fnFlushMenuThemes FlushMenuThemes = nullptr;
    fnRefreshImmersiveColorPolicyState RefreshImmersiveColorPolicyState = nullptr;
};
