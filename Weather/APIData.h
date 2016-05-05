//
//  apiData.h
//  Weather
//
//  Created by Tom Williamson on 5/5/16.
//  Copyright © 2016 Tom Williamson. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol APIDataDelegate <NSObject>

@required
-(void)gotAPIData;

@end

@interface APIData : NSObject

@property (strong, nonatomic) id<APIDataDelegate> delegate;

@property (copy, nonatomic)   NSString*     request;
@property (strong, nonatomic) NSMutableData* rawData;
@property (strong, nonatomic) NSDictionary  *dictionary;
@property (copy, nonatomic)   NSString      *errorText;

-(void)startRequest:(NSString*)req delegate:(id<APIDataDelegate>) delegate;

@end
