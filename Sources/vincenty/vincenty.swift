#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/*
 * Formula for bearings from http://www.movable-type.co.uk/scripts/latlong-vincenty.html
 */


/// Error indicating that the distance could not be computed within the maximal number of iterations.
public enum ConvergenceError: Error {
    case notConverged(maxIter: UInt, tol: Double, eps: Double)
}

/// [WGS 84 ellipsoid](https://en.wikipedia.org/wiki/World_Geodetic_System) definition
public let wgs84 = (a: 6378137.0, f: 1 / 298.257223563)

/// π (for convenience)
private let pi = Double.pi

///
/// Compute the distance between two points on an ellipsoid.
/// The ellipsoid parameters default to the WGS-84 parameters.
///
/// - Parameters:
///   - x: first point with latitude and longitude in radiant.
///   - y: second point with latitude and longitude in radiant.
///   - tol: tolerance for the computed distance (in meters)
///   - maxIter: maximal number of iterations
///   - a: first ellipsoid parameter in meters (defaults to WGS-84 parameter)
///   - f: second ellipsoid parameter in meters (defaults to WGS-84 parameter)
///
/// - Returns: distance between `x` and `y` in meters.
///
/// - Throws:
///   - `ConvergenceError.notConverged` if the distance computation does not converge within `maxIter` iterations.
public func distance(_ x: (lat: Double, lon: Double),
                     _ y: (lat: Double, lon: Double),
                     tol: Double = 1e-12,
                     maxIter: UInt = 200,
                     ellipsoid: (a: Double, f: Double) = wgs84) throws -> Double {
    try solveInverse(x, y, tol: tol, maxIter: maxIter, ellipsoid: ellipsoid).distance;
}


