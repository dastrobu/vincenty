# vincenty

[![Swift Version](https://img.shields.io/badge/swift-5.1-blue.svg)](https://swift.org) 
![Platform](https://img.shields.io/badge/platform-osx--64|linux--64-lightgrey.svg)
[![Build Travis-CI Status](https://travis-ci.org/dastrobu/vincenty.svg?branch=master)](https://travis-ci.org/dastrobu/vincenty) 

Solver for the inverse geodesic problem in Swift.

The inverse geodesic problem must be solved to compute the distance between two points on an oblate spheroid, or 
ellipsoid in general. The generalization to ellipsoids, which are not oblate spheroids is not further considered here, 
hence the term ellipsoid will be used synonymous with oblate spheroid.

The distance between two points is also known as the 
[Vincenty distance](https://en.wikipedia.org/wiki/Vincenty's_formulae).

Here is an example to compute the distance between two points (the poles in this case) on the 
[WGS 84 ellipsoid](https://en.wikipedia.org/wiki/World_Geodetic_System).

    import vincenty
    let d = try distance((lat: Double.pi / 2,lon: 0), (lat: -Double.pi / 2, lon: 0))
    
and that's it. 

## Installation

### Dependencies

At least `clang-3.6` is required. On linux one might need to install it explicitly.
There are no dependencies on macOS.
    
### Swift Package Manager

    dependencies: [
            .package(url: "https://github.com/dastrobu/vincenty.git", from: "1.0.0"),
        ],

## Cocoa Pods

Make sure a valid deployment target is setup in the Podfile and add

    pod 'vincenty', '~> 1'

## Implementation Details

This is a simple implementation of Vincenty's formulae. It is not the most accurate or most 
stable algorithm, however, easy to implement. 
There are more sophisticated implementations, see, e.g. 
[geodesic](https://github.com/dastrobu/geodesic).

## Convergence and Tolerance

Convergence and the accuracy of the result can be controlled via two parameters.  

    try distance((lat: 0,lon: 0), (lat: 0, lon: 0), tol: 1e-10, maxIter: 200)

## WGS 84 and other Ellipsoids

By default the 
[WGS 84 ellipsoid](https://en.wikipedia.org/wiki/World_Geodetic_System)
is employed, but different parameters can be specified, e.g. for the 
[GRS 80 ellipsoid](https://en.wikipedia.org/wiki/GRS_80).

    try distance((lat: Double.pi / 2, lon: 0), (lat: -Double.pi / 2, lon: 0), 
                 ellipsoid (a: 6378137.0, f: 1/298.257222100882711))



