#pragma once
#include <windows.h>
#include <atomic>
#include "Types.h"

// Stubborn apps that need extra notification kick
struct StubbornApp {
    const wchar_t* className;
    const wchar_t* windowTitle;
    UINT extraMessage;
    bool needsDirectPost;
};

class BroadcastManager {
public:
    explicit BroadcastManager(bool isWindows11);

    // Main broadcast method - returns number of stubborn apps kicked
    int BroadcastThemeChange(bool isDark, bool enableKick = true);

    // Whether any broadcast attempt failed during the last run
    bool HadBroadcastFailure() const { return hadFailure.load(); }

private:
    bool isWin11;

    // Parallel broadcast methods
    void BroadcastSystemWindows(const wchar_t* message);
    void BroadcastGlobal();
    void NotifyDWM(bool isDark);

    // Stubborn app handling
    int KickStubbornApps();
    static BOOL CALLBACK EnumWindowsProc(HWND hwnd, LPARAM lParam);

    // Helper
    void BroadcastToWindow(HWND hwnd, const wchar_t* message);

    // Context for window enumeration
    struct EnumWindowsContext {
        BroadcastManager* manager = nullptr;
        int kickCount = 0;
    };

    std::atomic_bool hadFailure{ false };
};
