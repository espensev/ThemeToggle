#pragma once
#include <windows.h>
#include <string>

namespace StringUtils {

inline std::string WideToUtf8(const std::wstring& wide) {
    if (wide.empty()) return {};

    int len = static_cast<int>(wide.size());
    int required = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS,
        wide.c_str(), len, nullptr, 0, nullptr, nullptr);
    if (required <= 0) return {};

    std::string utf8(static_cast<size_t>(required), '\0');
    WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS,
        wide.c_str(), len, utf8.data(), required, nullptr, nullptr);
    return utf8;
}

inline std::wstring Utf8ToWide(const std::string& text) {
    if (text.empty()) return {};

    int len = static_cast<int>(text.size());
    int required = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
        text.c_str(), len, nullptr, 0);
    if (required <= 0) return {};

    std::wstring wide(static_cast<size_t>(required), L'\0');
    MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
        text.c_str(), len, wide.data(), required);
    return wide;
}

} // namespace StringUtils
