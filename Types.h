#pragma once
#include <windows.h>
#include <string>
#include <stdexcept>

// Exit code enum for clarity and type safety
enum class ExitCode : int {
    SuccessNoChange = 0,
    ChangedToLight = 1,
    ChangedToDark = 2,
    RegKeyCreateFailed = 10,
    RegWriteFailed = 11,
    BroadcastFailed = 20,
    AlreadyRunning = 30
};

// Theme information result
struct ThemeInfo {
    DWORD oldSystemValue = 0;
    DWORD oldAppsValue = 0;
    DWORD newValue = 0;
    std::string theme;
    bool changed = false;
    bool broadcastOk = false;
    ExitCode exitCode = ExitCode::SuccessNoChange;
    int stubbornAppsKicked = 0;
};

// RAII wrapper for registry keys
struct RegKey {
    HKEY hKey = nullptr;

    RegKey() = default;
    RegKey(const RegKey&) = delete;
    RegKey& operator=(const RegKey&) = delete;

    RegKey(RegKey&& other) noexcept : hKey(other.hKey) {
        other.hKey = nullptr;
    }

    RegKey& operator=(RegKey&& other) noexcept {
        if (std::addressof(other) != this) {
            Close();
            hKey = other.hKey;
            other.hKey = nullptr;
        }
        return *this;
    }

    ~RegKey() {
        Close();
    }

    LONG Open(HKEY root, const wchar_t* path, REGSAM access) {
        Close();
        return RegOpenKeyExW(root, path, 0, access, &hKey);
    }

    LONG CreateOrOpen(HKEY root, const wchar_t* path, REGSAM access) {
        Close();
        return RegCreateKeyExW(root, path, 0, nullptr,
            REG_OPTION_NON_VOLATILE, access, nullptr, &hKey, nullptr);
    }

    operator HKEY() const { return hKey; }
    bool IsValid() const { return hKey != nullptr; }

    void Close() {
        if (hKey) {
            RegCloseKey(hKey);
            hKey = nullptr;
        }
    }
};

// RAII wrapper for mutex
struct MutexGuard {
    HANDLE hMutex = nullptr;
    bool owned = false;

    explicit MutexGuard(const wchar_t* name) {
        hMutex = CreateMutexW(nullptr, FALSE, name);
        if (hMutex) {
            DWORD result = WaitForSingleObject(hMutex, 50);
            if (result == WAIT_OBJECT_0 || result == WAIT_ABANDONED) {
                owned = true;
            }
        }
    }

    ~MutexGuard() {
        if (hMutex) {
            if (owned) {
                ReleaseMutex(hMutex);
            }
            CloseHandle(hMutex);
        }
    }

    bool IsOwned() const { return owned; }
};

// RAII wrapper for process priority boost
struct PriorityBoost {
    DWORD oldPriority;
    HANDLE hProcess;

    PriorityBoost() {
        hProcess = GetCurrentProcess();
        oldPriority = GetPriorityClass(hProcess);
        SetPriorityClass(hProcess, HIGH_PRIORITY_CLASS);
    }

    ~PriorityBoost() {
        SetPriorityClass(hProcess, oldPriority);
    }
};

// Typed error that carries an ExitCode so callers can map failures precisely
class ThemeToggleError : public std::runtime_error {
public:
    ThemeToggleError(const std::string& message, ExitCode code)
        : std::runtime_error(message), exitCode(code) {}

    ExitCode code() const noexcept { return exitCode; }

private:
    ExitCode exitCode;
};
