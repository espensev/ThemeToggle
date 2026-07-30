#include "BroadcastManager.h"
#include "StageTimer.h"
#include <dwmapi.h>

#pragma comment(lib, "dwmapi.lib")

namespace {
constexpr DWORD CLASSNAME_BUFFER_SIZE = 256;
}

// Stubborn apps — a small, empirical compatibility list, not a catalogue.
// Conformant apps already react to the global broadcast sequence; add an entry
// only for a reproduced miss, with a pointer-free message that demonstrably
// fixes it. Targeted async delivery rejects pointer payloads such as the
// WM_SETTINGCHANGE lParam string (ERROR_MESSAGE_SYNC_ONLY), so string-bearing
// nudges cannot live in this table — the global broadcast carries them.
// { className, extraMessage, needsDirectPost, prefixMatch, isCore }
static const StubbornApp STUBBORN_APPS[] = {
    { L"CabinetWClass",      WM_THEMECHANGED,   true,  false, true  }, // File Explorer
    { L"#32770",             WM_SYSCOLORCHANGE, true,  false, true  }, // Common dialogs
    { L"Chrome_WidgetWin_1", WM_THEMECHANGED,   false, false, false }, // Chromium/Electron family (Chrome, Edge, VS Code, ...)
    { L"MozillaWindowClass", WM_THEMECHANGED,   false, false, false }, // Firefox
};

BroadcastManager::BroadcastManager(bool isWindows11) : isWin11(isWindows11) {}

int BroadcastManager::BroadcastThemeChange(bool isDark, KickPolicy kickPolicy) {
    hadFailure = false;
    dwmMs = globalMs = kickMs = 0.0;

    StageTimer timer;

    // Kick first, while the desktop is still quiet: enumerating windows after
    // the global broadcast costs ~10x more because every window is already
    // busy processing the theme change. The registry write and uxtheme sync
    // have completed by now, so kicked apps re-read the new state either way.
    int kicked = 0;
    if (kickPolicy != KickPolicy::None) {
        kicked = KickStubbornApps(kickPolicy);
    }
    kickMs = timer.LapMs();

    // No per-window shell pokes here: the OS rejects targeted async sends of
    // WM_SETTINGCHANGE (ERROR_MESSAGE_SYNC_ONLY), and the shell windows —
    // taskbar, tray, secondary-monitor taskbars — are top-level windows that
    // receive the global broadcast below.
    NotifyDWM(isDark);
    dwmMs = timer.LapMs();

    BroadcastGlobal();
    globalMs = timer.LapMs();

    return kicked;
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
    if (!ctx) return TRUE;

    wchar_t className[CLASSNAME_BUFFER_SIZE] = {};
    if (!GetClassNameW(hwnd, className, CLASSNAME_BUFFER_SIZE)) return TRUE;

    // Linear scan (small fixed table)
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

    // Pointer-free messages only (see table comment): posted for queue-path
    // delivery, or sent async. Kicks are best-effort by design, so a miss
    // (e.g. an elevated window blocked by UIPI) never fails the toggle.
    bool delivered = match->needsDirectPost
        ? PostMessageW(hwnd, match->extraMessage, 0, 0) != 0
        : SendNotifyMessageW(hwnd, match->extraMessage, 0, 0) != 0;

    if (delivered) {
        ctx->kickCount++;
    }
    return TRUE;
}

int BroadcastManager::KickStubbornApps(KickPolicy kickPolicy) {
    // Skip in remote sessions
    if (GetSystemMetrics(SM_REMOTESESSION)) return 0;

    EnumWindowsContext ctx{ 0, kickPolicy };
    EnumWindows(EnumWindowsProc, reinterpret_cast<LPARAM>(&ctx));
    return ctx.kickCount;
}
