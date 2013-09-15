//
//  SRDAlarm.m
//  sirend
//
//  Created by Harshad on 15/09/2013.
//
//

#import "SRDAlarm.h"

@interface SRDAlarm ()

@property (readwrite, nonatomic) NSUInteger hour;
@property (readwrite, nonatomic) NSUInteger minute;

@end

@implementation SRDAlarm

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    
    self = [super init];
    if (self != nil) {
        
        id hour = dictionary[@"hour"];
        if (![hour isKindOfClass:[NSNull class]]) {
            _hour = [hour intValue];
        }
        
        id minute = dictionary[@"minute"];
        if (![minute isKindOfClass:[NSNull class]]) {
            _minute = [minute intValue];
        }
    }
    
    return self;
}




@end
