import XCTest
@testable import vincenty
import func geodesic.distance

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
        XCTAssertEqual(try vincenty.distance(zero, (lat: 0.0, lon: 0.0), maxIter: 1), 0.0)
        // make sure, the short cut does not work, if points are not equal
        XCTAssertThrowsError(try vincenty.distance(zero, (lat: 0.5.asRad, lon: 179.7.asRad), maxIter: 1))
    }

    /// make sure the computation converges
    func testPoles() {
        XCTAssertNoThrow(try vincenty.distance((lat: pi / 2, lon: 0), (lat: -pi / 2, lon: 0)))
    }

    /// make sure another ellipsoid can be employed
    func testGrs80() {
        XCTAssertNoThrow(try vincenty.distance((lat: pi / 2, lon: 0), (lat: -pi / 2, lon: 0), ellipsoid: grs80))
    }

    /// make sure, the results are within the right ballpark for some constants
    func testSimpleConstants() {
        let delta = 1e-3
        var x: (lat: Double, lon: Double), y: (lat: Double, lon: Double)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 0.asRad, lon: 0.asRad)
        XCTAssertEqual(try! vincenty.distance(x, y), 0.0, accuracy: delta)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 1.asRad, lon: 0.asRad)
        XCTAssertEqual(try! vincenty.distance(x, y), 110574.389, accuracy: delta)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 2.asRad, lon: 0.asRad)
        XCTAssertEqual(try! vincenty.distance(x, y), 221149.453, accuracy: delta)

        x = (lat: 0.5.asRad, lon: 0.asRad)
        y = (lat: -0.5.asRad, lon: 0.asRad)
        XCTAssertEqual(try! vincenty.distance(x, y), 110574.304, accuracy: delta)

        x = (lat: -0.5.asRad, lon: 0.asRad)
        y = (lat: 0.5.asRad, lon: 0.asRad)
        XCTAssertEqual(try! vincenty.distance(x, y), 110574.304, accuracy: delta)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 0.asRad, lon: 1.asRad)
        XCTAssertEqual(try! vincenty.distance(x, y), 111319.491, accuracy: delta)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 0.asRad, lon: 2.asRad)
        XCTAssertEqual(try! vincenty.distance(x, y), 222638.982, accuracy: delta)

        x = (lat: 0.asRad, lon: 0.5.asRad)
        y = (lat: 0.asRad, lon: -0.5.asRad)
        XCTAssertEqual(try! vincenty.distance(x, y), 111319.491, accuracy: delta)

        x = (lat: 0.asRad, lon: -0.5.asRad)
        y = (lat: 0.asRad, lon: 0.5.asRad)
        XCTAssertEqual(try! vincenty.distance(x, y), 111319.491, accuracy: delta)
    }

    /// use geodesic as reference and test vincenty distance.
    func testAgainstGeodesic() {
        var x: (lat: Double, lon: Double), y: (lat: Double, lon: Double)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 0.asRad, lon: 1.asRad)
        let v = try! vincenty.distance(x, y)
        let g = geodesic.distance(x, y)
        print("vincenty: \(v), geodesic: \(g), delta: \(fabs(v - g))")
        XCTAssertEqual(v, g, accuracy: 1e-3)
    }

    /// nearly antipodal points, see https://en.wikipedia.org/wiki/Vincenty%27s_formulae#Nearly_antipodal_points
    func testNearlyAntipodalPoints() {
        var x: (lat: Double, lon: Double), y: (lat: Double, lon: Double)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 0.5.asRad, lon: 179.5.asRad)
        let v = try! vincenty.distance(x, y)
        let g = geodesic.distance(x, y)
        print("vincenty: \(v), geodesic: \(g), delta: \(fabs(v - g))")
        XCTAssertEqual(v, g, accuracy: 1e-3)
        XCTAssertEqual(v, 19936288.579, accuracy: 1e-3)
    }

    /// nearly antipodal points, see https://en.wikipedia.org/wiki/Vincenty%27s_formulae#Nearly_antipodal_points
    func testFailOnNearlyAntipodalPoints() {
        var x: (lat: Double, lon: Double), y: (lat: Double, lon: Double)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 0.5.asRad, lon: 179.7.asRad)
        XCTAssertThrowsError(try vincenty.distance(x, y))

        // we would like to have a good accuracy here, however, this is one of the cases, where vincenty fails.
//        let v = try! vincenty.distance(x, y)
//        let g = geodesic.distance(x, y)
//        print("vincenty: \(v), geodesic: \(g), delta: \(fabs(v - g))")
//        XCTAssertEqual(v, g, accuracy: 1e-3)
//        XCTAssertEqual(v, 19944127.421, accuracy: 1e-3)
    }

#if !os(macOS)
    static var allTests = [
        ("testAgainstGeodesic", testAgainstGeodesic),
        ("testFailOnNearlyAntipodalPoints", testFailOnNearlyAntipodalPoints),
        ("testGrs80", testGrs80),
        ("testNearlyAntipodalPoints", testNearlyAntipodalPoints),
        ("testPoles", testPoles),
        ("testShortcutForEqualPoints", testShortcutForEqualPoints),
        ("testSimpleConstants", testSimpleConstants),
    ]
#endif
}
