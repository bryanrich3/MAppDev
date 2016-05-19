//
//  JUKESocket.m
//  UJuke
//
//  Created by Bryan Rich on 5/6/14.
//

#import "JUKESocket.h"

@implementation JUKESocket{
    NSString *player;
}

//connect to socket
-(void)socketConnect:(NSString *)playerID
{
    player = playerID;
    _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *err = nil;
    if (![self.socket connectToHost:@"www.chrisshafer.net" onPort:40004 error:&err])
    {
        NSLog(@"I goofed: %@", err);
    }
}

-(void)vote:(NSString *)songID
{
    NSData *data = [songID dataUsingEncoding:NSUTF8StringEncoding];
    [_socket writeData:data withTimeout:-1 tag:3];
}

//Connected to server
- (void)socket:(GCDAsyncSocket *)sender didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"Connected %@ %hu", host, port);
    
    NSString *str  = @"{\"id\":19,\"data\":\"gipIaxbv5yv9n53\",\"clientIdentifier\":\"UNKNOWN\"}\n";
    
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    [self.socket writeData:data withTimeout:-1 tag:1];
}

//sent data to server
-(void)socket:(GCDAsyncSocket *)sender didWriteDataWithTag:(long)tag
{
    if(tag == 1){
        NSLog(@"Write 1");
        [self.socket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:1];
    } else if (tag == 2) {
        NSLog(@"Write 2");
        [self.socket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:2];
    } else if (tag == 3) {
        NSLog(@"Write 3");
        [self.socket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:6];
    }
}

//read data from server
- (void)socket:(GCDAsyncSocket *)sender didReadData:(NSData *)data withTag:(long)tag
{
    if (tag == 1) {
        NSLog(@"Read 1");
        NSString *str  = [NSString stringWithFormat:@"{\"id\":403,\"data\":\"\",\"clientIdentifier\":\"%@\"}\n", player];
        
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        [self.socket writeData:data withTimeout:-1 tag:2];
        
    } else if (tag == 2) {
        NSLog(@"Read 2");
        
        [self.socket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:10 tag:3];
        
    } else if (tag == 3) {
        NSLog(@"Read 3");
        
        [self.socket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:4];
        
    } else if (tag == 4) {
        /*
         * get current song spotify id and set current variable
         */
        
        NSLog(@"Read 4");
        
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        //NSDictionary *jsonData = [jsonObject objectForKey:@"data"];
        
        //NSLog(@"%@", jsonObject[@"clientIdentifier"]);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"currentSong" object:nil userInfo:@{ @"jsonData" : jsonObject}];
        
        [self.socket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:5];
        
    } else if (tag == 5) {
        
        /*
         * get playlist and send to start
         */
        
        NSLog(@"Read 5");
        
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        NSDictionary *jsonData = [jsonObject objectForKey:@"data"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"playlist" object:nil userInfo:@{ @"jsonData" : jsonData}];
        
        [self.socket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:6];
        
    } else if (tag == 6) {
        /*
         * get current song or votes and update now playing or queue array
         */
        
        NSLog(@"Read 6");
        
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        NSDictionary *jsonData = [jsonObject objectForKey:@"data"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"votesOrCurrent" object:nil userInfo:@{ @"jsonData" : jsonData}];
        
        [self.socket readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:6];
    }
}

-(void)outOfRange
{
    [_socket disconnect];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"Disconnected");
}

- (void)socket:(GCDAsyncSocket *)sender shouldTimeoutReadWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length
{
    if (tag == 3) {
        NSLog(@"Could not reach player");
    }
}

@end
