//
//  Route.h
//  MapsDirections
//
//  Created by Phillip Ninan on 9/8/14.
//  Copyright (c) 2014 Google. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Route : NSObject
{
    NSMutableArray *legs;
    NSMutableArray *waypoints;
    NSMutableArray *steps;
    double totalDistanceInMiles;
    double totalTime;
    double mins;
    double hours;
    double latitude;
    double longitude;
}

@end
