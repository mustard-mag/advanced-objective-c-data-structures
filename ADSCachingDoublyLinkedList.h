//
//  ADSCachingDoublyLinkedList.h
//  advanced-objective-c-data-structures.git
//
//  Created by Richard Stelling on 10/01/2014.
//  Copyright (c) 2014 Empirical Magic Ltd. All rights reserved.
//

/*
 - Memory warnings?
 */

#import "ADSDoublyLinkedList.h"

@interface ADSCachingDoublyLinkedList : ADSDoublyLinkedList

- (instancetype)initWithCacheWindow:(NSInteger)cacheWindow;

- (BOOL)jump:(id)anObject __attribute__((unavailable("Not implemented in ADSCachingDoublyLinkedList")));

@end
