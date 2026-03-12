// KISE/Tests/Services/SuggestionServiceTests.swift
import Foundation
import Testing
@testable import KISE

struct SuggestionServiceTests {
    @Test func apiResponseDecoding() throws {
        let json = """
        {
            "pieces": ["uuid-1", "uuid-2", "uuid-3"],
            "reasoning": "Clean look for the weather",
            "layering_note": "Bring a jacket for the morning",
            "alternative_piece": {
                "swap": "uuid-3",
                "for": "uuid-4",
                "why": "Softer option"
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(SuggestionAPIResponse.self, from: json)
        #expect(response.pieces.count == 3)
        #expect(response.reasoning == "Clean look for the weather")
        #expect(response.layering_note == "Bring a jacket for the morning")
        #expect(response.alternative_piece?.swap == "uuid-3")
        #expect(response.alternative_piece?.for == "uuid-4")
    }

    @Test func apiResponseDecodingMinimal() throws {
        let json = """
        {
            "pieces": ["uuid-1"],
            "reasoning": "Simple outfit"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(SuggestionAPIResponse.self, from: json)
        #expect(response.pieces.count == 1)
        #expect(response.layering_note == nil)
        #expect(response.alternative_piece == nil)
    }

    @Test func suggestionErrorDescriptions() {
        let errors: [SuggestionError] = [
            .invalidResponse,
            .httpError(500),
            .serverError("API down"),
            .noActivePieces,
        ]
        for error in errors {
            #expect(error.errorDescription != nil)
        }
    }
}
