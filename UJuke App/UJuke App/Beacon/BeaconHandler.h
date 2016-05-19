//
//  BeaconHandler.h
//  UJuke
//
//  Created by Bryan Rich on 5/8/14.
//  Copyright (c) 2014 U Juke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface BeaconHandler : NSObject <CLLocationManagerDelegate>

@property (strong, nonatomic) CLBeaconRegion *beaconRegion;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLBeacon *beacon;
@property (assign, nonatomic) BOOL hasFoundBeacon;

@end
