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
/// - Returns: meters converted to nautical miles
private func nm<T: BinaryFloatingPoint>(fromMeters m: T) -> T {
    return m / 1852.0
}


/// extension for convenience
private extension BinaryFloatingPoint {
    /// degree converted to radians
    var asRad: Self {
        return rad(fromDegree: self)
    }
    var inNm: Self {
        return nm(fromMeters: self)
    }

}

final class VincentyTests: XCTestCase {
    
    func testLatLongCheck() {
        XCTAssertThrowsError(try vincenty.vincentyCalculations((lat: pi, lon: pi), (lat: 0, lon: 0)))
    }

    func testShortcutForEqualPoints() {
        // make sure, points are equal and not identical, to check if the shortcut works correctly
        XCTAssertEqual(try vincenty.vincentyCalculations(zero, (lat: 0.0, lon: 0.0), maxIter: 1).distance, 0.0)
        // make sure, the short cut does not work, if points are not equal
        XCTAssertThrowsError(try vincenty.vincentyCalculations(zero, (lat: 0.5.asRad, lon: 179.7.asRad), maxIter: 1))
    }

    /// make sure the computation converges
    func testPoles() {
        XCTAssertNoThrow(try vincenty.vincentyCalculations((lat: pi / 2, lon: 0), (lat: -pi / 2, lon: 0)))
    }

    /// make sure another ellipsoid can be employed
    func testGrs80() {
        XCTAssertNoThrow(try vincenty.vincentyCalculations((lat: pi / 2, lon: 0), (lat: -pi / 2, lon: 0), ellipsoid: grs80))
    }

    /// make sure, the results are within the right ballpark for some constants
    func testSimpleConstants() {
        let delta = 1e-3
        var x: (lat: Double, lon: Double), y: (lat: Double, lon: Double)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 0.asRad, lon: 0.asRad)
        XCTAssertEqual(try! vincenty.vincentyCalculations(x, y).distance, 0.0, accuracy: delta)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 1.asRad, lon: 0.asRad)
        XCTAssertEqual(try! vincenty.vincentyCalculations(x, y).distance, 110574.389, accuracy: delta)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 2.asRad, lon: 0.asRad)
        XCTAssertEqual(try! vincenty.vincentyCalculations(x, y).distance, 221149.453, accuracy: delta)

        x = (lat: 0.5.asRad, lon: 0.asRad)
        y = (lat: -0.5.asRad, lon: 0.asRad)
        XCTAssertEqual(try! vincenty.vincentyCalculations(x, y).distance, 110574.304, accuracy: delta)

        x = (lat: -0.5.asRad, lon: 0.asRad)
        y = (lat: 0.5.asRad, lon: 0.asRad)
        XCTAssertEqual(try! vincenty.vincentyCalculations(x, y).distance, 110574.304, accuracy: delta)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 0.asRad, lon: 1.asRad)
        XCTAssertEqual(try! vincenty.vincentyCalculations(x, y).distance, 111319.491, accuracy: delta)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 0.asRad, lon: 2.asRad)
        XCTAssertEqual(try! vincenty.vincentyCalculations(x, y).distance, 222638.982, accuracy: delta)

        x = (lat: 0.asRad, lon: 0.5.asRad)
        y = (lat: 0.asRad, lon: -0.5.asRad)
        XCTAssertEqual(try! vincenty.vincentyCalculations(x, y).distance, 111319.491, accuracy: delta)

        x = (lat: 0.asRad, lon: -0.5.asRad)
        y = (lat: 0.asRad, lon: 0.5.asRad)
        XCTAssertEqual(try! vincenty.vincentyCalculations(x, y).distance, 111319.491, accuracy: delta)
        
        //Test Cardinals
        x = (lat: 0.0, lon: 0.0)
        y = (lat: pi/2,lon: 0.0) //north pole
        XCTAssertEqual(try! vincenty.vincentyCalculations(x, y).initialTrueTrack, 0.0, accuracy: delta)
        
        y = (lat: 0.0, lon: pi/2) //east
        XCTAssertEqual(try! vincenty.vincentyCalculations(x, y).initialTrueTrack, 90.0, accuracy: delta)
        
        y = (lat: -pi/2,lon: 0.0) //south pole
        XCTAssertEqual(try! vincenty.vincentyCalculations(x, y).initialTrueTrack, 180.0, accuracy: delta)
        
        y = (lat: 0.0,lon: -pi/2) //west
        XCTAssertEqual(try! vincenty.vincentyCalculations(x, y).initialTrueTrack, 270.0, accuracy: delta)
        
    }
    
    /// Test against A330 FMS
    let fmsAcc = 0.49 //within half nm or degree
    func testNavigationAccurracy() {
        
        var x: (lat: Double, lon: Double), y: (lat: Double, lon: Double)
        var results: VincentyResults
        //Urabi to Bumat
        x = (lat: (60+12/60).asRad, lon: (154+41.1/60).asRad)
        y = (lat: (61+50.1/60).asRad, lon: (160+33/60).asRad)
        results = try! vincenty.vincentyCalculations(x, y)
        XCTAssertEqual(results.distance.inNm, 197, accuracy: fmsAcc)
        XCTAssertEqual(results.initialTrueTrack, 058, accuracy: fmsAcc)
    }
    

    /// use geodesic as reference and test vincenty distance.
    func testAgainstGeodesic() {
        var x: (lat: Double, lon: Double), y: (lat: Double, lon: Double)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 0.asRad, lon: 1.asRad)
        let v = try! vincenty.vincentyCalculations(x, y).distance
        let g = geodesic.distance(x, y)
        print("vincenty: \(v), geodesic: \(g), delta: \(fabs(v - g))")
        XCTAssertEqual(v, g, accuracy: 1e-3)
    }

    /// nearly antipodal points, see https://en.wikipedia.org/wiki/Vincenty%27s_formulae#Nearly_antipodal_points
    func testNearlyAntipodalPoints() {
        var x: (lat: Double, lon: Double), y: (lat: Double, lon: Double)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 0.5.asRad, lon: 179.5.asRad)
        let v = try! vincenty.vincentyCalculations(x, y).distance
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
        XCTAssertThrowsError(try vincenty.vincentyCalculations(x, y))

        // we would like to have a good accuracy here, however, this is one of the cases, where vincenty fails.
//        let v = try! vincenty.distance(x, y)
//        let g = geodesic.distance(x, y)
//        print("vincenty: \(v), geodesic: \(g), delta: \(fabs(v - g))")
//        XCTAssertEqual(v, g, accuracy: 1e-3)
//        XCTAssertEqual(v, 19944127.421, accuracy: 1e-3)
    }

#if !os(macOS)
    static var allTests = [
        ("testLatLongCheck", testLatLongCheck),
        ("testAgainstGeodesic", testAgainstGeodesic),
        ("testFailOnNearlyAntipodalPoints", testFailOnNearlyAntipodalPoints),
        ("testGrs80", testGrs80),
        ("testNearlyAntipodalPoints", testNearlyAntipodalPoints),
        ("testPoles", testPoles),
        ("testShortcutForEqualPoints", testShortcutForEqualPoints),
        ("testSimpleConstants", testSimpleConstants),
        ("testNavigationAccurracy", testNavigationAccurracy),
    ]
#endif
}
