//
//  FadeCurve.swift
//  Pure fade math, kept separate from the audio engine so it can be unit-tested.
//

import Foundation

enum FadeCurve {
    /// Evenly spaced volume steps from `from` to `to`, endpoints included.
    /// The result always ends exactly at `to`. Returns just `[to]` when
    /// `count <= 0` or the two volumes already match.
    static func steps(from: Float, to: Float, count: Int) -> [Float] {
        guard count > 0, from != to else { return [to] }
        let delta = (to - from) / Float(count)
        var result: [Float] = []
        result.reserveCapacity(count)
        for i in 1...count {
            result.append(from + delta * Float(i))
        }
        result[result.count - 1] = to
        return result
    }
}
