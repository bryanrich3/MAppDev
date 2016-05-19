//
//  JUKETrack.m
//  UJuke
//
//  Created by Bryan Rich on 5/3/14.
//

#import "JUKETrack.h"

@implementation JUKETrack

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.album forKey:@"album"];
    [aCoder encodeObject:self.artist forKey:@"artist"];
    [aCoder encodeObject:self.cover forKey:@"cover"];
    [aCoder encodeObject:self.trackID forKey:@"trackID"];
    [aCoder encodeObject:self.songID forKey:@"songID"];
    [aCoder encodeObject:self.track forKey:@"track"];
    [aCoder encodeInt:(int)self.votes forKey:@"votes"];
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if(self){
        self.album = [aDecoder decodeObjectForKey:@"album"];
        self.artist = [aDecoder decodeObjectForKey:@"artist"];
        self.cover = [aDecoder decodeObjectForKey:@"cover"];
        self.trackID = [aDecoder decodeObjectForKey:@"trackID"];
        self.songID = [aDecoder decodeObjectForKey:@"songID"];
        self.track = [aDecoder decodeObjectForKey:@"track"];
        self.votes = [aDecoder decodeIntegerForKey:@"votes"];
    }
    
    return self;
}

@end
