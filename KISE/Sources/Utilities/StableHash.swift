// KISE/Sources/Utilities/StableHash.swift
import Foundation

/// Deterministic hash — unlike Swift's hashValue, stable across launches
enum StableHash {
    static func fnv1a(_ string: String) -> Int {
        var hash: UInt64 = 14695981039346656037
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }
        return Int(truncatingIfNeeded: hash)
    }
}
