//
//  FadeCurveTests.swift
//

import Testing
@testable import SoundPad

struct FadeCurveTests {

    @Test func fadeInEndsExactlyAtTarget() {
        let steps = FadeCurve.steps(from: 0, to: 0.8, count: 15)
        #expect(steps.count == 15)
        #expect(steps.last == 0.8)
    }

    @Test func fadeOutEndsExactlyAtZero() {
        let steps = FadeCurve.steps(from: 1.0, to: 0, count: 20)
        #expect(steps.count == 20)
        #expect(steps.last == 0)
    }

    @Test func fadeInIsMonotonicallyIncreasing() {
        let steps = FadeCurve.steps(from: 0, to: 1, count: 10)
        for (previous, next) in zip(steps, steps.dropFirst()) {
            #expect(next > previous)
        }
    }

    @Test func fadeOutIsMonotonicallyDecreasing() {
        let steps = FadeCurve.steps(from: 0.9, to: 0, count: 10)
        for (previous, next) in zip(steps, steps.dropFirst()) {
            #expect(next < previous)
        }
    }

    @Test func equalVolumesYieldSingleStep() {
        #expect(FadeCurve.steps(from: 0.5, to: 0.5, count: 10) == [0.5])
    }

    @Test func nonPositiveCountYieldsTargetOnly() {
        #expect(FadeCurve.steps(from: 0, to: 1, count: 0) == [1])
        #expect(FadeCurve.steps(from: 1, to: 0, count: -3) == [0])
    }
}
