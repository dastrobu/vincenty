#if os(macOS) || os(iOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

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
                     ellipsoid: (a: Double, f: Double) = wgs84
) throws -> Double {

    assert(tol > 0, "tol '\(tol)' ≤ 0")

    // validate lat and lon values
    assert(x.lat >= -pi / 2 && x.lat <= pi / 2, "x.lat '\(x.lat)' outside [-π/2, π]")
    assert(y.lat >= -pi / 2 && y.lat <= pi / 2, "y.lat '\(y.lat)' outside [-π/2, π]")
    assert(x.lon >= -pi && x.lon <= pi, "x.lon '\(y.lon)' outside [-π, π]")
    assert(y.lon >= -pi && y.lon <= pi, "y.lon '\(y.lon)' outside [-π, π]")

    // shortcut for zero distance
    if x == y {
        return 0.0
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

    return B * a * (sigma - delta_sigma)
}
