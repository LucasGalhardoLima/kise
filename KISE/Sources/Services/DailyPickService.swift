import Foundation
import os.log

private let logger = Logger(subsystem: "com.kise.app", category: "DailyPick")

final class DailyPickService {
    private let baseURL = SuggestionService.proxyBaseURL

    func fetchDailyPick() async -> DailyPalette? {
        guard let url = URL(string: "\(baseURL)/daily-pick") else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return nil
            }
            return try JSONDecoder().decode(DailyPalette.self, from: data)
        } catch {
            logger.debug("Daily pick fetch failed: \(error.localizedDescription)")
            return nil
        }
    }
}
