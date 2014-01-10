//
//  ADSCachingDoublyLinkedList.h
//  advanced-objective-c-data-structures.git
//
//  Created by Richard Stelling on 10/01/2014.
//  Copyright (c) 2014 Empirical Magic Ltd. All rights reserved.
//

#import "ADSDoublyLinkedList.h"

@interface ADSCachingDoublyLinkedList : ADSDoublyLinkedList

- (instancetype)initWithCacheWindow:(NSInteger)cacheWindow;

- (void)trimForward __attribute__((unavailable("Not implemented in ADSCachingDoublyLinkedList")));

- (void)trimBackward __attribute__((unavailable("Not implemented in ADSCachingDoublyLinkedList")));

- (void)trimAll __attribute__((unavailable("Not implemented in ADSCachingDoublyLinkedList")));

- (void)empty __attribute__((unavailable("Not implemented in ADSCachingDoublyLinkedList")));

@end
