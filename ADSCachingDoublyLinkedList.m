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

@property (assign, nonatomic) NSUInteger objectHash;
@property (copy, nonatomic) NSString *data;

+ (instancetype)cacheWithObject:(id<NSCoding>)anObject;
- (id)object;

@end

@implementation ADSCache

- (void)dealloc
{
    NSLog(@"Deleating cache file: %@", self.data);
    
    [[NSFileManager defaultManager] removeItemAtPath:[[ADSCache cachePath] stringByAppendingPathComponent:self.data]
                                               error:nil];
}

+ (instancetype)cacheWithObject:(id<NSCoding, NSObject>)anObject
{
    ADSCache *me = [[ADSCache alloc] init];
    
    me.data = [[NSUUID UUID] UUIDString];
    me.objectHash = [anObject hash];
    
    if(![NSKeyedArchiver archiveRootObject:anObject toFile:[[self cachePath] stringByAppendingPathComponent:me.data]])
    {
        if([[NSFileManager defaultManager] createDirectoryAtPath:[self cachePath]
                                     withIntermediateDirectories:YES attributes:nil
                                                           error:nil])
        {
            [NSKeyedArchiver archiveRootObject:anObject toFile:[[self cachePath] stringByAppendingPathComponent:me.data]];
        }
        else
        {
            NSLog(@"Failed to write cache...");
        }
    }
    
    return me;
}

- (id)object
{
    id theObj = [NSKeyedUnarchiver unarchiveObjectWithFile:[[ADSCache cachePath] stringByAppendingPathComponent:self.data]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [[NSFileManager defaultManager] removeItemAtPath:[[ADSCache cachePath] stringByAppendingPathComponent:self.data]
                                                   error:nil];
    });
    
    return theObj;
}

+ (NSString *)cachePath
{
    NSURL *cacheUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    
    return [cacheUrl.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.cached-linkedlist", [[NSBundle mainBundle] bundleIdentifier]]];
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
    
    NSMutableDictionary *_serialisedObjectLookup;
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
        _serialisedObjectLookup = [NSMutableDictionary dictionaryWithCapacity:1];
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
    
    NSMutableString *desc = [NSMutableString stringWithFormat:@"[%@T|%lu%@]", ([self.tail isEqual:self.index]?@"*":@" "), (unsigned long)([self.tail isKindOfClass:[ADSCache class]]?[self.tail objectHash]:[self.tail hash]), ([self.tail isKindOfClass:[ADSCache class]]?@"~":@" ")];
    
    ADSLink *iterate = [_list objectForKey:self.tail];
    
    do
    {
        id current = iterate.forward;
        iterate = [_list objectForKey:current];
        
        if(iterate.forward)
            [desc appendFormat:@"[%@O|%lu%@]", ([current isEqual:self.index]?@"*":@" "), (unsigned long)([current isKindOfClass:[ADSCache class]]?[current objectHash]:[current hash]), ([current isKindOfClass:[ADSCache class]]?@"~":@" ")];
        
    } while (iterate.forward);
    
    [desc appendFormat:@"[%@H|%lu%@]", ([self.head isEqual:self.index]?@"*":@" "), (unsigned long)([self.head isKindOfClass:[ADSCache class]]?[self.head objectHash]:[self.head hash]), ([self.head isKindOfClass:[ADSCache class]]?@"~":@" ")];
        
    return desc;
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

- (id)mutateObjectToCache:(id)anObject
{
    ADSCache *cache = nil;
    
    /*if([anObject isEqual:self.head] || [anObject isEqual:self.tail])
    {
        return anObject; //do not cach head or tail
    }
    else*/
    if(![anObject isKindOfClass:[ADSCache class]])
    {
        //TODO: refactor into block
        cache = [ADSCache cacheWithObject:anObject];

        if(cache)
        {
            [_serialisedObjectLookup setObject:cache forKey:@(cache.objectHash)];
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
            [_serialisedObjectLookup removeObjectForKey:@([theObject hash])];
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

//- (id)head
//{
//    id realHead = [super head];
//    
//    if([realHead isKindOfClass:[ADSCache class]])
//    {
//        id uncachedHead = [self mutateCacheToObject:realHead];
//        _head = uncachedHead;
//    }
//    
//    NSAssert(![_head isKindOfClass:[ADSCache class]], @"ADSCache are not valid head object objects");
//
//    return _head;
//}
//
//- (id)tail
//{
//    id realTail = [super tail];
//    
//    if([realTail isKindOfClass:[ADSCache class]])
//    {
//        id uncachedTail = [self mutateCacheToObject:realTail];
//        _head = uncachedTail;
//    }
//    
//    NSAssert(![_tail isKindOfClass:[ADSCache class]], @"ADSCache are not valid head object objects");
//    
//    return _tail;
//}

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

- (id)nextObjectAfter:(id)anObject
{
    id nextObj = [super nextObjectAfter:anObject];
    
    if(!nextObj)
    {
        nextObj = [super nextObjectAfter:[_serialisedObjectLookup objectForKey:@([anObject hash])]];
    }
    
    if([nextObj isKindOfClass:[ADSCache class]])
    {
        nextObj = [self mutateCacheToObject:nextObj];
    }
    
    return nextObj;
}

- (id)previousObjectBefore:(id)anObject
{
    id prevObj = [super previousObjectBefore:anObject];
    
    if(!prevObj)
    {
        prevObj = [super previousObjectBefore:[_serialisedObjectLookup objectForKey:@([anObject hash])]];
    }
    
    if([prevObj isKindOfClass:[ADSCache class]])
    {
        prevObj = [self mutateCacheToObject:prevObj];
    }
    
    return prevObj;
}

- (void)add:(id)anObject before:(id)existingObject
{
    NSAssert(![existingObject isKindOfClass:[ADSCache class]], @"ADSCache are not valid objects");
    
    id existingObjectCache = [_serialisedObjectLookup objectForKey:@([existingObject hash])];
    
    [super add:anObject before:existingObjectCache?existingObjectCache:existingObject];
}

- (void)add:(id)anObject after:(id)existingObject
{
    NSAssert(![existingObject isKindOfClass:[ADSCache class]], @"ADSCache are not valid objects");

    id existingObjectCache = [_serialisedObjectLookup objectForKey:@([existingObject hash])];
    
    [super add:anObject after:existingObjectCache?existingObjectCache:existingObject];
}

@end
