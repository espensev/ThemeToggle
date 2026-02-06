#include "UxThemeHelper.h"

UxThemeHelper::UxThemeHelper() = default;

UxThemeHelper::~UxThemeHelper() {
    if (hUxThemeLoaded) {
        FreeLibrary(hUxThemeLoaded);
    }
}

void UxThemeHelper::LoadApis() {
    // Try existing handle first
    HMODULE hUxTheme = GetModuleHandleW(L"uxtheme.dll");

    // Fallback to LoadLibraryW if not already loaded
    if (!hUxTheme) {
        hUxTheme = LoadLibraryW(L"uxtheme.dll");
        if (hUxTheme) {
            hUxThemeLoaded = hUxTheme;  // Track for cleanup
        }
    }

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
    // Undocumented APIs - optimal call order is uncertain.
    // Current order: refresh policy → flush menus → set mode
    // Alternative: refresh → set mode → flush (set before rebuilding caches)
    // Testing suggests both work; keeping conservative order.
    
    // Refresh policy (reloads color settings from registry)
    if (RefreshImmersiveColorPolicyState) {
        RefreshImmersiveColorPolicyState();
    }

    // Flush menu themes (clears cached menu visuals)
    if (FlushMenuThemes) {
        FlushMenuThemes();
    }

    // Set preferred mode (configures dark/light for new windows)
    if (SetPreferredAppMode) {
        SetPreferredAppMode(isDark ? PreferredAppMode::ForceDark : PreferredAppMode::ForceLight);
    }
}
