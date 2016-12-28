//
//  MDViewController.m
//  MapsDirections
//
//  Created by Phillip Ninan
//  Copyright (c) 2014. All rights reserved.
//

#import "MDViewController.h"
#import "MDDirectionService.h"
#import <GoogleMaps/GoogleMaps.h>

@interface MDViewController () {
    GMSMapView *mapView_;
    NSMutableArray *waypoints_;
    NSMutableArray *waypointStrings_;
    double latitude_;
    double longitude_;
    float zoomLevel;
    double radius_;
    double distanceInMiles_;
    NSString *distance_;
    NSString *duration_;
    GMSCircle *circle_;
    CLGeocoder *_geocoder;
}
@end

@implementation MDViewController

#pragma mark - Geocoding
- (void)fetchCoordinates{
    if (!_geocoder) {
        _geocoder = [[CLGeocoder alloc] init];
    }
    
    // set address
    NSString *address = @"black";
    
    // create geo request
    [_geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error) {
        NSLog(@"%@",[error localizedDescription]);
        
        // get geo response
        CLPlacemark *placemark = [placemarks objectAtIndex:0];
        CLLocation *location = placemark.location;
        CLLocationCoordinate2D coordinate = location.coordinate;
        
        //put marker at the position
        GMSMarker *marker = [GMSMarker markerWithPosition:coordinate];
        marker.title = @"Home";
        
        //set the marker on the map
        marker.map = mapView_;
        
        //add the marker to a waypoint
        [waypoints_ addObject:marker];
        [mapView_ animateToLocation:coordinate];
        
        NSString *areaOfInterest = [placemark.areasOfInterest objectAtIndex:0];
        //CLS_LOG(@"Area of Interest: %@",areaOfInterest);

    }];
}

#pragma mark - Map Delegates
- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:
(CLLocationCoordinate2D)coordinate {
    NSLog(@"You tapped at %f,%f", coordinate.latitude, coordinate.longitude);
    
    // hide keyboard
    [self.startingPoint resignFirstResponder];
    [self.destinationPoint resignFirstResponder];
    [self.time resignFirstResponder];
    [self.distance resignFirstResponder];
    
    //if there are two clicked points get directions
    if([waypoints_ count]<2){
        //get position
        CLLocationCoordinate2D position = CLLocationCoordinate2DMake(
                                                                     coordinate.latitude,
                                                                     coordinate.longitude);
        
        //put marker at the position
        GMSMarker *marker = [GMSMarker markerWithPosition:position];
        marker.title = @"A";
        
        //set the marker on the map
        marker.map = mapView_;
        
        //add the marker to a waypoint
        [waypoints_ addObject:marker];
        
        //create string from the lat and long coordinates
        NSString *positionString = [[NSString alloc] initWithFormat:@"%f,%f",
                                    coordinate.latitude,coordinate.longitude];
        
        //add strings to array
        [waypointStrings_ addObject:positionString];
        //there is no sensor
        NSString *sensor = @"false";
        
        //parameters = sensor, string of points, nil
        NSArray *parameters = [NSArray arrayWithObjects:sensor, waypointStrings_,
                               nil];
        
        //create keys for parameters
        NSArray *keys = [NSArray arrayWithObjects:@"sensor", @"waypoints", nil];
        
        //create query with dictionary (parameters), and keys
        NSDictionary *query = [NSDictionary dictionaryWithObjects:parameters
                                                          forKeys:keys];
        
        //init the mdd service
        MDDirectionService *mds=[[MDDirectionService alloc] init];
        
        //create selector method
        SEL selector = @selector(addDirections:);
        
        //add direction query to service
        //add selector when response returns
        //add delegate as the view
        [mds setDirectionsQuery:query
                   withSelector:selector
                   withDelegate:self];
    }
}

#pragma mark - Map Functions
/*
 Method called when the MDDservice returns response
 */
