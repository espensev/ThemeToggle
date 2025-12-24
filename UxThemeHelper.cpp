#include "UxThemeHelper.h"

UxThemeHelper::UxThemeHelper() = default;

void UxThemeHelper::LoadApis() {
    // Use GetModuleHandle instead of LoadLibrary since uxtheme.dll is already loaded
    // This avoids incrementing reference count and needing to call FreeLibrary
    HMODULE hUxTheme = GetModuleHandleW(L"uxtheme.dll");
    if (!hUxTheme) return;

    // Ordinal-based loading (undocumented APIs)
    SetPreferredAppMode = reinterpret_cast<fnSetPreferredAppMode>(
        GetProcAddress(hUxTheme, MAKEINTRESOURCEA(135)));
    FlushMenuThemes = reinterpret_cast<fnFlushMenuThemes>(
        GetProcAddress(hUxTheme, MAKEINTRESOURCEA(136)));
    RefreshImmersiveColorPolicyState = reinterpret_cast<fnRefreshImmersiveColorPolicyState>(
        GetProcAddress(hUxTheme, MAKEINTRESOURCEA(104)));
}

void UxThemeHelper::SyncTheme(bool isDark) {
    // Force immediate theme policy refresh
    if (RefreshImmersiveColorPolicyState) {
        RefreshImmersiveColorPolicyState();
    }

    // Flush all menu themes for instant context menu updates
    if (FlushMenuThemes) {
        FlushMenuThemes();
    }

    // Set preferred app mode (helps some apps detect theme instantly)
    if (SetPreferredAppMode) {
        SetPreferredAppMode(isDark ? ForceDark : ForceLight);
    }
}
