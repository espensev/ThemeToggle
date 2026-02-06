#include <windows.h>
#include <winternl.h>
#include <iostream>
#include <string>
#include <sstream>
#include <vector>
#include <cstdio>
#include <cwchar>
#include <cctype>
#include <shellapi.h>

#include "Types.h"
#include "RegistryManager.h"
#include "BroadcastManager.h"
#include "UxThemeHelper.h"
#include "StringUtils.h"

namespace {
bool g_hasConsole = false;

void EnsureConsoleStreams() {
    if (!g_hasConsole) {
        return;
    }
    FILE* fp = nullptr;
    if (freopen_s(&fp, "CONOUT$", "w", stdout) != 0) {
        g_hasConsole = false;
    }
    if (freopen_s(&fp, "CONOUT$", "w", stderr) != 0) {
        g_hasConsole = false;
    }
}

void ShowGuiMessage(const std::string& text, UINT icon) {
    if (g_hasConsole) {
        return;
    }
    auto wide = StringUtils::Utf8ToWide(text);
    MessageBoxW(nullptr, wide.c_str(), L"ThemeToggle", MB_OK | icon);
}

void ShowGuiSummary(const ThemeInfo& info, bool quiet, bool passThru, bool asExitCode) {
    if (quiet || passThru || asExitCode) {
        return;
    }

    if (g_hasConsole) {
        return;
    }

    std::ostringstream msg;
    UINT icon = MB_ICONINFORMATION;

    if (info.exitCode == ExitCode::AlreadyRunning) {
        msg << "Another instance is already running.";
        icon = MB_ICONWARNING;
    }
    else if (info.changed) {
        msg << "Changed to " << info.theme << " theme.";
        if (!info.broadcastOk) {
            msg << " (broadcast issue detected)";
            icon = MB_ICONWARNING;
        }
    }
    else {
        msg << "Already " << info.theme << " theme.";
    }

    if (info.stubbornAppsKicked > 0) {
        msg << "\nKicked " << info.stubbornAppsKicked << " stubborn app"
            << (info.stubbornAppsKicked == 1 ? "" : "s") << ".";
    }

    ShowGuiMessage(msg.str(), icon);
}
}

class WindowsThemeToggler {
private:
    static constexpr WORD DEFAULT_CONSOLE_COLOR = FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE;
    static constexpr const wchar_t* MUTEX_NAME = L"Local\\WindowsThemeToggler_SingleInstance";

    bool quiet;
    bool passThru;
    bool noFlush;
    KickPolicy kickPolicy;
    HANDLE hConsole = nullptr;
    bool isWin11;

    RegistryManager registry;
    BroadcastManager broadcaster;
    UxThemeHelper uxtheme;

