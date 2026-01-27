#include "UxThemeHelper.h"

UxThemeHelper::UxThemeHelper() = default;

void UxThemeHelper::LoadApis() {
    // Use existing handle
    HMODULE hUxTheme = GetModuleHandleW(L"uxtheme.dll");
    if (!hUxTheme) return;

    // Load via ordinal
    SetPreferredAppMode = reinterpret_cast<fnSetPreferredAppMode>(
        GetProcAddress(hUxTheme, MAKEINTRESOURCEA(135)));
    FlushMenuThemes = reinterpret_cast<fnFlushMenuThemes>(
        GetProcAddress(hUxTheme, MAKEINTRESOURCEA(136)));
    RefreshImmersiveColorPolicyState = reinterpret_cast<fnRefreshImmersiveColorPolicyState>(
        GetProcAddress(hUxTheme, MAKEINTRESOURCEA(104)));
}

void UxThemeHelper::SyncTheme(bool isDark) {
    // Refresh policy
    if (RefreshImmersiveColorPolicyState) {
        RefreshImmersiveColorPolicyState();
    }

    // Flush menu themes
    if (FlushMenuThemes) {
        FlushMenuThemes();
    }

    // Set preferred mode
    if (SetPreferredAppMode) {
        SetPreferredAppMode(isDark ? ForceDark : ForceLight);
    }
}
