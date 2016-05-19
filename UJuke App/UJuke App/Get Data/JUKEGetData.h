//
//  JUKEGetData.h
//  UJuke
//
//  Created by Bryan Rich on 5/3/14.
//

#import <Foundation/Foundation.h>
#import "JUKETrack.h"

@interface JUKEGetData : NSObject

+ (JUKETrack *)getData:(NSDictionary *)trackID votes:(NSDictionary *)votes songID:(NSDictionary *)songID;

@end
