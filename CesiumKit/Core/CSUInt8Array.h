//
//  CSUInt8Array.h
//  CesiumKit
//
//  Created by Ryan Walklin on 30/05/14.
//  Copyright (c) 2014 Test Toast. All rights reserved.
//

#import "CSArray.h"

@interface CSUInt8Array : CSArray

-(instancetype)initWithCapacity:(UInt64)capacity;
-(instancetype)initWithValues:(UInt8 *)values length:(UInt64)length;

-(UInt8)valueAtIndex:(UInt64)index;

@end