- (void)addDirections:(NSDictionary *)json {

    // parse routes from json response
    NSDictionary *routes = [json objectForKey:@"routes"][0];
    NSDictionary *legs = [routes objectForKey:@"legs"][0];
    NSDictionary *steps = [legs objectForKey:@"steps"][0];
    NSDictionary *startLocation = [steps objectForKey:@"start_location"];
    NSDictionary *steps2 = [legs objectForKey:@"steps"];
    //set start cordinates
    latitude_ = [[startLocation objectForKey:@"lat"]doubleValue];
    longitude_ = [[startLocation objectForKey:@"lng"]doubleValue];
    
    //get distance and duration
    distance_ = [[legs valueForKey:@"distance"]valueForKey:@"value"];
    duration_ = [[legs valueForKey:@"duration"]valueForKey:@"value"];
    
    if ([waypoints_ count]>1) {
        [self parseResponse:json];
        
        [self.distance setText:[[legs valueForKey:@"distance"]valueForKey:@"text"]];
        [self.time setText:[[legs valueForKey:@"duration"]valueForKey:@"text"]];
        [self.distance setHidden:NO];
        [self.time setHidden:NO];
        [self.subtractHour setHidden:NO];
        [self.addHour setHidden:NO];
        
        //store distance
        distanceInMiles_ = [[self.distance text]doubleValue];
        
        //get the number of steps
        int count = [[legs objectForKey:@"steps"]count];
        double totalDistance = 0.0;
        for(int i=0;i<count;i++){
            NSDictionary *step = [legs objectForKey:@"steps"][i];
            
            //get end location
            NSDictionary *endLocation = [step objectForKey:@"end_location"];
            
            //end lat and long
            double lat2 = [[endLocation objectForKey:@"lat"]doubleValue];
            double lng2 = [[endLocation objectForKey:@"lng"]doubleValue];
    
            if(i==count-1){
                //start coordinate and end coordinate
                CLLocationCoordinate2D startCoordinate = CLLocationCoordinate2DMake(latitude_, longitude_);
                CLLocationCoordinate2D endCoordinate = CLLocationCoordinate2DMake(lat2, lng2);
                totalDistance += ((startCoordinate.latitude>endCoordinate.latitude)&&(startCoordinate.longitude>endCoordinate.longitude)) ?
                [self getDistance:startCoordinate :endCoordinate] : [self getDistance:endCoordinate :startCoordinate] ;
                //if (totalDistance >= midpoint) {
                    //NSLog(@"Aproximent midpoint: %f",totalDistance * 0.00062137);
                    //NSLog(@"Actual Midpoint: %f",midpoint);
                    //}
                radius_ = totalDistance;
            }

        }
        
        //set circle
        circle_ = [GMSCircle circleWithPosition:CLLocationCoordinate2DMake(latitude_, longitude_)
                                                 radius:totalDistance];
        //put cicle onto map
        circle_.map = mapView_;
    }
    
    //get polyline route to add to mape
    NSDictionary *route = [routes objectForKey:@"overview_polyline"];
    
    //get all the points in the map
    NSString *overview_route = [route objectForKey:@"points"];
    
    // create path from all points on map
    GMSPath *path = [GMSPath pathFromEncodedPath:overview_route];
    
    double path_count = [path count];
    double totalDistance = 0;
    // new
    NSString *distanceString = [[legs valueForKey:@"distance"]valueForKey:@"value"];
    double tDistance = [distanceString doubleValue];
    double totalMeters = tDistance;
    double midpoint = totalMeters / 2;
    for(int i=1; i < [path count]; i++){
        CLLocationCoordinate2D pt1 = [path coordinateAtIndex:i];
        CLLocationCoordinate2D pt2= [path coordinateAtIndex:i-1];
        
        CLLocation *location1 = [[CLLocation alloc]initWithLatitude:pt1.latitude longitude:pt1.longitude];
        
        CLLocation *location2 = [[CLLocation alloc]initWithLatitude:pt2.latitude longitude:pt2.longitude];
        
        totalDistance += [location1 distanceFromLocation:location2];
        if (totalDistance >= midpoint) {
            NSLog(@"Aproximent midpoint: %f",totalDistance * 0.00062137);
            NSLog(@"Actual Midpoint: %f",midpoint * 0.00062137);
            
            //put marker at the position
            GMSMarker *marker = [GMSMarker markerWithPosition:[path coordinateAtIndex:i]];
            [marker setTitle:@"Midpoint"];
            marker.infoWindowAnchor = CGPointMake(0.5, 0.5);
            //marker.icon = [UIImage imageNamed:@"house"];
            marker.map = mapView_;
            
            //set the marker on the map
            marker.map = mapView_;
            break;
        }
    }
    //create polyline from the path
    GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
    
    //add pth to the map
    polyline.map = mapView_;
}
- (NSMutableArray *)parseResponse:(NSDictionary *)response
{
    NSArray *routes = [response objectForKey:@"routes"];
    NSDictionary *route = [routes lastObject];
    if (route) {
        NSString *overviewPolyline = [[route objectForKey: @"overview_polyline"] objectForKey:@"points"];
        return  [self decodePolyLine:overviewPolyline];
    }
    return nil;
}


