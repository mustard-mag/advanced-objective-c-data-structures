//
//  ADSCachingDoublyLinkedList.m
//  advanced-objective-c-data-structures.git
//
//  Created by Richard Stelling on 10/01/2014.
//  Copyright (c) 2014 Empirical Magic Ltd. All rights reserved.
//

#import "ADSCachingDoublyLinkedList.h"

//Why 4? I did the science, and 4 was consistantly as fast as higher values with out the memory issues.
const NSInteger ADSDefaultCacheWindow = 4;

@interface ADSCache : NSObject <NSCopying>

@property (copy, nonatomic) NSString *data;

+ (instancetype)cacheWithObject:(id<NSCoding>)anObject;
- (id)object;

@end

@implementation ADSCache

+ (instancetype)cacheWithObject:(id<NSCoding>)anObject
{
    ADSCache *me = [[ADSCache alloc] init];
    
    me.data = [[NSUUID UUID] UUIDString];
    
    if(![NSKeyedArchiver archiveRootObject:anObject toFile:[[self cachePath] stringByAppendingPathComponent:me.data]])
    {
        NSLog(@"Failed to write cache...");
    }
    
    return me;
}

- (id)object
{
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[[ADSCache cachePath] stringByAppendingPathComponent:self.data]];
}

+ (NSString *)cachePath
{
    NSURL *cacheUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    
    return cacheUrl.path;
}

- (id)copyWithZone:(NSZone *)zone
{
    ADSCache *clone = [[ADSCache allocWithZone:zone] init];
    
    clone.data = self.data;
    
    return clone;
}

@end

@implementation ADSCachingDoublyLinkedList
{
    NSInteger _cacheWindow; //number of objects to retain in memory
    __weak NSMapTable *_list;
}

- (instancetype)init
{
    return [self initWithCacheWindow:ADSDefaultCacheWindow];
}

- (instancetype)initWithCacheWindow:(NSInteger)cacheWindow
{
    self = [super init];
    
    if(self)
    {
        _cacheWindow = cacheWindow;
        _list = _internal;
    }
    
    return self;
}

#pragma mark - Private

- (NSString *)description
{
    if([self isEmpty])
        return @"[   EMPTY LIST    ]";
    
    if([self.head isEqual:self.tail])
        return @"[ ONLY ONE OBJECT ]";
    
    NSMutableString *desc = [NSMutableString stringWithFormat:@"[%@T%@]", ([self.tail isEqual:self.index]?@"*":@" "), ([self.tail isKindOfClass:[ADSCache class]]?@"~":@" ")];
    
    ADSLink *iterate = [_list objectForKey:self.tail];
    
    do
    {
        id current = iterate.forward;
        iterate = [_list objectForKey:current];
        
        if(iterate.forward)
            [desc appendFormat:@"[%@O%@]", ([current isEqual:self.index]?@"*":@" "), ([current isKindOfClass:[ADSCache class]]?@"~":@" ")];
        
    } while (iterate.forward);
    
    [desc appendFormat:@"[%@H%@]", ([self.head isEqual:self.index]?@"*":@" "), ([self.head isKindOfClass:[ADSCache class]]?@"~":@" ")];
    
    //[desc appendFormat:@"\n\n[INDEX: %p]", self.index];
    
    return desc;
    
    
//    if([self isEmpty])
//        return @"[   EMPTY LIST    ]";
//    
//    NSMutableString *desc = [NSMutableString stringWithFormat:@"[TAIL:  %p%@%@]<->", self.tail, ([self.tail isEqual:self.index]?@" :INDEX":@""), ([self.tail isKindOfClass:[ADSCache class]]?@"*":@"")];
//    
//    ADSLink *iterate = [_list objectForKey:self.tail];
//    
//    do
//    {
//        id current = iterate.forward;
//        iterate = [_list objectForKey:current];
//        
//        if(iterate.forward)
//            [desc appendFormat:@"[%@%p%@]<->", ([current isEqual:self.index]?@"INDEX: ":@""), current, ([current isKindOfClass:[ADSCache class]]?@"*":@"")];
//        
//    } while (iterate.forward);
//    
//    [desc appendFormat:@"[%@%p%@  :HEAD]", ([self.head isEqual:self.index]?@"INDEX: ":@""), self.head, ([self.head isKindOfClass:[ADSCache class]]?@"*":@"")];
//    
//    [desc appendFormat:@"\n\n[INDEX: %p]", self.index];
//    
//    return desc;
}

