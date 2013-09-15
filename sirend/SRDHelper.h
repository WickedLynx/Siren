//
//  SRDHelper.h
//  sirend
//
//  Created by Harshad on 15/09/2013.
//
//

#import <Foundation/Foundation.h>

@interface SRDHelper : NSObject

+ (NSTimeInterval)currentNormalizedDateAsTimestamp;

+ (NSTimeInterval)timestampForCurrentDayWithAlarmHour:(NSUInteger)hour minute:(NSUInteger)minute;

+ (NSArray *)readAlarmsFromPlistPath:(NSString *)plistPath;

@end
