//
//  MDViewController.h
//  MapsDirections
//
//  Created by Phillip Ninan
//  Copyright (c) 2014. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>

@interface MDViewController : UIViewController <GMSMapViewDelegate,UITextFieldDelegate>

@property IBOutlet UIButton *searchButton;
@property IBOutlet UIButton *zoomInButton;
@property IBOutlet UIButton *zoomOutButton;
@property IBOutlet UIButton *clearMapButton;
@property IBOutlet UIButton *subtractHour;
@property IBOutlet UIButton *addHour;
@property IBOutlet UITextField *startingPoint;
@property IBOutlet UITextField *destinationPoint;
@property IBOutlet UITextField *distance;
@property IBOutlet UITextField *time;
@end
