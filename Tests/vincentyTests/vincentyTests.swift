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

/// - Returns: radians converted to degrees
private func deg<T: BinaryFloatingPoint>(fromRadian r: T) -> T {
    return r * 180 / T.pi
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
    var asDegrees: Self {
        return deg(fromRadian: self)
    }
    var inNm: Self {
        return nm(fromMeters: self)
    }

}

final class VincentyTests: XCTestCase {

    /// example code as shown in the Readme.md
    func testRreadmeExamples() {
        do {
            _ = try! vincenty.distance((lat: Double.pi / 2, lon: 0), (lat: -Double.pi / 2, lon: 0))
        }
        do {
            let (_, (_, _)) = try! solveInverse((lat: Double.pi / 2, lon: 0), (lat: -Double.pi / 2, lon: 0))
        }

    }

    func testShortcutForEqualPoints() {
        // make sure, points are equal and not identical, to check if the shortcut works correctly
        XCTAssertEqual(try vincenty.solveInverse(zero, (lat: 0.0, lon: 0.0), maxIter: 1).distance, 0.0)
        // make sure, the short cut does not work, if points are not equal
        XCTAssertThrowsError(try vincenty.solveInverse(zero, (lat: 0.5.asRad, lon: 179.7.asRad), maxIter: 1))
    }

    /// make sure the computation converges
    func testPoles() {
        XCTAssertNoThrow(try vincenty.solveInverse((lat: pi / 2, lon: 0), (lat: -pi / 2, lon: 0)))
    }

    /// make sure another ellipsoid can be employed
    func testGrs80() {
        XCTAssertNoThrow(try vincenty.solveInverse((lat: pi / 2, lon: 0), (lat: -pi / 2, lon: 0), ellipsoid: grs80))
    }

