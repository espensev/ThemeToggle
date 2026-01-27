#include "BroadcastManager.h"
#include <dwmapi.h>

#pragma comment(lib, "dwmapi.lib")

namespace {
constexpr DWORD CLASSNAME_BUFFER_SIZE = 256;
constexpr DWORD TITLE_BUFFER_SIZE = 256;
}

// Stubborn apps
static const StubbornApp STUBBORN_APPS[] = {
    { L"CabinetWClass", nullptr, WM_THEMECHANGED, true, false },                   // File Explorer
    { L"#32770", nullptr, WM_SYSCOLORCHANGE, true, false },                        // Dialogs
    { L"OpusApp", nullptr, WM_SETTINGCHANGE, true, false },                        // Office apps
    { L"HwndWrapper", nullptr, WM_THEMECHANGED, true, true },                      // WPF apps
    { L"CASCADIA_HOSTING_WINDOW_CLASS", nullptr, WM_SETTINGCHANGE, true, false },  // Windows Terminal
    { L"Chrome_WidgetWin_1", nullptr, WM_THEMECHANGED, false, false },             // Chrome (optional)
    { L"MozillaWindowClass", nullptr, WM_THEMECHANGED, false, false },             // Firefox (optional)
};

BroadcastManager::BroadcastManager(bool isWindows11) : isWin11(isWindows11) {}

int BroadcastManager::BroadcastThemeChange(bool isDark, bool enableKick) {
    hadFailure = false;

    BroadcastSystemWindows(L"ImmersiveColorSet");
    NotifyDWM(isDark);
    BroadcastGlobal();

    if (!enableKick) return 0;

    // Kick stubborn apps
    return KickStubbornApps();
}

void BroadcastManager::BroadcastToWindow(HWND hwnd, const wchar_t* message) {
    if (hwnd && IsWindow(hwnd)) {
        if (!SendNotifyMessageW(hwnd, WM_SETTINGCHANGE, 0, reinterpret_cast<LPARAM>(message))) {
            hadFailure = true;
        }
    }
}

void BroadcastManager::BroadcastSystemWindows(const wchar_t* message) {
    // Taskbar
    HWND hwndTaskbar = FindWindowW(L"Shell_TrayWnd", nullptr);
    if (!hwndTaskbar) {
        // Explorer restart retry
        Sleep(75);
        hwndTaskbar = FindWindowW(L"Shell_TrayWnd", nullptr);
    }
    BroadcastToWindow(hwndTaskbar, message);

    // Notification area
    HWND hwndTray = FindWindowExW(hwndTaskbar, nullptr, L"TrayNotifyWnd", nullptr);
    BroadcastToWindow(hwndTray, message);

    // System tray (secondary monitors)
    HWND hwndSysTray = FindWindowW(L"Shell_SecondaryTrayWnd", nullptr);
    BroadcastToWindow(hwndSysTray, message);

    // Settings app
    HWND hwndSettings = FindWindowW(L"ApplicationFrameWindow", nullptr);
    BroadcastToWindow(hwndSettings, message);

    // Win11 Widgets
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
        hadFailure = true;
    }
}

void BroadcastManager::BroadcastGlobal() {
    LPARAM immersiveParam = reinterpret_cast<LPARAM>(L"ImmersiveColorSet");
    if (!SendNotifyMessageW(HWND_BROADCAST, WM_SETTINGCHANGE, 0, immersiveParam)) {
        hadFailure = true;
    }
    if (!SendNotifyMessageW(HWND_BROADCAST, WM_THEMECHANGED, 0, 0)) {
        hadFailure = true;
    }

    if (isWin11) {
        LPARAM accentParam = reinterpret_cast<LPARAM>(L"WindowsAccentColor");
        if (!SendNotifyMessageW(HWND_BROADCAST, WM_SETTINGCHANGE, 0, accentParam)) {
            hadFailure = true;
        }

        LPARAM metricsParam = reinterpret_cast<LPARAM>(L"WindowMetrics");
        if (!SendNotifyMessageW(HWND_BROADCAST, WM_SETTINGCHANGE, 0, metricsParam)) {
            hadFailure = true;
        }
    }
    else {
        LPARAM colorizationParam = reinterpret_cast<LPARAM>(L"ColorizationColor");
        if (!SendNotifyMessageW(HWND_BROADCAST, WM_SETTINGCHANGE, 0, colorizationParam)) {
            hadFailure = true;
        }
    }
}

BOOL CALLBACK BroadcastManager::EnumWindowsProc(HWND hwnd, LPARAM lParam) {
    if (!IsWindowVisible(hwnd)) return TRUE;

    auto* ctx = reinterpret_cast<EnumWindowsContext*>(lParam);
    if (!ctx || !ctx->manager) return TRUE;

    wchar_t className[CLASSNAME_BUFFER_SIZE] = {};
    if (!GetClassNameW(hwnd, className, CLASSNAME_BUFFER_SIZE)) return TRUE;

    // Linear scan (N=7)
    const StubbornApp* match = nullptr;
    for (const auto& app : STUBBORN_APPS) {
        if (!app.className) continue;
        bool matched = app.prefixMatch
            ? _wcsnicmp(className, app.className, wcslen(app.className)) == 0
            : _wcsicmp(className, app.className) == 0;
        if (matched) {
            match = &app;
            break;
        }
    }
    if (!match) return TRUE;

    // Conditional title fetch
    if (match->windowTitle) {
        wchar_t windowTitle[TITLE_BUFFER_SIZE] = {};
        GetWindowTextW(hwnd, windowTitle, TITLE_BUFFER_SIZE);
        if (!windowTitle[0] || !wcsstr(windowTitle, match->windowTitle)) {
            return TRUE;
        }
    }

    LPARAM colorParam = reinterpret_cast<LPARAM>(L"ImmersiveColorSet");

    // Delivery method selection
    bool success = match->needsDirectPost
        ? PostMessageW(hwnd, match->extraMessage, 0, colorParam)
        : SendNotifyMessageW(hwnd, match->extraMessage, 0, colorParam);

    if (!success) {
        ctx->manager->hadFailure = true;
    }

    // Redundant broadcast
    if (!SendNotifyMessageW(hwnd, WM_SETTINGCHANGE, 0, colorParam)) {
        ctx->manager->hadFailure = true;
    }

    ctx->kickCount++;
    return TRUE;
}

int BroadcastManager::KickStubbornApps() {
    // Skip in remote sessions
    if (GetSystemMetrics(SM_REMOTESESSION)) return 0;

    // Optimization: Fast check
    const wchar_t* fastCheckClasses[] = {
        L"CabinetWClass", L"CASCADIA_HOSTING_WINDOW_CLASS", L"OpusApp"
    };

    bool targetFound = false;
    for (const auto* cls : fastCheckClasses) {
        if (FindWindowW(cls, nullptr)) {
            targetFound = true;
            break;
        }
    }

    if (!targetFound) return 0;

    EnumWindowsContext ctx{ this, 0 };
    EnumWindows(EnumWindowsProc, reinterpret_cast<LPARAM>(&ctx));
    return ctx.kickCount;
}