-(NSMutableArray *)decodePolyLine:(NSString *)encodedStr {
    
    NSMutableString *encoded = [[NSMutableString alloc]initWithCapacity:[encodedStr length]];
    [encoded appendString:encodedStr];
    [encoded replaceOccurrencesOfString:@"\\\\" withString:@"\\"
                                options:NSLiteralSearch range:NSMakeRange(0,
                                                                          [encoded length])];
    NSInteger len = [encoded length];
    NSInteger index = 0;
    NSMutableArray *array = [[NSMutableArray alloc] init]; NSInteger lat=0;
    NSInteger lng=0;
    while (index < len) {
        NSInteger b; NSInteger shift = 0; NSInteger result = 0; do {
            b = [encoded characterAtIndex:index++] - 63; result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        NSInteger dlat = ((result & 1) ? ~(result >> 1)
                          : (result >> 1)); lat += dlat;
        shift = 0; result = 0; do {
            b = [encoded characterAtIndex:index++] - 63; result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        NSInteger dlng = ((result & 1) ? ~(result >> 1)
                          : (result >> 1)); lng += dlng;
        NSNumber *latitude = [[NSNumber alloc] initWithFloat:lat * 1e-5]; NSNumber *longitude = [[NSNumber alloc] initWithFloat:lng * 1e-5];
        CLLocation *location = [[CLLocation alloc] initWithLatitude: [latitude floatValue] longitude:[longitude floatValue]];
        [array addObject:location]; }
    return array;
}
#pragma mark - Math Functions
-(double)calculateRadius: (double) x
{
    return x * M_PI / 180;
}

-(double)getDistance: (CLLocationCoordinate2D)p1 : (CLLocationCoordinate2D)p2
{
    double R = 6371000;
    double dLat = [self calculateRadius:(p2.latitude - p1.latitude)];
    double dLong = [self calculateRadius:(p2.longitude - p1.longitude)];
    double a = sin(dLat/2)*sin(dLat/2) +
    cos([self calculateRadius:p1.latitude]) * cos([self calculateRadius:p2.latitude])*
    sin(dLong/2)*sin(dLong/2);
    float c = 2 * atan2(sqrt(a), sqrt(1-a));
    
    return R*c;
}

#pragma mark - View Delegates
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //add search button
    self.searchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.searchButton.layer setCornerRadius:10.0f];
    [self.searchButton setBackgroundColor:[UIColor whiteColor]];
    [self.searchButton setFrame:CGRectMake(500, 900, 100, 40)];
    [self.searchButton setTitle:@"Find" forState:UIControlStateNormal];
    [self.searchButton addTarget:self action:@selector(findDestSel) forControlEvents:UIControlEventTouchDown];
    
    //add clear button
    self.clearMapButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.clearMapButton.layer setCornerRadius:10.0f];
    [self.clearMapButton setBackgroundColor:[UIColor whiteColor]];
    [self.clearMapButton setFrame:CGRectMake(600, 900, 100, 40)];
    [self.clearMapButton setTitle:@"Clear Map" forState:UIControlStateNormal];
    [self.clearMapButton addTarget:self action:@selector(clearMapSel) forControlEvents:UIControlEventTouchDown];
    
    //zoom in button
    self.zoomInButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.zoomInButton.layer setCornerRadius:10.0f];
    [self.zoomInButton setBackgroundColor:[UIColor whiteColor]];
    [self.zoomInButton setFrame:CGRectMake(0, 900, 100, 40)];
    [self.zoomInButton setTitle:@"Zoom In" forState:UIControlStateNormal];
    [self.zoomInButton addTarget:self action:@selector(zoomInSel) forControlEvents:UIControlEventTouchDown];
    
    //zoom out button
    self.zoomOutButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.zoomOutButton.layer setCornerRadius:10.0f];
    [self.zoomOutButton setBackgroundColor:[UIColor whiteColor]];
    [self.zoomOutButton setFrame:CGRectMake(100, 900, 100, 40)];
    [self.zoomOutButton setTitle:@"Zoom Out" forState:UIControlStateNormal];
    [self.zoomOutButton addTarget:self action:@selector(zoomOutSel) forControlEvents:UIControlEventTouchDown];
    
    //add text fields
    self.startingPoint = [[UITextField alloc] initWithFrame:CGRectMake(0, 30, 300, 40)];
    [self.startingPoint setBorderStyle:UITextBorderStyleRoundedRect];
    [self.startingPoint setPlaceholder:@"Starting Point"];
    [self.startingPoint setDelegate:self];
    
    self.destinationPoint = [[UITextField alloc] initWithFrame:CGRectMake(300, 30, 300, 40)];
    self.destinationPoint.borderStyle = UITextBorderStyleRoundedRect;
    [self.destinationPoint setPlaceholder:@"Destination"];
    self.destinationPoint.delegate = self;
    
    self.distance = [[UITextField alloc] initWithFrame:CGRectMake(500, 800, 100, 40)];
    self.distance.borderStyle = UITextBorderStyleRoundedRect;
    [self.distance setPlaceholder:@"200 Miles"];
    self.distance.delegate = self;
    self.distance.hidden = true;
    
    self.time = [[UITextField alloc] initWithFrame:CGRectMake(600, 800, 100, 40)];
    self.time.borderStyle = UITextBorderStyleRoundedRect;
    [self.time setPlaceholder:@"2.5 Hours"];
    self.time.delegate = self;
    self.time.hidden = true;
    
    //add subtract hour button
    self.subtractHour = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.subtractHour.layer setCornerRadius:10.0f];
    [self.subtractHour setBackgroundColor:[UIColor whiteColor]];
    [self.subtractHour setFrame:CGRectMake(600, 950, 100, 40)];
    [self.subtractHour setTitle:@"Subtract Time" forState:UIControlStateNormal];
    [self.subtractHour addTarget:self action:@selector(subtract) forControlEvents:UIControlEventTouchDown];
    [self.subtractHour setHidden:YES];
    
    //add add hour button
    self.addHour = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.addHour.layer setCornerRadius:10.0f];
    [self.addHour setBackgroundColor:[UIColor whiteColor]];
    [self.addHour setFrame:CGRectMake(500, 950, 100, 40)];
    [self.addHour setTitle:@"Add Time" forState:UIControlStateNormal];
    [self.addHour addTarget:self action:@selector(add) forControlEvents:UIControlEventTouchDown];
    [self.addHour setHidden:YES];
    
    //add button and fields to view
    [self.view addSubview:self.searchButton];
    [self.view addSubview:self.clearMapButton];
    [self.view addSubview:self.zoomInButton];
    [self.view addSubview:self.zoomOutButton];
    [self.view addSubview:self.clearMapButton];
    [self.view addSubview:self.startingPoint];
    [self.view addSubview:self.destinationPoint];
    [self.view addSubview:self.distance];
    [self.view addSubview:self.time];
    [self.view addSubview:self.subtractHour];
    [self.view addSubview:self.addHour];
    [self.view setUserInteractionEnabled:YES];
    [self removeGMSBlockingGestureRecognizerFromMapView:mapView_];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - View Functions
