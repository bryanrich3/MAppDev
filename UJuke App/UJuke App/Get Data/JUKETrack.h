//
//  JUKETrack.h
//  UJuke
//
//  Created by Bryan Rich on 5/3/14.
//

#import <Foundation/Foundation.h>

@interface JUKETrack : NSObject <NSCoding>

@property (nonatomic, strong) NSMutableString *album;
@property (nonatomic, strong) NSMutableString *artist;
@property (nonatomic, strong) NSMutableString *track;
@property (nonatomic, strong) NSMutableString *trackID;
@property (nonatomic, strong) NSMutableString *songID;
@property (nonatomic, assign) NSInteger votes;
@property (nonatomic, strong) UIImage *cover;

@end
