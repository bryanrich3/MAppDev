//
//  JUKESocket.h
//  UJuke
//
//  Created by Bryan Rich on 5/6/14.
//

#import "GCDAsyncSocket.h"

@interface JUKESocket : GCDAsyncSocket

@property (nonatomic, strong) GCDAsyncSocket *socket;
-(void)socketConnect:(NSString *)playerID;
-(void)vote:(NSString *)songID;
-(void)outOfRange;

@end
