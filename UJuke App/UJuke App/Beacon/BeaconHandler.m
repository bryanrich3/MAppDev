//
//  BeaconHandler.m
//  UJuke
//
//  Created by Bryan Rich on 5/8/14.
//  Copyright (c) 2014 U Juke. All rights reserved.
//

#import "BeaconHandler.h"

@implementation BeaconHandler

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.hasFoundBeacon = false;
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        [self initRegion];
        [self.locationManager startMonitoringForRegion:self.beaconRegion];
        [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
    }
    return self;
}

- (void)initRegion {
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"B9407F30-F5F8-466E-AFF9-25556B57FE6D"];
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"UJuke Beacon Region"];
    self.beaconRegion.notifyOnEntry = YES;
    self.beaconRegion.notifyOnExit = YES;
    self.beaconRegion.notifyEntryStateOnDisplay = YES;
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
    
    
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
    //self.beacon = nil;
    NSString *temp = @"OUT OF RANGE";
    [[NSNotificationCenter defaultCenter] postNotificationName:@"foundBeacon" object:nil userInfo:@{ @"beaconString" : temp}];
    //self.hasFoundBeacon = false;
    UILocalNotification *notification = [UILocalNotification new];
    notification.alertBody = @"Exit region notification";
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
	//NSLog(@"RANGED %d BEACONS", beacons.count);
    
	if (beacons.count > 0) {
        for(int i = 0; i < beacons.count; i++){
            if([[beacons[i] major] intValue] == 12345){
                self.beacon = beacons[i];
                CLProximity proximity = [self.beacon proximity];
                
                if(proximity == CLProximityFar || proximity == CLProximityNear || proximity == CLProximityImmediate){
                    //self.hasFoundBeacon = true;
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"foundBeacon" object:nil userInfo:@{ @"beacon" : self.beacon}];
                }
            }
        }
	}
}


@end
