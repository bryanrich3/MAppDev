//
//  JUKEGetData.m
//  UJuke
//
//  Created by Bryan Rich on 5/3/14.
//

#import "JUKEGetData.h"
#import "JUKETrack.h"

@implementation JUKEGetData

+ (JUKETrack *)getData:(NSDictionary *)trackID votes:(NSDictionary *)votes songID:(NSDictionary *)songID
{
    JUKETrack *result = [[JUKETrack alloc] init];
    result.trackID = [NSMutableString stringWithFormat:@"%@", trackID];
    NSString *temp = [NSString stringWithFormat:@"%@", votes];
    result.votes = [temp integerValue];
    result.songID = [NSMutableString stringWithFormat:@"%@", songID];
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    [self getSpotifyMetaData:trackID withBlock:^(JUKETrack *info) {
        result.album = info.album;
        result.track = info.track;
        result.artist = info.artist;
        dispatch_group_leave(group);
    }];
    
    dispatch_group_enter(group);
    [self getCoverArt:trackID withBlock:^(UIImage *info) {
        result.cover = info;
        dispatch_group_leave(group);
    }];
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    return result;
}

+ (void)getSpotifyMetaData:(NSDictionary *)trackID withBlock:(void (^)(JUKETrack *))block
{
    NSString *urlString = [NSString stringWithFormat:@"http://ws.spotify.com/lookup/1/.json?uri=spotify:track:%@", trackID];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    [[session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        JUKETrack *info = [[JUKETrack alloc] init];
        
        NSError *e;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&e];
        
        NSDictionary *track = [dictionary objectForKey:@"track"];
        
        NSDictionary *album = [track objectForKey:@"album"];
        info.album = album[@"name"];
        
        NSArray *artist = [track objectForKey:@"artists"];
        NSArray *artistName = [artist valueForKey:@"name"];
        for (int i = 0; i < [artistName count]; i++) {
            if (i == 0) {
                info.artist = [artistName objectAtIndex:i];
            } else {
                [info.artist appendString:[NSMutableString stringWithFormat:@", %@", [artistName objectAtIndex:i]]];
            }
        }
        
        info.track = track[@"name"];
        
        block(info);
    }] resume];
}

+ (void)getCoverArt:(NSDictionary *)trackID withBlock:(void (^)(UIImage *))block
{
    NSString *urlStringCover = [NSString stringWithFormat:@"https://embed.spotify.com/oembed/?url=spotify:track:%@", trackID];
    NSURL *urlCover = [NSURL URLWithString:urlStringCover];
    
    NSURLSession *sessionCover = [NSURLSession sharedSession];
    
    [[sessionCover dataTaskWithURL:urlCover completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        NSDictionary *coverUrl = [dictionary objectForKey:@"thumbnail_url"];
        NSMutableString *str = [NSMutableString stringWithFormat:@"%@", coverUrl];
        NSArray *strArray = [str componentsSeparatedByString:@"cover"];
        NSString *urlString = [NSString stringWithFormat:@"%@640%@", strArray[0], strArray[1]];
        
        NSURL *url = [NSURL URLWithString:urlString];
        
        NSURLSession *session = [NSURLSession sharedSession];
        
        [[session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            UIImage *image = [UIImage imageWithData:data];
            block(image);
        }] resume];
    }] resume];
}

@end
