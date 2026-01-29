#pragma once
#include <windows.h>
#include <string>
#include <stdexcept>

// Exit codes
enum class ExitCode : int {
    SuccessNoChange = 0,
    ChangedToLight = 1,
    ChangedToDark = 2,
    RegKeyCreateFailed = 10,
    RegWriteFailed = 11,
    BroadcastFailed = 20,
    AlreadyRunning = 30,
    UnknownError = 99
};

// Read status
enum class RegistryStatus {
    Success,
    KeyNotFound,
    AccessDenied
};

// Theme info
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

// RAII registry key
class RegKey {
public:
    RegKey() = default;
    RegKey(const RegKey&) = delete;
    RegKey& operator=(const RegKey&) = delete;

    RegKey(RegKey&& other) noexcept : hKey_(other.hKey_) {
        other.hKey_ = nullptr;
    }

    RegKey& operator=(RegKey&& other) noexcept {
        if (&other != this) {
            Close();
            hKey_ = other.hKey_;
            other.hKey_ = nullptr;
        }
        return *this;
    }

    ~RegKey() {
        Close();
    }

    LONG Open(HKEY root, const wchar_t* path, REGSAM access) {
        Close();
        return RegOpenKeyExW(root, path, 0, access, &hKey_);
    }

    LONG CreateOrOpen(HKEY root, const wchar_t* path, REGSAM access) {
        Close();
        return RegCreateKeyExW(root, path, 0, nullptr,
            REG_OPTION_NON_VOLATILE, access, nullptr, &hKey_, nullptr);
    }

    HKEY Get() const { return hKey_; }
    explicit operator HKEY() const { return hKey_; }
    bool IsValid() const { return hKey_ != nullptr; }

    void Close() {
        if (hKey_) {
            RegCloseKey(hKey_);
            hKey_ = nullptr;
        }
    }

private:
    HKEY hKey_ = nullptr;
};

// RAII mutex
struct MutexGuard {
    HANDLE hMutex = nullptr;
    bool owned = false;
    bool abandoned = false;

    MutexGuard(const MutexGuard&) = delete;
    MutexGuard& operator=(const MutexGuard&) = delete;

    explicit MutexGuard(const wchar_t* name) {
        hMutex = CreateMutexW(nullptr, FALSE, name);
        if (hMutex) {
            // Wait up to 2s
            DWORD result = WaitForSingleObject(hMutex, 2000);
            if (result == WAIT_OBJECT_0) {
                owned = true;
            } else if (result == WAIT_ABANDONED) {
                owned = true;
                abandoned = true;
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
    bool WasAbandoned() const { return abandoned; }
};

// RAII priority boost
struct PriorityBoost {
    DWORD oldPriority;
    HANDLE hProcess;
    bool succeeded;

    PriorityBoost(const PriorityBoost&) = delete;
    PriorityBoost& operator=(const PriorityBoost&) = delete;

    PriorityBoost() : oldPriority(0), hProcess(nullptr), succeeded(false) {
        hProcess = GetCurrentProcess();
        oldPriority = GetPriorityClass(hProcess);
        
        // Use ABOVE_NORMAL priority
        if (SetPriorityClass(hProcess, ABOVE_NORMAL_PRIORITY_CLASS)) {
            succeeded = true;
        }
    }

    ~PriorityBoost() {
        if (succeeded && hProcess && oldPriority != 0) {
            SetPriorityClass(hProcess, oldPriority);
        }
    }
};

// Error with exit code
class ThemeToggleError : public std::runtime_error {
public:
    ThemeToggleError(const std::string& message, ExitCode code)
        : std::runtime_error(message), exitCode(code) {}

    ExitCode code() const noexcept { return exitCode; }

private:
    ExitCode exitCode;
};
