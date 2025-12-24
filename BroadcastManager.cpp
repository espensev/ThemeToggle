#include "BroadcastManager.h"
#include <dwmapi.h>

#pragma comment(lib, "dwmapi.lib")

// Hash table of apps that commonly miss theme changes
static const StubbornApp STUBBORN_APPS[] = {
    { L"CabinetWClass", nullptr, WM_THEMECHANGED, true },                    // File Explorer
    { L"#32770", nullptr, WM_SYSCOLORCHANGE, true },                         // Dialogs
    { L"OpusApp", nullptr, WM_SETTINGCHANGE, true },                         // Office apps
    { L"HwndWrapper", nullptr, WM_THEMECHANGED, true },                      // WPF apps (VS, etc)
    { L"CASCADIA_HOSTING_WINDOW_CLASS", nullptr, WM_SETTINGCHANGE, true },  // Windows Terminal
    { L"Chrome_WidgetWin_1", nullptr, WM_THEMECHANGED, false },              // Chrome (optional)
    { L"MozillaWindowClass", nullptr, WM_THEMECHANGED, false },              // Firefox (optional)
};

BroadcastManager::BroadcastManager(bool isWindows11) : isWin11(isWindows11) {}

int BroadcastManager::BroadcastThemeChange(bool isDark, bool enableKick) {
    hadFailure.store(false, std::memory_order_relaxed);

    BroadcastSystemWindows(L"ImmersiveColorSet");
    NotifyDWM(isDark);
    BroadcastGlobal();

    if (!enableKick) return 0;

    // Give stubborn apps an extra kick
    return KickStubbornApps();
}

void BroadcastManager::BroadcastToWindow(HWND hwnd, const wchar_t* message) {
    if (hwnd && IsWindow(hwnd)) {
        if (!SendNotifyMessageW(hwnd, WM_SETTINGCHANGE, 0, reinterpret_cast<LPARAM>(message))) {
            hadFailure.store(true, std::memory_order_relaxed);
        }
    }
}

void BroadcastManager::BroadcastSystemWindows(const wchar_t* message) {
    // Find taskbar
    HWND hwndTaskbar = FindWindowW(L"Shell_TrayWnd", nullptr);
    if (!hwndTaskbar) {
        // Explorer may be restarting; short retry to catch it
        Sleep(75);
        hwndTaskbar = FindWindowW(L"Shell_TrayWnd", nullptr);
    }
    BroadcastToWindow(hwndTaskbar, message);

    // Find notification area
    HWND hwndTray = FindWindowExW(hwndTaskbar, nullptr, L"TrayNotifyWnd", nullptr);
    BroadcastToWindow(hwndTray, message);

    // Find system tray (secondary monitors)
    HWND hwndSysTray = FindWindowW(L"Shell_SecondaryTrayWnd", nullptr);
    BroadcastToWindow(hwndSysTray, message);

    // Find Settings app
    HWND hwndSettings = FindWindowW(L"ApplicationFrameWindow", nullptr);
    BroadcastToWindow(hwndSettings, message);

    // Windows 11: Find Widgets panel
    if (isWin11) {
        HWND hwndWidgets = FindWindowW(L"Windows.UI.Composition.DesktopWindowContentBridge", nullptr);
        BroadcastToWindow(hwndWidgets, message);
    }
}

void BroadcastManager::NotifyDWM(bool isDark) {
    BOOL useDarkMode = isDark ? TRUE : FALSE;
    HRESULT hr = DwmSetWindowAttribute(GetDesktopWindow(), DWMWA_USE_IMMERSIVE_DARK_MODE,
        &useDarkMode, sizeof(useDarkMode));
    if (FAILED(hr)) {
        hadFailure.store(true, std::memory_order_relaxed);
    }
}

