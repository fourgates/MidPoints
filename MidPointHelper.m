//
//  MidPointHelper.m
//  MapsDirections
//
//  Created by Phillip Ninan on 9/7/14.
//  Copyright (c) 2014 Google. All rights reserved.
//

#import "MidPointHelper.h"
#import <GoogleMaps/GoogleMaps.h>
# define DEG_TO_RAD(degree): degree *180;

/*

 @see
 */
@implementation MidPointHelper

/**
 * Returns the angular distance between two points using the Haversine forumla
 * could also use Vincenty formula
 * @see http://www.daftlogic.com/uscript/geo-0.2.js
 var phi1 = point1.lat().toRadians();
 var phi2 = point2.lat().toRadians();
 
 var d_phi = (point2.lat() - point1.lat()).toRadians();
 var d_lmd = (point2.lng() - point1.lng()).toRadians();
 
 var A = Math.pow(Math.sin(d_phi / 2), 2) +
 Math.cos(phi1) * Math.cos(phi2) *
 Math.pow(Math.sin(d_lmd / 2), 2);
 
 return 2 * Math.atan2(Math.sqrt(A), Math.sqrt(1 - A));
 */
-(double)angularDistanceance: (CLLocationCoordinate2D)p1 : (CLLocationCoordinate2D)p2{
    // convert lattitude to radians
    double phi1 = [self latitudeToRadians:p1];
    double phi2 = [self latitudeToRadians:p2];
    
    double d_phi = p2.latitude - [self latitudeToRadians:p1];
    double d_lmd = p2.longitude - [self longitudeToRadians:p2];
    
    double A = pow(sin(d_phi / 2), 2) + cos(phi1) * cos(phi2) * pow(sin(d_lmd / 2), 2);
    
    return 2 * atan2(sqrt(A), sqrt(1 - A));

}
/**
 * Calculates an intermediate point on the geodesic between the two given
 * points.
 * @param {geo.Point} point1 The first point.
 * @param {geo.Point} point2 The second point.
 * @param {Number} [fraction] The fraction of distance between the first
 *     and second points.
 * @return {geo.Point}
 * @see http://williams.best.vwh.net/avform.htm#Intermediate
 */
- (CLLocationCoordinate2D)midPoint: (CLLocationCoordinate2D)p1 : (CLLocationCoordinate2D)p2 : (double)fraction{
    if (!fraction) {
        fraction = .5;
    }
    
    double phi1 = [self latitudeToRadians:p1];
    double phi2 = [self latitudeToRadians:p2];
    double lmd1 = [self longitudeToRadians:p1];
    double lmd2 = [self longitudeToRadians:p2];
    
    double cos_phi1 = cos(phi1);
    double cos_phi2 = cos(phi2);
    
    double angularDistance = [self angularDistanceance:p1 :p2];
    double sin_angularDistance = sin(angularDistance);
    
    double A = sin((1 - fraction) * angularDistance) / sin_angularDistance;
    double B = sin(fraction * angularDistance) / sin_angularDistance;
    
    double x = A * cos_phi1 * cos(lmd1) +
    B * cos_phi2 * cos(lmd2);
    
    double y = A * cos_phi1 * sin(lmd1) +
    B * cos_phi2 * sin(lmd2);
    
    double z = A * sin(phi1) +
    B * sin(phi2);
    
    double lat = atan2(z, sqrt(pow(x, 2) + [self toDegrees:pow(y, 2)]));
    double longitude = [self toDegrees:atan2(y, x)];
    return CLLocationCoordinate2DMake(lat, longitude);
    
    /*
     A=sin((1-f)*d)/sin(d)
     B=sin(f*d)/sin(d)
     x = A*cos(lat1)*cos(lon1) +  B*cos(lat2)*cos(lon2)
     y = A*cos(lat1)*sin(lon1) +  B*cos(lat2)*sin(lon2)
     z = A*sin(lat1)           +  B*sin(lat2)
     lat=atan2(z,sqrt(x^2+y^2))
     lon=atan2(y,x)
     
     // TODO: check for antipodality and fail w/ exception in that case
     if (geo.util.isUndefined(fraction) || fraction === null) {
     fraction = 0.5;
     }
     
     if (point1.equals(point2)) {
     return new geo.Point(point1);
     }
     
     var phi1 = point1.lat().toRadians();
     var phi2 = point2.lat().toRadians();
     var lmd1 = point1.lng().toRadians();
     var lmd2 = point2.lng().toRadians();
     
     var cos_phi1 = Math.cos(phi1);
     var cos_phi2 = Math.cos(phi2);
     
     var angularDistance = geo.math.angularDistance(point1, point2);
     var sin_angularDistance = Math.sin(angularDistance);
     
     var A = Math.sin((1 - fraction) * angularDistance) / sin_angularDistance;
     var B = Math.sin(fraction * angularDistance) / sin_angularDistance;
     
     var x = A * cos_phi1 * Math.cos(lmd1) +
     B * cos_phi2 * Math.cos(lmd2);
     
     var y = A * cos_phi1 * Math.sin(lmd1) +
     B * cos_phi2 * Math.sin(lmd2);
     
     var z = A * Math.sin(phi1) +
     B * Math.sin(phi2);
     
     return new geo.Point(
     Math.atan2(z, Math.sqrt(Math.pow(x, 2) +
     Math.pow(y, 2))).toDegrees(),
     Math.atan2(y, x).toDegrees());
     };*/
}

- (double) toDegrees: (double)degrees{
    return degrees * 180 / M_PI;
}
- (double) latitudeToRadians: (CLLocationCoordinate2D)coord{
    return coord.latitude * M_PI / 180;
}

- (double) longitudeToRadians: (CLLocationCoordinate2D)coord{
    return coord.longitude * M_PI / 180;
}

@end
