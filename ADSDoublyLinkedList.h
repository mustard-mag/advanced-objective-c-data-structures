//
//  ADSDoublyLinkedList.h
//  advanced-objective-c-data-structures
//
//  Created by Richard Stelling on 09/01/2014.
//  Copyright (c) 2014 Empirical Magic Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADSDoublyLinkedList : NSObject

/* Access Nodes */

///Object at the very base of the list
@property (readonly, nonatomic) id tail;

///Object at the head of the list
@property (readonly, nonatomic) id head;

///Object currently pointed at.
@property (readonly, nonatomic) id index;

/* Taverse List */

///Move forward in list
- (void)forward;

///Move backward in list
- (void)backward;

/* Adding/Removing Nodes */

///Add an object to the list. This object will be connected to head.
- (void)add:(id)anObject;

///Remove the current object at index and connect (index - 1) to (index + 1)
- (void)remove;

///Remove all nodes forward of index, index will become head
- (void)trimForward;

///Remove all nodes behind index, index will become tail
- (void)trimBackward;

///Trim both forwards and backwards leaving only the object at `index` e.g. NULL<->index<->NULL
- (void)trimAll;

///Remov all objects
- (void)empty;

@end
