//
//  ADSDoublyLinkedList.h
//  advanced-objective-c-data-structures
//
//  Created by Richard Stelling on 09/01/2014.
//  Copyright (c) 2014 Empirical Magic Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const ADSInconsistencyException;

@interface ADSDoublyLinkedList : NSObject
{
    @protected
    id _internal;
}

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

///Remove all objects
- (void)empty;

///List is empty
- (BOOL)isEmpty;

@end

@interface ADSDoublyLinkedList (Extended)

/** Jump the index to anObject if it exists otherwise no changes are made
    @param anObject: the object to search for and move index to
    @return YES for successful jump, NO if anObject was not found
 */
- (BOOL)jump:(id)anObject;

///swaps objects and maintains the links. if secondObject is not already in the list firstObject is removed.
- (void)swapObject:(id)firstObject withObject:(id)secondObject;

///Convenience method to return the next object in the list and advance the index. If the index is at head this will return nil and not change index.
- (id)nextObject;

///Convenience method to return the previous object in the list and move the index back in the list. If the index is at tail this will return nil and not change index.
- (id)previousObject;

@end

/* ADSLink */

@interface ADSLink : NSObject

@property (strong, nonatomic) id forward; //if NULL we are the head
@property (strong, nonatomic) id back; //if NULL we are the tail

@end