///
/// Compute the distance between two points on an ellipsoid.
/// The ellipsoid parameters default to the WGS-84 parameters.
///
/// - Parameters:
///   - x: first point with latitude and longitude in radiant.
///   - y: second point with latitude and longitude in radiant.
///   - tol: tolerance for the computed distance (in meters)
///   - maxIter: maximal number of iterations
///   - a: first ellipsoid parameter in meters (defaults to WGS-84 parameter)
///   - f: second ellipsoid parameter in meters (defaults to WGS-84 parameter)
///
/// - Returns: distance between `x` and `y` in meters. Azimuths (Initial and Final True Track) in radians.
///
/// - Throws:
///   - `VincentyError.notConverged` if the distance computation does not converge within `maxIter` iterations.
public func solveInverse(_ x: (lat: Double, lon: Double),
                     _ y: (lat: Double, lon: Double),
                     tol: Double = 1e-12,
                     maxIter: UInt = 200,
                     ellipsoid: (a: Double, f: Double) = wgs84
) throws -> (distance:Double,azimuths:(Double,Double)) {
    
    assert(tol > 0, "tol '\(tol)' ≤ 0")

    // validate lat and lon values
    assert(x.lat >= -pi / 2 && x.lat <= pi / 2, "x.lat '\(x.lat)' outside [-π/2, π/2]")
    assert(y.lat >= -pi / 2 && y.lat <= pi / 2, "y.lat '\(y.lat)' outside [-π/2, π/2]")
    assert(x.lon >= -pi && x.lon <= pi, "x.lon '\(x.lon)' outside [-π, π]")
    assert(y.lon >= -pi && y.lon <= pi, "y.lon '\(y.lon)' outside [-π, π]")

    // shortcut for zero distance
    if x == y {
        return (distance: 0.0, azimuths: (0.0, 0.0))
    }

    // compute ellipsoid constants
    let A: Double = ellipsoid.a
    let F: Double = ellipsoid.f
    let B: Double = (1 - F) * A
    let C: Double = (A * A - B * B) / (B * B)

    let u_x: Double = atan((1 - F) * tan(x.lat))
    let sin_u_x: Double = sin(u_x)
    let cos_u_x: Double = cos(u_x)

    let u_y: Double = atan((1 - F) * tan(y.lat))
    let sin_u_y: Double = sin(u_y)
    let cos_u_y: Double = cos(u_y)

    let l: Double = y.lon - x.lon

    var lambda: Double = l, tmp: Double = 0.0
    var q: Double = 0.0, p: Double = 0.0, sigma: Double = 0.0, sin_alpha: Double = 0.0, cos2_alpha: Double = 0.0
    var c: Double = 0.0, sin_sigma: Double = 0.0, cos_sigma: Double = 0.0, cos_2sigma: Double = 0.0

    for _ in 0..<maxIter {
        tmp = cos(lambda)
        q = cos_u_y * sin(lambda)
        p = cos_u_x * sin_u_y - sin_u_x * cos_u_y * tmp
        sin_sigma = sqrt(q * q + p * p)
        cos_sigma = sin_u_x * sin_u_y + cos_u_x * cos_u_y * tmp
        sigma = atan2(sin_sigma, cos_sigma)

        // catch zero division problem
        if sin_sigma == 0.0 {
            sin_sigma = Double.leastNonzeroMagnitude
        }

        sin_alpha = (cos_u_x * cos_u_y * sin(lambda)) / sin_sigma
        cos2_alpha = 1 - sin_alpha * sin_alpha
        cos_2sigma = cos_sigma - (2 * sin_u_x * sin_u_y) / cos2_alpha

        // check for nan
        if cos_2sigma.isNaN {
            cos_2sigma = 0.0
        }

        c = F / 16.0 * cos2_alpha * (4 + F * (4 - 3 * cos2_alpha))
        tmp = lambda
        lambda = (l + (1 - c) * F * sin_alpha
            * (sigma + c * sin_sigma
            * (cos_2sigma + c * cos_sigma
            * (-1 + 2 * cos_2sigma * cos_2sigma
        )))
        )

        if fabs(lambda - tmp) < tol {
            break
        }

    }
    let eps: Double = fabs(lambda - tmp)
    if eps >= tol {
        throw ConvergenceError.notConverged(maxIter: maxIter, tol: tol, eps: eps)
    }

    let uu: Double = cos2_alpha * C
    let a: Double = 1 + uu / 16384 * (4096 + uu * (-768 + uu * (320 - 175 * uu)))
    let b: Double = uu / 1024 * (256 + uu * (-128 + uu * (74 - 47 * uu)))
    let delta_sigma: Double = (b * sin_sigma
        * (cos_2sigma + 1.0 / 4.0 * b
        * (cos_sigma * (-1 + 2 * cos_2sigma * cos_2sigma)
        - 1.0 / 6.0 * b * cos_2sigma
        * (-3 + 4 * sin_sigma * sin_sigma)
        * (-3 + 4 * cos_2sigma * cos_2sigma))))
    
    let distance = B * a * (sigma - delta_sigma)
    
    //Azimuth calculations:
    let sinSq_sigma = q * q + p * p
    // note special handling of exactly antipodal points where sin²σ = 0 (due to discontinuity
    // atan2(0, 0) = 0 but atan2(ε, 0) = π/2 / 90°) - in which case bearing is always meridional,
    // due north (or due south!)
    // α = azimuths of the geodesic; α2 the direction P₁ P₂ produced
    let a1 = abs(sinSq_sigma) < Double.leastNonzeroMagnitude ? 0 : atan2(cos_u_y*sin(lambda),  cos_u_x*sin_u_y-sin_u_x*cos_u_y*cos(lambda))
    let a2 = abs(sinSq_sigma) < Double.leastNonzeroMagnitude ? Double.pi : atan2(cos_u_x*sin(lambda), -sin_u_x*cos_u_y+cos_u_x*sin_u_y*cos(lambda))
    
    let initialTrueTrack = abs(distance) < Double.leastNonzeroMagnitude ? Double.nan : wrap2pi(a1)
    let finalTrueTrack = abs(distance) < Double.leastNonzeroMagnitude ? Double.nan : wrap2pi(a2)
    
    return (distance: distance, azimuths: (initialTrueTrack, finalTrueTrack))
    
}

/* Source: https://www.movable-type.co.uk/scripts/geodesy/docs/dms.js.html */

private func wrap2pi(_ radians:Double) -> Double
{
    // avoid rounding due to arithmetic ops if within range
    guard radians < 0 || radians >= 2*Double.pi  else {
        return radians
    }
    
    // bearing wrapping requires a sawtooth wave function with a vertical offset equal to the
    // amplitude and a corresponding phase shift; this changes the general sawtooth wave function from
    //     f(x) = (2ax/p - p/2) % p - a
    // to
    //     f(x) = (2ax/p) % p
    // where a = amplitude, p = period, % = modulo; however, Swift '%' is a remainder operator
    // not a modulo operator - for modulo, replace 'x%n' with '((x%n)+n)%n'
    let x = radians, a = Double.pi, p = 2*Double.pi
    
    return ((2*a*x/p).truncatingRemainder(dividingBy: p)+p).truncatingRemainder(dividingBy: p)
}

