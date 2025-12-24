#include <windows.h>
#include <iostream>
#include <string>
#include <sstream>
#include <vector>
#include <cstdio>
#include <shellapi.h>

#include "Types.h"
#include "RegistryManager.h"
#include "BroadcastManager.h"
#include "UxThemeHelper.h"

namespace {
bool g_hasConsole = false;

std::string WideToUtf8(const std::wstring& wide) {
    if (wide.empty()) {
        return {};
    }
    int required = WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), -1, nullptr, 0, nullptr, nullptr);
    if (required <= 0) {
        return {};
    }
    std::string utf8(static_cast<size_t>(required - 1), '\0');
    WideCharToMultiByte(CP_UTF8, 0, wide.c_str(), -1, utf8.data(), required, nullptr, nullptr);
    return utf8;
}

std::wstring Utf8ToWide(const std::string& text) {
    if (text.empty()) {
        return {};
    }
    int required = MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, nullptr, 0);
    if (required <= 0) {
        return {};
    }
    std::wstring wide(static_cast<size_t>(required - 1), L'\0');
    MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, wide.data(), required);
    return wide;
}

void EnsureConsoleStreams() {
    if (!g_hasConsole) {
        return;
    }
    FILE* dummy = nullptr;
    freopen_s(&dummy, "CONOUT$", "w", stdout);
    freopen_s(&dummy, "CONOUT$", "w", stderr);
}

void ShowGuiMessage(const std::string& text, UINT icon) {
    if (g_hasConsole) {
        return;
    }
    auto wide = Utf8ToWide(text);
    MessageBoxW(nullptr, wide.c_str(), L"ThemeToggle", MB_OK | icon);
}
}

class WindowsThemeToggler {
private:
    static constexpr WORD DEFAULT_CONSOLE_COLOR = FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE;
    static constexpr const wchar_t* MUTEX_NAME = L"Global\\WindowsThemeToggler_SingleInstance";

    bool quiet;
    bool passThru;
    bool noKick;
    HANDLE hConsole;
    bool isWin11;

    RegistryManager registry;
    BroadcastManager broadcaster;
    UxThemeHelper uxtheme;

    // Detect Windows version
    static bool IsWindows11OrGreater() {
        RegKey key;
        if (key.Open(HKEY_LOCAL_MACHINE, L"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion", KEY_READ) != ERROR_SUCCESS) {
            return false;
        }

        wchar_t buildStr[32] = {};
        DWORD dataSize = sizeof(buildStr);
        DWORD type = 0;

        if (RegQueryValueExW(key, L"CurrentBuild", nullptr, &type,
            reinterpret_cast<LPBYTE>(buildStr), &dataSize) == ERROR_SUCCESS) {
            int build = _wtoi(buildStr);
            return build >= 22000;
        }

        return false;
    }

    void PrintMessage(const std::string& message, bool isWarning = false) {
        if (quiet) return;

        if (hConsole != INVALID_HANDLE_VALUE && hConsole != nullptr) {
            if (isWarning) {
                SetConsoleTextAttribute(hConsole,
                    FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_INTENSITY);
                std::cout << "Warning: ";
            }
            else {
                SetConsoleTextAttribute(hConsole,
                    FOREGROUND_GREEN | FOREGROUND_BLUE | FOREGROUND_INTENSITY);
            }
            std::cout << message << std::endl;
            SetConsoleTextAttribute(hConsole, DEFAULT_CONSOLE_COLOR);
            return;
        }

        if (isWarning) {
            std::cout << "Warning: ";
        }
        std::cout << message << std::endl;
    }

public:
    WindowsThemeToggler(bool quiet = false, bool passThru = false, bool noKick = false)
        : quiet(quiet),
          passThru(passThru),
          noKick(noKick),
          hConsole(nullptr),
          isWin11(IsWindows11OrGreater()),
          broadcaster(isWin11) {

        // Load undocumented APIs for Windows 11
        if (isWin11) {
            uxtheme.LoadApis();
        }

        // Cache console handle
        hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
        if (hConsole != INVALID_HANDLE_VALUE && hConsole != nullptr) {
            DWORD mode;
            if (!GetConsoleMode(hConsole, &mode)) {
                hConsole = nullptr;
            }
        }
    }

