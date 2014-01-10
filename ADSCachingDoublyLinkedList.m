//
//  ADSCachingDoublyLinkedList.m
//  advanced-objective-c-data-structures.git
//
//  Created by Richard Stelling on 10/01/2014.
//  Copyright (c) 2014 Empirical Magic Ltd. All rights reserved.
//

#import "ADSCachingDoublyLinkedList.h"

const NSInteger ADSDefaultCacheWindow = 2;

@interface ADSCache : NSObject <NSCopying>

@property (copy, nonatomic) NSString *data;

+ (instancetype)cacheWithObject:(id<NSCoding>)anObject;

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
    
    NSMutableString *desc = [NSMutableString stringWithFormat:@"[TAIL:  %p%@%@]<->", self.tail, ([self.tail isEqual:self.index]?@" :INDEX":@""), ([self.tail isKindOfClass:[ADSCache class]]?@"*":@"")];
    
    ADSLink *iterate = [_list objectForKey:self.tail];
    
    do
    {
        id current = iterate.forward;
        iterate = [_list objectForKey:current];
        
        if(iterate.forward)
            [desc appendFormat:@"[%@%p%@]<->", ([current isEqual:self.index]?@"INDEX: ":@""), current, ([current isKindOfClass:[ADSCache class]]?@"*":@"")];
        
    } while (iterate.forward);
    
    [desc appendFormat:@"[%@%p%@  :HEAD]", ([self.head isEqual:self.index]?@"INDEX: ":@""), self.head, ([self.head isKindOfClass:[ADSCache class]]?@"*":@"")];
    
    [desc appendFormat:@"\n\n[INDEX: %p]", self.index];
    
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

- (void)mutateObjectToCache:(id)anObject
{
    if(![anObject isKindOfClass:[ADSCache class]])
    {
        //TODO: refactor into block
        ADSCache *cache = [ADSCache cacheWithObject:anObject];

        if(cache)
        {
            ADSLink *cacheLink = [_list objectForKey:anObject];
            [_list removeObjectForKey:anObject];
            [_list setObject:cache forKey:cacheLink];
            
            if(cacheLink.forward)
            {
                ADSLink *forwardLink = [_list objectForKey:cacheLink.forward];
                forwardLink.back = cache;
            }
            else //new head
            {
                [self swapObject: withObject:]
            }
            
            ADSLink *backLink = [_list objectForKey:cacheLink.back];
            backLink.forward = cache;
        }
    }
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
}

- (void)remove
{
    [super remove];
}

- (void)forward
{
    [super forward];
}

- (void)backward
{
    [super backward];
}

@end