- (void)findDestSel{
    NSLog(@"Find Destination");
    // hide keyboard
    [self.startingPoint resignFirstResponder];
    [self.destinationPoint resignFirstResponder];
    [self.time resignFirstResponder];
    [self.distance resignFirstResponder];
    
    self.time.hidden = false;
    self.distance.hidden = false;
}

- (void)subtract{
    NSLog(@"Subtract Hour");
    // hide keyboard
    [self.startingPoint resignFirstResponder];
    [self.destinationPoint resignFirstResponder];
    [self.time resignFirstResponder];
    [self.distance resignFirstResponder];
    
    self.time.hidden = false;
    self.distance.hidden = false;
    
    double mph = [distance_ doubleValue] / [duration_ doubleValue];
    distanceInMiles_ = distanceInMiles_ * .8;
    NSString *d = [NSString stringWithFormat:@"%.1f",distanceInMiles_ ];
    [self.distance setText:d];
    
    radius_ = radius_ *.8;
    
    //null out previous circle
    [circle_ setMap:(nil)];
    //set circle
    circle_ = [GMSCircle circleWithPosition:CLLocationCoordinate2DMake(latitude_, longitude_)
                                     radius:radius_];
    //put cicle onto map
    circle_.map = mapView_;
}

- (void)add{
    NSLog(@"Subtract Hour");
    // hide keyboard
    [self.startingPoint resignFirstResponder];
    [self.destinationPoint resignFirstResponder];
    [self.time resignFirstResponder];
    [self.distance resignFirstResponder];
    
    self.time.hidden = false;
    self.distance.hidden = false;
    
    double mph = [distance_ doubleValue] / [duration_ doubleValue];
    radius_ = radius_ *1.8;
    
    //null out previous circle
    [circle_ setMap:(nil)];
    //set circle
    circle_ = [GMSCircle circleWithPosition:CLLocationCoordinate2DMake(latitude_, longitude_)
                                     radius:radius_];
    //put cicle onto map
    circle_.map = mapView_;
    
}
- (void)zoomOutSel{
    NSLog(@"ZOOM OUT");
    [self fetchCoordinates];
    // hide keyboard
    [self.startingPoint resignFirstResponder];
    [self.destinationPoint resignFirstResponder];
    [self.time resignFirstResponder];
    [self.distance resignFirstResponder];
    
    zoomLevel = zoomLevel-1;
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:latitude_
                                                            longitude:longitude_
                                                                 zoom:zoomLevel];
    [mapView_ setCamera:camera];
}
- (void)clearMapSel{
    NSLog(@"Clear Map");
    // hide keyboard
    [self.startingPoint resignFirstResponder];
    [self.destinationPoint resignFirstResponder];
    [self.time resignFirstResponder];
    [self.distance resignFirstResponder];
    
    //hide text fields
    self.time.hidden = true;
    self.distance.hidden = true;
    
    [mapView_ clear];
    [waypoints_ removeAllObjects];
    [waypointStrings_ removeAllObjects];
    
    latitude_ = 37.778376;
    longitude_ = -122.409853;
    zoomLevel = (float)16.0;
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:latitude_
                                                            longitude:longitude_
                                                                 zoom:zoomLevel];
    [mapView_ setCamera:camera];
}
- (void)zoomInSel{
    NSLog(@"ZOOM IN");
    //[[Crashlytics sharedInstance] crash];
    // hide keyboard
    [self.startingPoint resignFirstResponder];
    [self.destinationPoint resignFirstResponder];
    [self.time resignFirstResponder];
    [self.distance resignFirstResponder];
    zoomLevel = zoomLevel+1;
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:latitude_
                                                            longitude:longitude_
                                                                 zoom:zoomLevel];
    [mapView_ setCamera:camera];
}
- (void)loadView {
    latitude_ = 37.778376;
    longitude_ = -122.409853;
    zoomLevel = (float)16.0;
    waypoints_ = [[NSMutableArray alloc]init];
    waypointStrings_ = [[NSMutableArray alloc]init];
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:latitude_
                                                            longitude:longitude_
                                                                 zoom:zoomLevel];
    mapView_ = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    mapView_.delegate = self;
    self.view = mapView_;
    
}

#pragma mark - Text Field Delegates
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    NSLog(@"textFieldShouldBeginEditing");
    [textField setBackgroundColor:[UIColor colorWithRed:220.0f/255.0f green:220.0f/255.0f blue:220.0f/255.0f alpha:1.0f]];
    return YES;
}
- (void)textFieldDidEndEditing:(UITextField *)textField{
    NSLog(@"DONE");
    [textField setBackgroundColor:[UIColor whiteColor]];
    [textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    //hide the keyboard
    [textField resignFirstResponder];
    
    //return NO or YES, it doesn't matter
    return YES;
}
// Remove the GMSBlockingGestureRecognizer of the GMSMapView.
- (void)removeGMSBlockingGestureRecognizerFromMapView:(GMSMapView *)mapView
{
    if([mapView.settings respondsToSelector:@selector(consumesGesturesInView)]) {
        mapView.settings.consumesGesturesInView = NO;
    }
    else {
        for (id gestureRecognizer in mapView.gestureRecognizers)
        {
            if (![gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]])
            {
                [mapView removeGestureRecognizer:gestureRecognizer];
            }
        }
    }
}

@end
