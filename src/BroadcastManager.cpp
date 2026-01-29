#include "BroadcastManager.h"
#include <dwmapi.h>

#pragma comment(lib, "dwmapi.lib")

namespace {
constexpr DWORD CLASSNAME_BUFFER_SIZE = 256;
constexpr ULONGLONG KICK_ENUM_CACHE_MS = 1500;
}

// Stubborn apps
static const StubbornApp STUBBORN_APPS[] = {
    { L"CabinetWClass", WM_THEMECHANGED, true, false, true },                   // File Explorer
    { L"#32770", WM_SYSCOLORCHANGE, true, false, true },                        // Dialogs
    { L"OpusApp", WM_SETTINGCHANGE, true, false, true },                        // Office apps
    { L"CASCADIA_HOSTING_WINDOW_CLASS", WM_SETTINGCHANGE, true, false, true },  // Windows Terminal
    { L"Chrome_WidgetWin_1", WM_THEMECHANGED, false, false, false },            // Chrome (optional)
    { L"MozillaWindowClass", WM_THEMECHANGED, false, false, false },            // Firefox (optional)
};

BroadcastManager::BroadcastManager(bool isWindows11) : isWin11(isWindows11) {}

int BroadcastManager::BroadcastThemeChange(bool isDark, KickPolicy kickPolicy) {
    hadFailure = false;

    BroadcastSystemWindows(L"ImmersiveColorSet");
    NotifyDWM(isDark);
    BroadcastGlobal();

    if (kickPolicy == KickPolicy::None) return 0;

    // Kick stubborn apps
    return KickStubbornApps(kickPolicy);
}

void BroadcastManager::BroadcastToWindow(HWND hwnd, const wchar_t* message) {
    if (hwnd && IsWindow(hwnd)) {
        if (!SendNotifyMessageW(hwnd, WM_SETTINGCHANGE, 0, reinterpret_cast<LPARAM>(message))) {
            hadFailure = true;
        }
    }
}

bool BroadcastManager::HasFastTarget(KickPolicy kickPolicy) {
    // Exact-match classes only (prefix matches require enumeration)
    const wchar_t* coreClasses[] = {
        L"CabinetWClass",
        L"#32770",
        L"OpusApp",
        L"CASCADIA_HOSTING_WINDOW_CLASS"
    };

    for (const auto* cls : coreClasses) {
        if (FindWindowW(cls, nullptr)) {
            return true;
        }
    }

    if (kickPolicy == KickPolicy::All) {
        const wchar_t* optionalClasses[] = {
            L"Chrome_WidgetWin_1",
            L"MozillaWindowClass"
        };
        for (const auto* cls : optionalClasses) {
            if (FindWindowW(cls, nullptr)) {
                return true;
            }
        }
    }

    return false;
}

void BroadcastManager::BroadcastSystemWindows(const wchar_t* message) {
    // Taskbar
    HWND hwndTaskbar = FindWindowW(L"Shell_TrayWnd", nullptr);
    BroadcastToWindow(hwndTaskbar, message);

    // Notification area
    if (hwndTaskbar) {
        HWND hwndTray = FindWindowExW(hwndTaskbar, nullptr, L"TrayNotifyWnd", nullptr);
        BroadcastToWindow(hwndTray, message);
    }

    // System tray (secondary monitors)
    HWND hwndSysTray = FindWindowW(L"Shell_SecondaryTrayWnd", nullptr);
    BroadcastToWindow(hwndSysTray, message);

    // Win11 Widgets
    if (isWin11) {
        HWND hwndWidgets = FindWindowW(L"Windows.UI.Composition.DesktopWindowContentBridge", nullptr);
        BroadcastToWindow(hwndWidgets, message);
    }
}

void BroadcastManager::NotifyDWM(bool isDark) {
    BOOL useDarkMode = isDark ? TRUE : FALSE;
    // Best-effort; DWM failure is not a broadcast failure
    DwmSetWindowAttribute(GetDesktopWindow(), DWMWA_USE_IMMERSIVE_DARK_MODE,
        &useDarkMode, sizeof(useDarkMode));
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

    if (ctx->kickPolicy == KickPolicy::Core && !match->isCore) {
        return TRUE;
    }

    LPARAM colorParam = reinterpret_cast<LPARAM>(L"ImmersiveColorSet");

    // Delivery method selection
    bool success = match->needsDirectPost
        ? PostMessageW(hwnd, match->extraMessage, 0, colorParam)
        : SendNotifyMessageW(hwnd, match->extraMessage, 0, colorParam);

    if (!success) {
        ctx->manager->hadFailure = true;
    }

    ctx->kickCount++;
    return TRUE;
}

int BroadcastManager::KickStubbornApps(KickPolicy kickPolicy) {
    // Skip in remote sessions
    if (GetSystemMetrics(SM_REMOTESESSION)) return 0;

    const ULONGLONG now = GetTickCount64();
    if (kickPolicy == lastKickPolicy) {
        if (!HasFastTarget(kickPolicy) && !lastFoundTargets && (now - lastEnumTick) < KICK_ENUM_CACHE_MS) {
            return 0;
        }
    }

    EnumWindowsContext ctx{ this, 0, kickPolicy };
    EnumWindows(EnumWindowsProc, reinterpret_cast<LPARAM>(&ctx));
    lastFoundTargets = ctx.kickCount > 0;
    lastEnumTick = now;
    lastKickPolicy = kickPolicy;
    return ctx.kickCount;
}
