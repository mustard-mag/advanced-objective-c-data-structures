//
//  ADSBidirectionalMapTable.m
//  
//
//  Created by Richard Stelling on 09/12/2013.
//  Copyright (c) 2013 Empirical Magic Ltd. All rights reserved.
//

#import "ADSBidirectionalMapTable.h"

//Can only ever have a 1-to-1 mapping

@implementation ADSBidirectionalMapTable
{
    NSMapTable *upstream;
    NSMapTable *downstream;
}

- (NSString *)description
{
    NSMutableString *desc = [NSMutableString stringWithString:@"{\n"];
    
    for(id key in upstream)
    {
        id obj_up = [upstream objectForKey:key];
        id obj_down = [downstream objectForKey:obj_up];
        
        [desc appendFormat:@"%@ <=> %@ \n", obj_up, obj_down];
    }
    
    [desc appendFormat:@"}"];
    
    return desc;
}

- (instancetype)init
{
    self = [super init];
    
    if(self)
    {
        upstream = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory
                                         valueOptions:NSPointerFunctionsStrongMemory];
        
        downstream = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                           valueOptions:NSPointerFunctionsWeakMemory];
        
        if(!(upstream && downstream))
            self = nil; //we need both of these for Bidirectional Map Table to work
    }
    
    return self;
}

- (void)insertObject:(id)firstObj forMappedObject:(id)secondObject;
{
    @synchronized(self)
    {
        [self removeObject:firstObj];
        
        [upstream setObject:firstObj forKey:secondObject];
        [downstream setObject:secondObject forKey:firstObj];
        
        NSAssert(upstream.count == downstream.count, @"Internal consistency error.");
    }
}

- (id)objectForMappedObject:(id)anObject
{
    @synchronized(self)
    {
        id obj = [upstream objectForKey:anObject];
        
        if(!obj)
            obj = [downstream objectForKey:anObject];
        
        return obj;
    }
}

- (void)removeObject:(id)anObject
{
    @synchronized(self)
    {
        id obj = [upstream objectForKey:anObject];
        
        if(!obj)
        {
            obj = [downstream objectForKey:anObject];
            [upstream removeObjectForKey:obj];
            [downstream removeObjectForKey:anObject];
        }
        else
        {
            [upstream removeObjectForKey:anObject];
            [downstream removeObjectForKey:obj];
        }
        
        NSAssert(upstream.count == downstream.count, @"Internal consistency error.");
    }
}

- (NSUInteger)count
{
    NSAssert(upstream.count == downstream.count, @"Internal consistency error.");

    return upstream.count;
}

@end