    ThemeInfo SetWindowsTheme(bool forceLight, bool forceDark, bool /*toggle*/) {

        ThemeInfo info{};
        info.exitCode = ExitCode::SuccessNoChange;

        // Mutex to prevent concurrent toggles
        MutexGuard mutex(MUTEX_NAME);
        if (!mutex.IsOwned()) {
            if (!quiet) {
                PrintMessage("Another instance is already running.", true);
            }
            info.exitCode = ExitCode::AlreadyRunning;
            return info;
        }

        // Boost process priority for faster execution
        PriorityBoost priorityBoost;

        // Read current theme
        DWORD currSystem = 0;
        DWORD currApps = 0;
        bool hasSystem = false;
        bool hasApps = false;

        if (!registry.ReadTheme(currSystem, currApps, hasSystem, hasApps)) {
            throw ThemeToggleError("Failed to read registry", ExitCode::RegKeyCreateFailed);
        }

        if (!hasSystem) currSystem = 0;
        if (!hasApps) currApps = 0;

        info.oldSystemValue = currSystem;
        info.oldAppsValue = currApps;

        // Decide new target value
        DWORD newValue;
        if (forceLight) {
            newValue = 1;
        }
        else if (forceDark) {
            newValue = 0;
        }
        else {
            newValue = (currSystem == 1) ? 0 : 1;
        }

        // Check if change needed
        bool needsSystemChange = !hasSystem || currSystem != newValue;
        bool needsAppsChange = !hasApps || currApps != newValue;
        bool requiresWrite = needsSystemChange || needsAppsChange;

        if (!requiresWrite) {
            info.newValue = newValue;
            info.changed = false;
            info.broadcastOk = true;
            info.theme = (newValue == 1) ? "Light" : "Dark";
            info.exitCode = ExitCode::SuccessNoChange;

            if (!quiet) {
                std::ostringstream msg;
                msg << "Already " << info.theme << " theme.";
                PrintMessage(msg.str());
            }

            return info;
        }

        info.newValue = newValue;
        info.changed = true;
        info.theme = (newValue == 1) ? "Light" : "Dark";
        bool isDark = (newValue == 0);

        // Write theme to registry
        if (!registry.WriteTheme(newValue, currSystem, hasSystem)) {
            throw ThemeToggleError("Failed writing theme values", ExitCode::RegWriteFailed);
        }

        // Force immediate flush
        if (!registry.Flush()) {
            throw ThemeToggleError("Failed to flush theme values", ExitCode::RegWriteFailed);
        }

        // Call uxtheme APIs for Windows 11 (parallel with broadcasts)
        if (isWin11) {
            uxtheme.SyncTheme(isDark);
        }

        // Broadcast theme change (parallel execution + stubborn app kick)
        int kicked = broadcaster.BroadcastThemeChange(isDark, !noKick);
        info.stubbornAppsKicked = kicked;
        info.broadcastOk = !broadcaster.HadBroadcastFailure();
        if (info.broadcastOk) {
            info.exitCode = (newValue == 1) ? ExitCode::ChangedToLight : ExitCode::ChangedToDark;
        }
        else {
            info.exitCode = ExitCode::BroadcastFailed;
        }

        if (!quiet) {
            std::ostringstream msg;
            msg << "Changed to " << info.theme << " theme.";
            if (!info.broadcastOk) {
                msg << " (broadcast issue detected)";
            }
            PrintMessage(msg.str());
        }

        return info;
    }

    void PrintThemeInfo(const ThemeInfo& info) {
        if (passThru) {
            std::cout << "OldSystemValue: " << info.oldSystemValue << std::endl;
            std::cout << "OldAppsValue: " << info.oldAppsValue << std::endl;
            std::cout << "NewValue: " << info.newValue << std::endl;
            std::cout << "Theme: " << info.theme << std::endl;
            std::cout << "Changed: " << (info.changed ? "true" : "false") << std::endl;
            std::cout << "BroadcastOk: " << (info.broadcastOk ? "true" : "false") << std::endl;
            std::cout << "Windows11: " << (isWin11 ? "true" : "false") << std::endl;
            std::cout << "StubbornAppsKicked: " << info.stubbornAppsKicked << std::endl;
        }
    }
};

