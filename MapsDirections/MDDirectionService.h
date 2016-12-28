//
//  MDDirectionService.h
//  MapsDirections
//
//  Created by Phillip Ninan
//  Copyright (c) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MDDirectionService : NSObject

- (void)setDirectionsQuery:(NSDictionary *)object withSelector:(SEL)selector
              withDelegate:(id)delegate;
- (void)retrieveDirections:(SEL)sel withDelegate:(id)delegate;
- (void)fetchedData:(NSData *)data withSelector:(SEL)selector
       withDelegate:(id)delegate;
@end
