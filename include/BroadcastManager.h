#pragma once
#include <windows.h>
#include "Types.h"

// Stubborn app definition
struct StubbornApp {
    const wchar_t* className;
    UINT extraMessage;
    bool needsDirectPost;
    bool prefixMatch;       // Prefix match
    bool isCore;            // Core app class
};

class BroadcastManager {
public:
    explicit BroadcastManager(bool isWindows11);

    // Broadcast theme change
    int BroadcastThemeChange(bool isDark, KickPolicy kickPolicy = KickPolicy::All);

    // Last run failure status
    bool HadBroadcastFailure() const { return hadFailure; }

private:
    bool isWin11;
    ULONGLONG lastEnumTick = 0;
    bool lastFoundTargets = false;
    KickPolicy lastKickPolicy = KickPolicy::All;

    // Broadcasts
    void BroadcastSystemWindows(const wchar_t* message);
    void BroadcastGlobal();
    void NotifyDWM(bool isDark);

    // Stubborn apps
    int KickStubbornApps(KickPolicy kickPolicy);
    bool HasFastTarget(KickPolicy kickPolicy);
    static BOOL CALLBACK EnumWindowsProc(HWND hwnd, LPARAM lParam);

    // Helpers
    void BroadcastToWindow(HWND hwnd, const wchar_t* message);

    // Enum context
    struct EnumWindowsContext {
        BroadcastManager* manager = nullptr;
        int kickCount = 0;
        KickPolicy kickPolicy = KickPolicy::All;
    };

    bool hadFailure = false;
};
