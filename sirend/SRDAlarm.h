//
//  SRDAlarm.h
//  sirend
//
//  Created by Harshad on 15/09/2013.
//
//

#import <Foundation/Foundation.h>

@interface SRDAlarm : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (readonly, nonatomic) NSUInteger hour;
@property (readonly, nonatomic) NSUInteger minute;

@end
