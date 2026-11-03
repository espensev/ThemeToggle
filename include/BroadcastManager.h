#pragma once
#include <windows.h>
#include "Types.h"

// Stubborn app definition
struct StubbornApp {
    const wchar_t* className;
    UINT extraMessage;      // Must be pointer-free — the OS rejects targeted
                            // async sends of pointer-carrying messages
                            // (ERROR_MESSAGE_SYNC_ONLY)
    bool needsDirectPost;   // Deliver via PostMessage (queue path) instead of
                            // SendNotifyMessage
    bool prefixMatch;       // Match className as prefix
    bool isCore;            // Included in /kick=core (OS surfaces)
};

class BroadcastManager {
public:
    explicit BroadcastManager(bool isWindows11);

    // Broadcast theme change. sendThemeChanged=false (/nothemechanged) omits
    // every WM_THEMECHANGED send — global broadcast and kicks alike — so the
    // light/dark switch is signalled only via WM_SETTINGCHANGE, as Windows
    // Settings does. Diagnostic switch for issue #17.
    int BroadcastThemeChange(bool isDark, KickPolicy kickPolicy = KickPolicy::All,
        bool sendThemeChanged = true);

    // Last run failure status
    bool HadBroadcastFailure() const { return hadFailure; }

    // Last-run stage timings (milliseconds)
    double LastDwmMs() const { return dwmMs; }
    double LastGlobalMs() const { return globalMs; }
    double LastKickMs() const { return kickMs; }

private:
    bool isWin11;
    double dwmMs = 0.0;
    double globalMs = 0.0;
    double kickMs = 0.0;

    // Broadcasts
    void BroadcastGlobal(bool sendThemeChanged);
    void NotifyDWM(bool isDark);

    // Stubborn apps
    int KickStubbornApps(KickPolicy kickPolicy, bool sendThemeChanged);
    static BOOL CALLBACK EnumWindowsProc(HWND hwnd, LPARAM lParam);

    // Enum context
    struct EnumWindowsContext {
        int kickCount = 0;
        KickPolicy kickPolicy = KickPolicy::All;
        bool sendThemeChanged = true;
    };

    bool hadFailure = false;
};