    /// make sure, the results are within the right ballpark for some constants
    func testSimpleConstants() {
        let delta = 1e-3
        var x: (lat: Double, lon: Double), y: (lat: Double, lon: Double)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 0.asRad, lon: 0.asRad)
        XCTAssertEqual(try! vincenty.solveInverse(x, y).distance, 0.0, accuracy: delta)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 1.asRad, lon: 0.asRad)
        XCTAssertEqual(try! vincenty.solveInverse(x, y).distance, 110574.389, accuracy: delta)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 2.asRad, lon: 0.asRad)
        XCTAssertEqual(try! vincenty.solveInverse(x, y).distance, 221149.453, accuracy: delta)

        x = (lat: 0.5.asRad, lon: 0.asRad)
        y = (lat: -0.5.asRad, lon: 0.asRad)
        XCTAssertEqual(try! vincenty.solveInverse(x, y).distance, 110574.304, accuracy: delta)

        x = (lat: -0.5.asRad, lon: 0.asRad)
        y = (lat: 0.5.asRad, lon: 0.asRad)
        XCTAssertEqual(try! vincenty.solveInverse(x, y).distance, 110574.304, accuracy: delta)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 0.asRad, lon: 1.asRad)
        XCTAssertEqual(try! vincenty.solveInverse(x, y).distance, 111319.491, accuracy: delta)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 0.asRad, lon: 2.asRad)
        XCTAssertEqual(try! vincenty.solveInverse(x, y).distance, 222638.982, accuracy: delta)

        x = (lat: 0.asRad, lon: 0.5.asRad)
        y = (lat: 0.asRad, lon: -0.5.asRad)
        XCTAssertEqual(try! vincenty.solveInverse(x, y).distance, 111319.491, accuracy: delta)

        x = (lat: 0.asRad, lon: -0.5.asRad)
        y = (lat: 0.asRad, lon: 0.5.asRad)
        XCTAssertEqual(try! vincenty.solveInverse(x, y).distance, 111319.491, accuracy: delta)

        // Test Cardinals
        x = (lat: 0.0, lon: 0.0)
        y = (lat: pi/2, lon: 0.0) // north pole
        var (_, azimuths: (initialTrueTrack, finalTrueTrack)) = try! vincenty.solveInverse(x, y)
        XCTAssertEqual(initialTrueTrack, 0.0, accuracy: delta)
        XCTAssertEqual(finalTrueTrack, 0.0, accuracy: delta)

        y = (lat: 0.0, lon: pi/2) // east
        (_, azimuths: (initialTrueTrack, finalTrueTrack)) = try! vincenty.solveInverse(x, y)
        XCTAssertEqual(initialTrueTrack, Double.pi/2, accuracy: delta)
        XCTAssertEqual(finalTrueTrack, Double.pi/2, accuracy: delta)

        y = (lat: -pi/2, lon: 0.0) // south pole
        (_, azimuths: (initialTrueTrack, finalTrueTrack)) = try! vincenty.solveInverse(x, y)
        XCTAssertEqual(initialTrueTrack, Double.pi, accuracy: delta)
        XCTAssertEqual(finalTrueTrack, Double.pi, accuracy: delta)

        y = (lat: 0.0,lon: -pi/2) // west
        (_, azimuths: (initialTrueTrack, finalTrueTrack)) = try! vincenty.solveInverse(x, y)
        XCTAssertEqual(initialTrueTrack, 3*Double.pi/2, accuracy: delta)
        XCTAssertEqual(finalTrueTrack, 3*Double.pi/2, accuracy: delta)

    }

    /// Test against A330 FMS
    let fmsAcc = 0.49 // within half nm or degree
    func testNavigationAccurracy() {

        var x: (lat: Double, lon: Double), y: (lat: Double, lon: Double)

        //Urabi to Bumat
        x = (lat: (60+12/60).asRad, lon: (154+41.1/60).asRad)
        y = (lat: (61+50.1/60).asRad, lon: (160+33/60).asRad)
        var (distance, azimuths: (initialTrueTrack, _)) = try! vincenty.solveInverse(x, y)
        XCTAssertEqual(distance.inNm, 197, accuracy: fmsAcc)
        XCTAssertEqual(initialTrueTrack.asDegrees, 058, accuracy: fmsAcc)

        // Dacey is N5933.6 / W12604.5
        x = (lat: (59+33.6/60).asRad, lon: -(126+04.5/60).asRad)
        // MCT is N5321.4 / W00215.7
        y = (lat: (53+21.4/60).asRad, lon: -(2+15.7/60).asRad)
        // TRK036T3507
        (distance, azimuths: (initialTrueTrack, _)) = try! vincenty.solveInverse(x, y)
        // XCTAssertEqual(distance.inNm, 3507, accuracy: fmsAcc) //FMS seems to be wrong in this case...
        // http://www.gcmap.com/dist?P=N5933.6+W12604.5+-+N5321.4+W00215.7&DU=nm&DM=&SG=450&SU=kts
        let gDist = geodesic.distance(x, y)
        print("vincenty: \(distance), geodesic: \(gDist), delta: \(fabs(distance - gDist))")
        XCTAssertEqual(distance, gDist, accuracy: 1e-3)
        XCTAssertEqual(initialTrueTrack.asDegrees, 036, accuracy: fmsAcc)

    }

    /// use geodesic as reference and test vincenty distance.
    func testAgainstGeodesic() {
        var x: (lat: Double, lon: Double), y: (lat: Double, lon: Double)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 0.asRad, lon: 1.asRad)
        let v = try! vincenty.solveInverse(x, y).distance
        let g = geodesic.distance(x, y)
        print("vincenty: \(v), geodesic: \(g), delta: \(fabs(v - g))")
        XCTAssertEqual(v, g, accuracy: 1e-3)
    }

    /// nearly antipodal points, see https://en.wikipedia.org/wiki/Vincenty%27s_formulae#Nearly_antipodal_points
    func testNearlyAntipodalPoints() {
        var x: (lat: Double, lon: Double), y: (lat: Double, lon: Double)

        x = (lat: 0.asRad, lon: 0.asRad)
        y = (lat: 0.5.asRad, lon: 179.5.asRad)
        let v = try! vincenty.solveInverse(x, y).distance
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
        XCTAssertThrowsError(try vincenty.solveInverse(x, y))

        // we would like to have a good accuracy here, however, this is one of the cases, where vincenty fails.
//        let v = try! vincenty.distance(x, y)
//        let g = geodesic.distance(x, y)
//        print("vincenty: \(v), geodesic: \(g), delta: \(fabs(v - g))")
//        XCTAssertEqual(v, g, accuracy: 1e-3)
//        XCTAssertEqual(v, 19944127.421, accuracy: 1e-3)
    }
}
