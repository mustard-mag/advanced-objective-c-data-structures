//
//  ADSBidirectionalMapTable.h
//
//
//  Created by Richard Stelling on 09/12/2013.
//  Copyright (c) 2013 Empirical Magic Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADSBidirectionalMapTable : NSObject

///Inserts mapped object. This will remove any previous mappings and updates them
- (void)insertObject:(id)firstObj forMappedObject:(id)secondObject;

///Returns the mapped object assocated with anObject
- (id)objectForMappedObject:(id)anObject;

///Remove this object and corrisponding mapped object
- (void)removeObject:(id)anObject;

///Count number of objects mapped (total objects is x2 this)
- (NSUInteger)count;

@end