void PrintUsage() {
    const std::string usage =
        "Usage: ThemeToggle.exe [options]\n\n"
        "Options:\n"
        "  /light       Force light theme\n"
        "  /dark        Force dark theme\n"
        "  /toggle      Toggle current theme (default)\n"
        "  /quiet       Suppress output\n"
        "  /passthru    Return detailed information\n"
        "  /exitcode    Map result to exit code\n"
        "  /nokick      Do not attempt to kick stubborn apps\n\n"
        "Exit Codes (when /exitcode is used):\n"
        "  0  = Success (no change)\n"
        "  1  = Changed to Light\n"
        "  2  = Changed to Dark\n"
        "  10 = Registry key creation failed\n"
        "  11 = Registry write failed\n"
        "  20 = Broadcast failed but registry ok\n"
        "  30 = Already running (another instance)\n";

    std::cout << usage;
    if (!g_hasConsole) {
        ShowGuiMessage(usage, MB_ICONINFORMATION);
    }
}

int RunThemeToggleCli(int argc, char* argv[]) {
    bool forceLight = false;
    bool forceDark = false;
    bool toggle = false;
    bool quiet = false;
    bool passThru = false;
    bool asExitCode = false;
    bool noKick = false;

    // Parse command-line arguments
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];

        for (auto& c : arg) {
            c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
        }

        if (arg == "/light" || arg == "-light") {
            forceLight = true;
        }
        else if (arg == "/dark" || arg == "-dark") {
            forceDark = true;
        }
        else if (arg == "/toggle" || arg == "-toggle") {
            toggle = true;
        }
        else if (arg == "/quiet" || arg == "-quiet") {
            quiet = true;
        }
        else if (arg == "/passthru" || arg == "-passthru") {
            passThru = true;
        }
        else if (arg == "/exitcode" || arg == "-exitcode") {
            asExitCode = true;
        }
        else if (arg == "/nokick" || arg == "-nokick") {
            noKick = true;
        }
        else if (arg == "/?" || arg == "-?" || arg == "/help" || arg == "-help") {
            PrintUsage();
            return 0;
        }
    }

    if (!forceLight && !forceDark && !toggle) {
        toggle = true;
    }

    try {
        WindowsThemeToggler toggler(quiet, passThru, noKick);
        ThemeInfo info = toggler.SetWindowsTheme(forceLight, forceDark, toggle);
        toggler.PrintThemeInfo(info);

        if (asExitCode) {
            return static_cast<int>(info.exitCode);
        }
    }
    catch (const ThemeToggleError& tex) {
        std::cerr << "Error: " << tex.what() << std::endl;
        if (!g_hasConsole) {
            ShowGuiMessage(tex.what(), MB_ICONERROR);
        }

        if (asExitCode) {
            return static_cast<int>(tex.code());
        }
        return 1;
    }
    catch (const std::exception& ex) {
        std::cerr << "Error: " << ex.what() << std::endl;
        if (!g_hasConsole) {
            ShowGuiMessage(ex.what(), MB_ICONERROR);
        }

        if (asExitCode) {
            return static_cast<int>(ExitCode::RegKeyCreateFailed);
        }
        return 1;
    }

    return 0;
}

int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int) {
    int argc = 0;
    LPWSTR* argvW = CommandLineToArgvW(GetCommandLineW(), &argc);
    if (!argvW) {
        return 1;
    }

    if (AttachConsole(ATTACH_PARENT_PROCESS)) {
        g_hasConsole = true;
        EnsureConsoleStreams();
    }

    std::vector<std::string> narrow(argc);
    std::vector<char*> argv(argc);
    for (int i = 0; i < argc; ++i) {
        narrow[i] = WideToUtf8(argvW[i] ? argvW[i] : L"");
        argv[i] = narrow[i].data();
    }

    LocalFree(argvW);
    return RunThemeToggleCli(argc, argv.data());
}
