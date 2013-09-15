//
//  main.m
//  sirend
//
//  Created by Harshad on 15/09/2013.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Celestial/Celestial.h>

#import "SRDHelper.h"
#import "NSTask.h"
#import "SRDAlarm.h"


// The path for the preferences file for Clock.app
NSString *const SirendMobileTimerPlistPath = @"/var/mobile/Library/Preferences/com.apple.mobiletimer.plist";

// The path for the shell script which reloads the daemon
NSString *const SirendReloadScriptPath = @"/usr/local/bin/reloadsirend";

// The path to the launchd plist of the daemon
NSString *const SirendLaunchdPlistPath = @"/var/mobile/Library/LaunchDaemons/com.lbs.sirend.plist";

// The path where the log file sits
NSString *const SirendLogMessagePath = @"/tmp/sirendlog.txt";

// The number of seconds before the alarm when the volume will be boosted
NSTimeInterval const SirendTimeIntervalForActivation = 120;

int main (int argc, const char * argv[])
{

    @autoreleasepool
    {	
        
        // First step is to fetch all alarms from the Clock app
        NSArray *alarms = [[SRDHelper readAlarmsFromPlistPath:SirendMobileTimerPlistPath] retain];
        
        NSString *logMessage = [NSString stringWithFormat:@"-----------sirend--%@-------------", [NSDate date]];
        
        
        // Check if there are any alarms set
        if (alarms.count > 0) {
            
            logMessage = [logMessage stringByAppendingFormat:@"\n Found %d alarms!", alarms.count];
            // Now we will iterate through these to determine if there are any alarms that will be triggered within 2 minutes from the current time
            NSUInteger alarmHour = 0;
            NSUInteger alarmMinute = 0;
            NSTimeInterval alarmTimestampForToday = 0;
            
            NSTimeInterval currentTimeStamp = [[NSDate date] timeIntervalSince1970];
            logMessage = [logMessage stringByAppendingFormat:@"\n Current timestamp: %@", [@(currentTimeStamp) stringValue]];
            
            BOOL shouldBoost = NO;
            
            for (SRDAlarm *anAlarm in alarms) {
                
                alarmHour = [anAlarm hour];
                logMessage = [logMessage stringByAppendingFormat:@"\n Alarm hour: %d", alarmHour];
                
                alarmMinute = [anAlarm minute];
                logMessage = [logMessage stringByAppendingFormat:@"\n Alarm minute: %d", alarmMinute];
                
                alarmTimestampForToday = [SRDHelper timestampForCurrentDayWithAlarmHour:alarmHour minute:alarmMinute];
                logMessage = [logMessage stringByAppendingFormat:@"\n Alarm timestamp: %@", [@(alarmTimestampForToday) stringValue]];

                
                if (alarmTimestampForToday > currentTimeStamp) {
                    
                    if ((alarmTimestampForToday - currentTimeStamp) <= SirendTimeIntervalForActivation) {
                        // We found an alarm within the specified trigger time!
                        shouldBoost = YES;
                        
                        logMessage = [logMessage stringByAppendingFormat:@"\n Found alarm to boost for!"];
                        
                        break;
                    }
                }
                
            }
            
            if (shouldBoost) {
                // If we are supposed to boost the volume, save the original system volume to disk
                float originalVolume = 0.0f;
                if (![[AVSystemController sharedAVSystemController] getVolume:&originalVolume forCategory:@"Ringtone"]) {
                    // If we cannot get the original volume from the system, set it to 0.5f
                    logMessage = [logMessage stringByAppendingFormat:@"\n Failed to retrieve original system volume"];
                    originalVolume = 0.5f;
                }
                
                logMessage = [logMessage stringByAppendingFormat:@"\n Original system volume: %f", originalVolume];
                
                // Now boost the volume for the alarm
                [[AVSystemController sharedAVSystemController] setVolumeTo:0.9f forCategory:@"Ringtone"];
                
                logMessage = [logMessage stringByAppendingFormat:@"\n Boosted!"];
                
                /*
                 * Important part: We need to restore the original volume after 5 minutes from the boost date.
                 * For this, we will sleep for 5 minutes till the alarm is over, after which, we will restore the original volume
                 *
                 * This can alternatively be achieved by changing the StartCalendarInterval key and re-submitting the daemon to launchd
                 */
                
                [logMessage writeToFile:SirendLogMessagePath atomically:NO encoding:NSUTF8StringEncoding error:nil];
                [NSThread sleepForTimeInterval:300];
                
                // Now restore the original volume
                [[AVSystemController sharedAVSystemController] setVolumeTo:originalVolume forCategory:@"Ringtone"];
                
                logMessage = [logMessage stringByAppendingFormat:@"\n Restored original volume. All done!"];
                
            } else {
                
                /*
                 * If there is no upcoming alarm, update the launchd plist to modify the StartCalendarInterval key such that
                 * the daemon launches 1 minute before the alarm fires.
                 * This probably means that the deamon was launched because the user added/edited an alarm
                 */
                
                logMessage = [logMessage stringByAppendingFormat:@"\n No upcoming alarms"];
                
                // First we will sort the alarms in an ascending order based on their hour and minute
                NSMutableArray *sortedAlarms = [alarms mutableCopy];
                NSSortDescriptor *hourSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"hour" ascending:YES];
                NSSortDescriptor *minuteSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"minute" ascending:YES];
                [sortedAlarms sortUsingDescriptors:@[hourSortDescriptor, minuteSortDescriptor]];
                
                // Now we will iterate through the alarms to determine which will be triggered first from now
                logMessage = [logMessage stringByAppendingFormat:@"\n Determining which alarm will fire next"];
                
                currentTimeStamp = [[NSDate date] timeIntervalSince1970];
                logMessage = [logMessage stringByAppendingFormat:@"\n Current timestamp: %@", [@(currentTimeStamp) stringValue]];
                
                for (SRDAlarm *anAlarm in sortedAlarms) {
                    alarmHour = [anAlarm hour];
                    logMessage = [logMessage stringByAppendingFormat:@"\n Alarm hour: %d", alarmHour];
                    
                    alarmMinute = [anAlarm minute];
                    logMessage = [logMessage stringByAppendingFormat:@"\n Alarm minute: %d", alarmMinute];
                    
                    alarmTimestampForToday = [SRDHelper timestampForCurrentDayWithAlarmHour:alarmHour minute:alarmMinute];
                    if (alarmTimestampForToday > currentTimeStamp || [sortedAlarms indexOfObject:anAlarm] == sortedAlarms.count - 1) {
                        
                        /*
                         * The daemon should launch 2 minutes before this alarm fires.
                         * The launchd plist will be edited to have this
                         */
                        
                        logMessage = [logMessage stringByAppendingFormat:@"\n Found alarm to boost for"];
                        
                        if (alarmMinute == 0) {
                            
                            alarmMinute = 58;
                            alarmHour = alarmHour - 1;
                            
                        } else {
                            alarmMinute = alarmMinute - 2;
                        }
                        
                        // Now write these to the launchd plist for the daemon
                        NSMutableDictionary *plistContent = [NSMutableDictionary dictionaryWithContentsOfFile:SirendLaunchdPlistPath];
                        NSDictionary *startCalendarInterval = @{@"Hour" : @(alarmHour), @"Minute" : @(alarmMinute)};
                        plistContent[@"StartCalendarInterval"] = startCalendarInterval;
                        [plistContent writeToFile:SirendLaunchdPlistPath atomically:NO];
                        
                        logMessage = [logMessage stringByAppendingFormat:@"\n Modified plist: %@", plistContent];
                        
                        /*
                         * We are almost done.
                         * But if we exit now, launchd will think we crashed, and hence will either respawn or blacklist us
                         * So we will wait for 10 seconds before we exit
                         */
                        
                        [NSThread sleepForTimeInterval:10];
                        
                        // Now we just need to resubmit ourself to launchd. Our reload script and NSTask will come in handy here
                        [NSTask launchedTaskWithLaunchPath:SirendReloadScriptPath arguments:@[]];
                        
                        break;
                        
                        
                    }
                }
                
                [sortedAlarms release];
            }

            
        } else {
            
            /*
             * If there are no alarms set, we will remove the StartAtCalendarTime key from the launchd plist
             * This will prevent launchd from launching us without an alarm set
             */
            
            logMessage = [logMessage stringByAppendingFormat:@"\n No alarms found"];
            NSMutableDictionary *plistContent = [NSMutableDictionary dictionaryWithContentsOfFile:SirendLaunchdPlistPath];
            id startAtCalendarTime = plistContent[@"StartAtCalendarTime"];
            
            if (![startAtCalendarTime isKindOfClass:[NSNull class]]) {
                
                [plistContent removeObjectForKey:@"StartAtCalendarTime"];
                [plistContent writeToFile:SirendLaunchdPlistPath atomically:YES];
                

                 // Now we will wait for 10 seconds so that launchd does not think we crashed
                [NSThread sleepForTimeInterval:10];
                
                // Finally, we will use our reload script to resubmit us to launchd
                [NSTask launchedTaskWithLaunchPath:SirendReloadScriptPath arguments:@[]];
                
            } else {
                
                // If there was no modifications in the plist, we will just wait for 10 seconds
                [NSThread sleepForTimeInterval:10];
                
            }
            
            
        }
        
        [alarms release];
        
        [logMessage writeToFile:SirendLogMessagePath atomically:NO encoding:NSUTF8StringEncoding error:nil];
    }
	return 0;
}

