//
//  SRDHelper.m
//  sirend
//
//  Created by Harshad on 15/09/2013.
//
//

#import "SRDHelper.h"
#import "SRDAlarm.h"

NSUInteger const SRDSecondsInAnHour = 3600;
NSUInteger const SRDSecondsInAMinute = 60;

@implementation SRDHelper

+ (NSTimeInterval)currentNormalizedDateAsTimestamp {
    
    NSDateFormatter *aDateFormatter = [[NSDateFormatter alloc] init];
    [aDateFormatter setDateFormat:@"dd-MM-yyyy"];
    
    NSString *currentDateAsString = [aDateFormatter stringFromDate:[NSDate date]];
    currentDateAsString = [currentDateAsString stringByAppendingFormat:@" 00:00:00"];
    
    [aDateFormatter setDateFormat:@"dd-MM-yyyy HH:mm:ss"];
    
    NSDate *normalizedDate = [aDateFormatter dateFromString:currentDateAsString];
    
    [aDateFormatter release];
    
    return [normalizedDate timeIntervalSince1970];
}

+ (NSTimeInterval)timestampForCurrentDayWithAlarmHour:(NSUInteger)hour minute:(NSUInteger)minute {
    
    return [self currentNormalizedDateAsTimestamp] + (hour * SRDSecondsInAnHour) + (minute * SRDSecondsInAMinute);
    
}

+ (NSArray *)readAlarmsFromPlistPath:(NSString *)plistPath {
    
    NSDictionary *plistContents = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    
    NSArray *plistAlarms = plistContents[@"Alarms"];
    
    NSMutableArray *alarmsToReturn = nil;
    
    if (![plistAlarms isKindOfClass:[NSNull class]] && plistAlarms.count > 0) {
        
        alarmsToReturn = [NSMutableArray arrayWithCapacity:plistAlarms.count];
        
        for (NSDictionary *aDictionary in plistAlarms) {
            
            SRDAlarm *anAlarm = [[SRDAlarm alloc] initWithDictionary:aDictionary];
            
            [alarmsToReturn addObject:anAlarm];
            
            [anAlarm release];
        }
    }
    
    return alarmsToReturn;
}

@end
