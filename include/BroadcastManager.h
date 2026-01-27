#pragma once
#include <windows.h>
#include "Types.h"

// Stubborn app definition
struct StubbornApp {
    const wchar_t* className;
    const wchar_t* windowTitle;
    UINT extraMessage;
    bool needsDirectPost;
    bool prefixMatch;       // Prefix match
};

class BroadcastManager {
public:
    explicit BroadcastManager(bool isWindows11);

    // Broadcast theme change
    int BroadcastThemeChange(bool isDark, bool enableKick = true);

    // Last run failure status
    bool HadBroadcastFailure() const { return hadFailure; }

private:
    bool isWin11;

    // Broadcasts
    void BroadcastSystemWindows(const wchar_t* message);
    void BroadcastGlobal();
    void NotifyDWM(bool isDark);

    // Stubborn apps
    int KickStubbornApps();
    static BOOL CALLBACK EnumWindowsProc(HWND hwnd, LPARAM lParam);

    // Helpers
    void BroadcastToWindow(HWND hwnd, const wchar_t* message);

    // Enum context
    struct EnumWindowsContext {
        BroadcastManager* manager = nullptr;
        int kickCount = 0;
    };

    bool hadFailure = false;
};
