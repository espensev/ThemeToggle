#pragma once
#include <windows.h>

// Minimal QueryPerformanceCounter lap timer for stage diagnostics
struct StageTimer {
    LARGE_INTEGER freq{};
    LARGE_INTEGER last{};

    StageTimer() {
        QueryPerformanceFrequency(&freq);
        QueryPerformanceCounter(&last);
    }

    // Milliseconds since construction or the previous lap
    double LapMs() {
        LARGE_INTEGER now;
        QueryPerformanceCounter(&now);
        double ms = (now.QuadPart - last.QuadPart) * 1000.0 / static_cast<double>(freq.QuadPart);
        last = now;
        return ms;
    }
};
