import SwiftUI

/// Supported language pairs for the picker.
struct Language: Identifiable, Hashable {
    let id: String         // BCP-47 code
    let displayName: String
    let flag: String

    var locale: Locale.Language { Locale.Language(identifier: id) }

    static let all: [Language] = [
        Language(id: "en", displayName: "English", flag: "🇺🇸"),
        Language(id: "es", displayName: "Spanish", flag: "🇪🇸"),
        Language(id: "fr", displayName: "French", flag: "🇫🇷"),
        Language(id: "de", displayName: "German", flag: "🇩🇪"),
        Language(id: "pt", displayName: "Portuguese", flag: "🇧🇷"),
        Language(id: "it", displayName: "Italian", flag: "🇮🇹"),
        Language(id: "nl", displayName: "Dutch", flag: "🇳🇱"),
        Language(id: "ru", displayName: "Russian", flag: "🇷🇺"),
        Language(id: "zh", displayName: "Chinese", flag: "🇨🇳"),
        Language(id: "ja", displayName: "Japanese", flag: "🇯🇵"),
        Language(id: "ko", displayName: "Korean", flag: "🇰🇷"),
        Language(id: "ar", displayName: "Arabic", flag: "🇸🇦"),
        Language(id: "hi", displayName: "Hindi", flag: "🇮🇳"),
        Language(id: "tr", displayName: "Turkish", flag: "🇹🇷"),
        Language(id: "pl", displayName: "Polish", flag: "🇵🇱"),
    ]

    static let auto = Language(id: "", displayName: "Auto-detect", flag: "🌐")
}

/// A compact language picker button with flag + name.
struct LanguageButton: View {
    let label: String
    @Binding var selection: Language
    let languages: [Language]

    var body: some View {
        Menu {
            ForEach(languages) { lang in
                Button {
                    selection = lang
                } label: {
                    Text("\(lang.flag) \(lang.displayName)")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selection.flag)
                    .font(.system(size: 14))
                Text(selection.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}