void BroadcastManager::BroadcastGlobal() {
    LPARAM immersiveParam = reinterpret_cast<LPARAM>(L"ImmersiveColorSet");
    if (!SendNotifyMessageW(HWND_BROADCAST, WM_SETTINGCHANGE, 0, immersiveParam)) {
        hadFailure.store(true, std::memory_order_relaxed);
    }
    if (!SendNotifyMessageW(HWND_BROADCAST, WM_THEMECHANGED, 0, 0)) {
        hadFailure.store(true, std::memory_order_relaxed);
    }

    if (isWin11) {
        LPARAM accentParam = reinterpret_cast<LPARAM>(L"WindowsAccentColor");
        if (!SendNotifyMessageW(HWND_BROADCAST, WM_SETTINGCHANGE, 0, accentParam)) {
            hadFailure.store(true, std::memory_order_relaxed);
        }

        LPARAM metricsParam = reinterpret_cast<LPARAM>(L"WindowMetrics");
        if (!SendNotifyMessageW(HWND_BROADCAST, WM_SETTINGCHANGE, 0, metricsParam)) {
            hadFailure.store(true, std::memory_order_relaxed);
        }
    }
    else {
        LPARAM colorizationParam = reinterpret_cast<LPARAM>(L"ColorizationColor");
        if (!SendNotifyMessageW(HWND_BROADCAST, WM_SETTINGCHANGE, 0, colorizationParam)) {
            hadFailure.store(true, std::memory_order_relaxed);
        }
    }
}

BOOL CALLBACK BroadcastManager::EnumWindowsProc(HWND hwnd, LPARAM lParam) {
    if (!IsWindowVisible(hwnd)) return TRUE;

    auto* ctx = reinterpret_cast<EnumWindowsContext*>(lParam);
    if (!ctx || !ctx->manager) {
        return TRUE;
    }
    wchar_t className[256] = {};
    wchar_t windowTitle[256] = {};

    GetClassNameW(hwnd, className, 256);
    GetWindowTextW(hwnd, windowTitle, 256);

    // Check against stubborn app list
    for (const auto& app : STUBBORN_APPS) {
        bool classMatch = (app.className && _wcsicmp(className, app.className) == 0);
        bool titleMatch = (!app.windowTitle ||
            (windowTitle[0] && wcsstr(windowTitle, app.windowTitle)));

        if (classMatch && titleMatch) {
            // Give this app an extra kick
            if (app.needsDirectPost) {
                if (!PostMessageW(hwnd, app.extraMessage, 0,
                    reinterpret_cast<LPARAM>(L"ImmersiveColorSet"))) {
                    ctx->manager->hadFailure.store(true, std::memory_order_relaxed);
                }
            }
            else {
                if (!SendNotifyMessageW(hwnd, app.extraMessage, 0,
                    reinterpret_cast<LPARAM>(L"ImmersiveColorSet"))) {
                    ctx->manager->hadFailure.store(true, std::memory_order_relaxed);
                }
            }

            // Also send WM_SETTINGCHANGE for good measure
            if (!SendNotifyMessageW(hwnd, WM_SETTINGCHANGE, 0,
                reinterpret_cast<LPARAM>(L"ImmersiveColorSet"))) {
                ctx->manager->hadFailure.store(true, std::memory_order_relaxed);
            }

            ctx->kickCount++;
            break;
        }
    }

    return TRUE;
}

int BroadcastManager::KickStubbornApps() {
    // Skip extra kick for remote sessions to reduce overhead
    if (GetSystemMetrics(SM_REMOTESESSION)) {
        return 0;
    }

    // Quick pre-check: if none of the common targets are present, skip enumeration
    bool likelyTargetsPresent = false;
    if (FindWindowW(L"CabinetWClass", nullptr)) likelyTargetsPresent = true;
    else if (FindWindowW(L"HwndWrapper", nullptr)) likelyTargetsPresent = true;
    else if (FindWindowW(L"CASCADIA_HOSTING_WINDOW_CLASS", nullptr)) likelyTargetsPresent = true;
    else if (FindWindowW(L"OpusApp", nullptr)) likelyTargetsPresent = true;

    if (!likelyTargetsPresent) {
        return 0;
    }

    EnumWindowsContext ctx{};
    ctx.manager = this;
    EnumWindows(EnumWindowsProc, reinterpret_cast<LPARAM>(&ctx));
    return ctx.kickCount;
}
