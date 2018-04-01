import XCTest
@testable import vincenty

// some constants

private let zero = (lat: 0.0, lon: 0.0)
private let northPole = (lat: Double.pi / 2, lon: 0.0)
private let southPole = (lat: -Double.pi / 2, lon: 0.0)
private let grs80 = (a: 6378137.0, f: 1 / 298.257222100882711)
private let pi: Double = Double.pi

/// - Returns: degree converted to radians
private func rad<T: BinaryFloatingPoint>(fromDegree d: T) -> T {
    return d * T.pi / 180
}

/// extension for convenience
private extension BinaryFloatingPoint {
    /// degree converted to radians
    var asRad: Self {
        return rad(fromDegree: self)
    }
}

final class VincentyTests: XCTestCase {

    func testShortcutForEqualPoints() {
        // make sure, points are equal and not identical, to check if the shortcut works correctly
        XCTAssertEqual(try distance(zero, (lat: 0.0, lon: 0.0), maxIter: 1), 0.0)
        // make sure, the short cut does not work, if points are not equal
        XCTAssertThrowsError(try distance(zero, (lat: 0.5.asRad, lon: 179.7.asRad), maxIter: 1))
    }

    func testPoles() {
        XCTAssertNoThrow(try distance((lat: pi / 2, lon: 0), (lat: -pi / 2, lon: 0)))
    }

    func testGrs80() {
        XCTAssertNoThrow(try distance((lat: pi / 2, lon: 0), (lat: -pi / 2, lon: 0), ellipsoid: grs80))
    }

    func testVincentyDistance() {
        let delta = 1e-3
        var x: (lat: Double, lon: Double), y: (lat: Double, lon: Double)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 0.asRad, lon: 0.asRad)
        XCTAssertEqual(try! distance(x, y), 0.0, accuracy: delta)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 1.asRad, lon: 0.asRad)
        XCTAssertEqual(try! distance(x, y), 110574.389, accuracy: delta)
        XCTAssert(abs(try! distance(x, y) - 110574.389) < delta)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 2.asRad, lon: 0.asRad)
        XCTAssertEqual(try! distance(x, y), 221149.453, accuracy: delta)

        x = (lat: 0.5.asRad, lon: 0.asRad)
        y = (lat: -0.5.asRad, lon: 0.asRad)
        XCTAssertEqual(try! distance(x, y), 110574.304, accuracy: delta)

        x = (lat: -0.5.asRad, lon: 0.asRad)
        y = (lat: 0.5.asRad, lon: 0.asRad)
        XCTAssertEqual(try! distance(x, y), 110574.304, accuracy: delta)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 0.asRad, lon: 1.asRad)
        XCTAssertEqual(try! distance(x, y), 111319.491, accuracy: delta)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 0.asRad, lon: 2.asRad)
        XCTAssertEqual(try! distance(x, y), 222638.982, accuracy: delta)

        x = (lat: 0.asRad, lon: 0.5.asRad)
        y = (lat: 0.asRad, lon: -0.5.asRad)
        XCTAssertEqual(try! distance(x, y), 111319.491, accuracy: delta)

        x = (lat: 0.asRad, lon: -0.5.asRad)
        y = (lat: 0.asRad, lon: 0.5.asRad)
        XCTAssertEqual(try! distance(x, y), 111319.491, accuracy: delta)
    }

    static var allTests = [
        ("testShortcutForEqualPoints", testShortcutForEqualPoints),
        ("testPoles", testPoles),
        ("testGrs80", testGrs80),
    ]
}