//- (void)adjustCacheWindow
//{
//    id downstream = [self getObjectAt:-_cacheWindow fromObject:self.index];
//    
//    if(downstream) //cache all below this object
//    {
//        
//    }
//    
//    id upstream = [self getObjectAt:_cacheWindow fromObject:self.index];
//    
//    if(upstream) //cache all above this
//    {
//        if(![upstream isKindOfClass:[ADSCache class]])
//        {
//            //TODO: refactor into block
//            ADSCache *cache = [ADSCache cacheWithObject:upstream];
//            
//            if(cache)
//            {
//                ADSLink *cacheLink = [_list objectForKey:upstream];
//                [_list removeObjectForKey:upstream];
//                [_list setObject:cache forKey:cacheLink];
//            }
//        }
//    }
//}

- (id)getObjectAt:(NSInteger)jumps fromObject:(id)startObject
{
    id object = nil;
    ADSLink *objLink = [_list objectForKey:startObject];
    
    if(jumps > 0) //forward, towards head
    {
        for(NSInteger i = 0; i < jumps; i++)
        {
            object = objLink.forward;
            objLink = [_list objectForKey:object];
            
            if(!objLink.forward)
                break;
        }
    }
    else if (jumps < 0) //backwards, towards tail
    {
        for(NSInteger i = 0; i < -jumps; i++)
        {
            object = objLink.back;
            objLink = [_list objectForKey:object];
            
            if(!objLink.back)
                break;
        }
    }
    else //if jumps is zero
    {
        object = startObject;
    }
    
    return object;
}

- (NSInteger)distanceFromObject:(id)firstObject toObject:(id)secondObject
{
    if([firstObject isEqual:secondObject])
        return 0;
    
    NSInteger count = 0;
    ADSLink *iterate = [_list objectForKey:firstObject];
    
    do
    {
        id current = iterate.forward;
        iterate = [_list objectForKey:current];
        
        count++;
        
        if([current isEqual:secondObject])
        {
            break;
        }
        else if(!iterate.forward)
        {
            count = NSIntegerMax;
        }
        
    } while(iterate.forward);
    
    if(count == NSIntegerMax)
    {
        ADSLink *iterate = [_list objectForKey:secondObject];
        count = 0;
        
        do
        {
            id current = iterate.forward;
            iterate = [_list objectForKey:current];
            
            count--;
            
            if([current isEqual:firstObject])
            {
                break;
            }
            else if(!iterate.forward)
            {
                count = NSIntegerMax;
            }
            
        } while(iterate.forward);
    }
    
    return count;
}

- (ADSCache *)mutateObjectToCache:(id)anObject
{
    ADSCache *cache = nil;
    
    if(![anObject isKindOfClass:[ADSCache class]])
    {
        //TODO: refactor into block
        cache = [ADSCache cacheWithObject:anObject];

        if(cache)
        {
            [self swapObject:anObject withObject:cache];
        }
    }
    
    return cache;
}

- (id)mutateCacheToObject:(ADSCache *)cacheObject
{
    id theObject = nil;
    
    if([cacheObject isKindOfClass:[ADSCache class]])
    {
        theObject = [cacheObject object];
        
        if(theObject)
        {
            [self swapObject:cacheObject withObject:theObject];
        }
    }
    
    return theObject;
}

//This returns nil if it hits the head or tail before distance is covered
- (id)objectAtDistance:(NSInteger)distance fromObject:(id)startObject
{
    if(distance == 0)
        return startObject;
    
    id returnObj = nil;
    ADSLink *currentLink = [_list objectForKey:startObject];
    
    for(NSInteger i = 0; i < (NSInteger)abs(distance); i++)
    {
        if(distance > 0) //fwd
        {
            if(currentLink.forward)
            {
                returnObj = currentLink.forward;
            }
            else
            {
                returnObj = nil;
                break; //hit head
            }
                
        }
        else if(distance < 0) //bak
        {
            if(currentLink.back)
            {
                returnObj = currentLink.back;
            }
            else
            {
                returnObj = nil;
                break; //hit tail
            }
        }
        
        currentLink = [_list objectForKey:returnObj];
    }
    
    return returnObj;
}

#pragma mark - Overridden

