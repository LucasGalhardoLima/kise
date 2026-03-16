// KISE/Sources/Services/ColorNamingService.swift
import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum ColorNamingService {
    /// Generate a creative name for a hex color.
    /// iOS 26+: uses on-device FoundationModels.
    /// Older iOS: falls back to nearest match in ColorDictionary.
    static func generateName(for hex: String) async -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            if let aiName = await generateOnDeviceName(for: hex) {
                return aiName
            }
        }
        #endif
        return ColorDictionary.nearestName(for: hex)
    }

    #if canImport(FoundationModels)
    @available(iOS 26, *)
    private static func generateOnDeviceName(for hex: String) async -> String? {
        do {
            let session = LanguageModelSession()
            let prompt = "Give this color a short, evocative name (2-3 words max, no hex values, no quotes): \(hex)"
            let response = try await session.respond(to: prompt)
            let name = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            // Validate: non-empty, short (< 30 chars), and not contain the hex
            guard !name.isEmpty, name.count < 30, !name.contains("#") else {
                return nil
            }
            return name
        } catch {
            return nil
        }
    }
    #endif
}