    // Windows version check using RtlGetVersion (reliable, no manifest required)
    bool IsWindows11OrGreater() {
        using RtlGetVersionPtr = NTSTATUS(WINAPI*)(PRTL_OSVERSIONINFOW);
        
        HMODULE ntdll = GetModuleHandleW(L"ntdll.dll");
        if (!ntdll) return false;
        
        auto RtlGetVersion = reinterpret_cast<RtlGetVersionPtr>(
            GetProcAddress(ntdll, "RtlGetVersion"));
        if (!RtlGetVersion) return false;
        
        RTL_OSVERSIONINFOW osvi = {};
        osvi.dwOSVersionInfoSize = sizeof(osvi);
        
        // NTSTATUS: negative values indicate failure
        if (RtlGetVersion(&osvi) < 0) return false;
        
        // Windows 11 is build 22000+ with major version 10
        return osvi.dwMajorVersion >= 10 && osvi.dwBuildNumber >= 22000;
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
WindowsThemeToggler(bool quiet = false, bool passThru = false, KickPolicy kickPolicy = KickPolicy::All, bool noFlush = false)
    : quiet(quiet)
    , passThru(passThru)
    , noFlush(noFlush)
    , kickPolicy(kickPolicy)
    , isWin11(IsWindows11OrGreater())
    , broadcaster(isWin11) {
        
    // Load undocumented theme APIs (available on Win10 1903+, but mainly useful on Win11)
    uxtheme.LoadApis();

    // Cache console handle
    hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
    if (hConsole != INVALID_HANDLE_VALUE && hConsole != nullptr) {
            DWORD mode;
            if (!GetConsoleMode(hConsole, &mode)) {
                hConsole = nullptr;
            }
        }
    }

    ThemeInfo SetWindowsTheme(bool forceLight, bool forceDark) {

        ThemeInfo info{};
        info.exitCode = ExitCode::SuccessNoChange;

        // Prevent concurrent instances
        MutexGuard mutex(MUTEX_NAME);
        if (mutex.IsValid()) {
            if (mutex.HasWaitError()) {
                // WaitForSingleObject failed unexpectedly
                if (!quiet) {
                    PrintMessage("Mutex wait failed; continuing without lock.", true);
                }
            }
            else if (mutex.IsTimedOut()) {
                // Another instance is likely hung or taking too long
                if (!quiet) {
                    PrintMessage("Timed out acquiring mutex; another instance may be hung.", true);
                }
                info.exitCode = ExitCode::AlreadyRunning;
                return info;
            }
            else if (!mutex.IsOwned()) {
                // Shouldn't reach here, but handle gracefully
                if (!quiet) {
                    PrintMessage("Another instance is already running.", true);
                }
                info.exitCode = ExitCode::AlreadyRunning;
                return info;
            }
            
            if (mutex.WasAbandoned()) {
                PrintMessage("Previous instance may have exited abnormally.", true);
            }
        }
        else {
            // If the mutex can't be created, don't falsely claim "AlreadyRunning".
            // Best-effort: continue without single-instance enforcement.
            if (!quiet) {
                PrintMessage("Unable to create single-instance mutex; continuing without lock.", true);
            }
        }

        // Read current theme
        DWORD currSystem = 0;
        DWORD currApps = 0;
        bool hasSystem = false;
        bool hasApps = false;

        RegistryStatus readStatus = registry.ReadTheme(currSystem, currApps, hasSystem, hasApps);
        if (readStatus == RegistryStatus::AccessDenied) {
            throw ThemeToggleError("Failed to read registry (access denied)", ExitCode::RegReadFailed);
        }
        if (readStatus == RegistryStatus::OtherError) {
            throw ThemeToggleError("Failed to read registry (unexpected error)", ExitCode::RegReadFailed);
        }

        // Default to dark theme if key missing
        if (!hasSystem) currSystem = 0;
        if (!hasApps) currApps = 0;

        info.oldSystemValue = currSystem;
        info.oldAppsValue = currApps;

        // Determine target value
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

        // Check for required changes
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

        // Boost process priority only when writing
        PriorityBoost priorityBoost;

        // Write theme to registry
        if (!registry.WriteTheme(newValue, currSystem, hasSystem)) {
            throw ThemeToggleError("Failed writing theme values", ExitCode::RegWriteFailed);
        }

        int verifyAttempts = 0;
        auto verifyWrite = [&](DWORD expected) {
            verifyAttempts++;
            DWORD verifySystem = 0;
            DWORD verifyApps = 0;
            bool verifyHasSystem = false;
            bool verifyHasApps = false;
            RegistryStatus verifyStatus = registry.ReadTheme(verifySystem, verifyApps, verifyHasSystem, verifyHasApps);
            if (verifyStatus == RegistryStatus::AccessDenied) {
                PrintMessage("Unable to verify registry values (access denied).", true);
                return true; // Best-effort: proceed without verification
            }
            if (verifyStatus == RegistryStatus::OtherError) {
                PrintMessage("Unable to verify registry values (unexpected error).", true);
                return true; // Best-effort: proceed without verification
            }
            if (verifyStatus != RegistryStatus::Success) {
                return false;
            }
            return verifyHasSystem && verifyHasApps && verifySystem == expected && verifyApps == expected;
        };

        // Force flush (best-effort)
        if (!noFlush) {
            if (!registry.Flush()) {
                PrintMessage("Failed to flush theme values; continuing with verification.", true);
            }
        }

        // Verify write; retry once if mismatch
        if (!verifyWrite(newValue)) {
            PrintMessage("Theme values did not verify; retrying write.", true);
            if (!registry.WriteTheme(newValue, currSystem, hasSystem)) {
                throw ThemeToggleError("Failed writing theme values", ExitCode::RegWriteFailed);
            }
            if (!noFlush) {
                if (!registry.Flush()) {
                    PrintMessage("Failed to flush theme values on retry.", true);
                }
            }
            if (!verifyWrite(newValue)) {
                throw ThemeToggleError("Failed to verify theme values", ExitCode::RegWriteFailed);
            }
        }
        info.verifyAttempts = verifyAttempts;

        // Sync via uxtheme (no-op if APIs unavailable)
        uxtheme.SyncTheme(isDark);

        // Broadcast change and kick stubborn apps
        int kicked = broadcaster.BroadcastThemeChange(isDark, kickPolicy);
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
            std::cout << "VerifyAttempts: " << info.verifyAttempts << std::endl;
            
            // UxTheme API diagnostics
            std::cout << "UxThemeLoaded: " << (uxtheme.IsFullyLoaded() ? "true" : "false") << std::endl;
            std::cout << "UxTheme_Ord104: " << (uxtheme.HasRefreshImmersiveColorPolicyState() ? "true" : "false") << std::endl;
            std::cout << "UxTheme_Ord135: " << (uxtheme.HasSetPreferredAppMode() ? "true" : "false") << std::endl;
            std::cout << "UxTheme_Ord136: " << (uxtheme.HasFlushMenuThemes() ? "true" : "false") << std::endl;
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
        "  /kick=all    Kick all stubborn apps (default)\n"
        "  /kick=core   Kick core stubborn apps only\n"
        "  /kick=none   Do not kick stubborn apps\n"
        "  /nokick      Alias for /kick=none\n"
        "  /noflush     Skip registry flush (best-effort)\n"
        "  /? /help /h  Show this help\n"
        "  (All options also accept '-' or '--' prefixes)\n\n"
        "Exit Codes (when /exitcode is used):\n"
        "  0  = Success (no change)\n"
        "  1  = Changed to Light\n"
        "  2  = Changed to Dark\n"
        "  10 = Registry key creation failed\n"
        "  11 = Registry write failed\n"
        "  12 = Registry read failed\n"
        "  20 = Broadcast failed but registry ok\n"
        "  30 = Already running (another instance)\n"
        "  99 = Unknown error\n";

    std::cout << usage;
    if (!g_hasConsole) {
        ShowGuiMessage(usage, MB_ICONINFORMATION);
    }
}

int RunThemeToggleCli(int argc, char* argv[]) {
    bool forceLight = false;
    bool forceDark = false;
    bool quiet = false;
    bool passThru = false;
    bool asExitCode = false;
    bool noFlush = false;
    KickPolicy kickPolicy = KickPolicy::All;
    std::vector<std::string> unknownArgs;

    // Parse arguments
    for (int i = 1; i < argc; ++i) {
        std::string originalArg = argv[i] ? argv[i] : "";
        std::string arg = originalArg;

        for (auto& c : arg) {
            c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
        }

        if (arg == "/light" || arg == "-light" || arg == "--light") {
            forceLight = true;
        }
        else if (arg == "/dark" || arg == "-dark" || arg == "--dark") {
            forceDark = true;
        }
        else if (arg == "/toggle" || arg == "-toggle" || arg == "--toggle") {
            // Default behavior; accepted for explicitness
        }
        else if (arg == "/quiet" || arg == "-quiet" || arg == "--quiet") {
            quiet = true;
        }
        else if (arg == "/passthru" || arg == "-passthru" || arg == "--passthru") {
            passThru = true;
        }
        else if (arg == "/exitcode" || arg == "-exitcode" || arg == "--exitcode") {
            asExitCode = true;
        }
        else if (arg == "/noflush" || arg == "-noflush" || arg == "--noflush") {
            noFlush = true;
        }
        else if (arg == "/nokick" || arg == "-nokick" || arg == "--nokick") {
            kickPolicy = KickPolicy::None;
        }
        else if (arg.rfind("/kick=", 0) == 0 || arg.rfind("-kick=", 0) == 0 || arg.rfind("--kick=", 0) == 0) {
            auto valuePos = arg.find('=');
            auto value = valuePos == std::string::npos ? "" : arg.substr(valuePos + 1);
            if (value == "all") {
                kickPolicy = KickPolicy::All;
            }
            else if (value == "core") {
                kickPolicy = KickPolicy::Core;
            }
            else if (value == "none") {
                kickPolicy = KickPolicy::None;
            }
            else {
                std::cerr << "Warning: Unknown kick policy '" << value << "'; using default (all)." << std::endl;
            }
        }
        else if (arg == "/?" || arg == "-?" || arg == "/help" || arg == "-help" || arg == "/h" || arg == "-h" || arg == "--help") {
            PrintUsage();
            return 0;
        }
        else if (!arg.empty()) {
            unknownArgs.push_back(originalArg);
        }
    }

    if (!unknownArgs.empty()) {
        for (const auto& badArg : unknownArgs) {
            std::cerr << "Error: Unknown option '" << badArg << "'." << std::endl;
        }
        PrintUsage();
        return asExitCode ? static_cast<int>(ExitCode::UnknownError) : 1;
    }

    if (forceLight && forceDark) {
        std::cerr << "Error: /light and /dark cannot be used together." << std::endl;
        return asExitCode ? static_cast<int>(ExitCode::UnknownError) : 1;
    }

    try {
        WindowsThemeToggler toggler(quiet, passThru, kickPolicy, noFlush);
        ThemeInfo info = toggler.SetWindowsTheme(forceLight, forceDark);
        toggler.PrintThemeInfo(info);
        ShowGuiSummary(info, quiet, passThru, asExitCode);

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
            return static_cast<int>(ExitCode::UnknownError);
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
        narrow[i] = StringUtils::WideToUtf8(argvW[i] ? argvW[i] : L"");
        argv[i] = narrow[i].data();
    }

    LocalFree(argvW);
    return RunThemeToggleCli(argc, argv.data());
}