- (void)add:(id)anObject
{
    NSAssert([anObject conformsToProtocol:@protocol(NSCoding)], @"Object cannot be cached, in production code this will be ignored.");
    
    if([anObject conformsToProtocol:@protocol(NSCoding)])
    {
        //TODO: check distance between index and head and cach object befoe adding to list
        
        [super add:anObject];
        
        if([self distanceFromObject:self.index toObject:anObject] > _cacheWindow)
        {
            //NSLog(@"*** Distance %d ***", );
            [self mutateObjectToCache:anObject];
        }
    }
    else
    {
        NSLog(@"[ERROR: %s] Object not added to list.", __PRETTY_FUNCTION__);
    }
    
    NSAssert(![self.index isKindOfClass:[ADSCache class]], @"Index cannot be of type ADSCache");
}

- (void)remove
{
    [super remove];
    
    NSAssert(![self.index isKindOfClass:[ADSCache class]], @"Index cannot be of type ADSCache");
}

- (void)forward
{
    [super forward];
    
    //Hop backwards _cacheWindow times and cache objects if required
    id backObj = [self objectAtDistance:-(_cacheWindow + 1) fromObject:self.index];
    BOOL loopBack = ![self.index isEqual:self.tail]; //only try and cache backwards if we're not the tail
    
    while(backObj && loopBack)
    {
        if(![backObj isKindOfClass:[ADSCache class]])
        {
            ADSCache *cache = [self mutateObjectToCache:backObj];
            
            backObj = [self objectAtDistance:-1 fromObject:cache];
        }
        else
        {
            loopBack = NO;
        }
    }
    
    //Hop forward _cacheWindow times and un-cache objects if required
    id forwardObj = [self objectAtDistance:_cacheWindow fromObject:self.index];
    BOOL loopForward = ![self.index isEqual:self.head]; //only try and cache forwards if we're not the head
    
    while(loopForward && forwardObj)
    {
        if([forwardObj isKindOfClass:[ADSCache class]])
        {
            id obj = [self mutateCacheToObject:forwardObj];
            
            forwardObj = [self objectAtDistance:-1 fromObject:obj];
        }
        else
        {
            loopForward = NO;
        }
    }
    
    NSAssert(![self.index isKindOfClass:[ADSCache class]], @"Index cannot be of type ADSCache");
}

- (void)backward
{
    [super backward];
    
    //Hop backwards _cacheWindow times and cache objects if required
    id forwardObj = [self objectAtDistance:_cacheWindow+1 fromObject:self.index];
    BOOL loopForward = ![self.index isEqual:self.head]; //only try and cache forwards if we're not the head
    
    while(loopForward && forwardObj)
    {
        if(![forwardObj isKindOfClass:[ADSCache class]])
        {
            ADSCache *cache = [self mutateObjectToCache:forwardObj];

            forwardObj = [self objectAtDistance:1 fromObject:cache];
        }
        else
        {
            loopForward = NO;
        }
    }
    
    //Hop backwards _cacheWindow times and cache objects if required
    id backObj = [self objectAtDistance:-_cacheWindow fromObject:self.index];
    BOOL loopBack = ![self.index isEqual:self.tail]; //only try and cache backwards if we're not the tail
    
    while(backObj && loopBack)
    {
        if([backObj isKindOfClass:[ADSCache class]])
        {
            id obj = [self mutateCacheToObject:backObj];

            backObj = [self objectAtDistance:1 fromObject:obj];
        }
        else
        {
            loopBack = NO;
        }
    }
    
//    id backObj = [self objectAtDistance:-_cacheWindow fromObject:self.index];
//    BOOL loopBack = ![self.index isEqual:self.tail]; //only try and cache backwards if we're not the tail
//    
//    while(loopBack)
//    {
//        if(backObj && ![backObj isKindOfClass:[ADSCache class]])
//        {
//            id obj = [self mutateCacheToObject:backObj];
//            
//            backObj = [self objectAtDistance:-1 fromObject:obj];
//        }
//        else
//        {
//            loopBack = NO;
//        }
//    }
//    
//    //Hop forward _cacheWindow times and un-cache objects if required
//    id forwardObj = [self objectAtDistance:_cacheWindow fromObject:self.index];
//    BOOL loopForward = ![self.index isEqual:self.head]; //only try and cache forwards if we're not the head
//    
//    while(loopForward && forwardObj)
//    {
//        if([forwardObj isKindOfClass:[ADSCache class]])
//        {
//            ADSCache *cache = [self mutateObjectToCache:forwardObj];
//            
//            forwardObj = [self objectAtDistance:-1 fromObject:cache];
//        }
//        else
//        {
//            loopForward = NO;
//        }
//    }
    
    NSAssert(![self.index isKindOfClass:[ADSCache class]], @"Index cannot be of type ADSCache");
}

@end
