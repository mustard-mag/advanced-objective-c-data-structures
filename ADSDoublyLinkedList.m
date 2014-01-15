//
//  ADSDoublyLinkedList.m
//  advanced-objective-c-data-structures
//
//  Created by Richard Stelling on 09/01/2014.
//  Copyright (c) 2014 Empirical Magic Ltd. All rights reserved.
//

#import "ADSDoublyLinkedList.h"

NSString *const ADSInconsistencyException = @"com.ads.exception.inconsistency";

@interface ADSLink ()

+ (instancetype)linkForward:(id)myForward backward:(id)myBackward;

@end

@implementation ADSLink

- (void)dealloc
{
    NSLog(@"Link is being removed...");
    
    self.forward = nil;
    self.back = nil;
}

+ (instancetype)linkForward:(id)myForward backward:(id)myBackward
{
    ADSLink *me = [[ADSLink alloc] init];
    
    me.forward = myForward;
    me.back = myBackward;
    
    return me;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"\t\t◀[%@]---[%@]▶", self.back, self.forward];
}

@end

@implementation ADSDoublyLinkedList
{
    __weak NSMapTable *_list;
    NSMutableSet *_listContents;
}

- (void)dealloc
{
    [_list removeAllObjects];
    _list = nil;
    _internal = nil;
    
    [_listContents removeAllObjects];
    _listContents = nil;
    
    NSLog(@"BUY, BUY!");
}

- (instancetype)init
{
    self = [super init];
    
    if(self)
    {
        _listContents = [NSMutableSet setWithCapacity:1];
        
        _internal = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                          valueOptions:NSPointerFunctionsStrongMemory/*weak?*/];
        _list = _internal;
    }
    
    return self;
}

#pragma mark - Private

- (NSString *)description
{
    if([self isEmpty])
        return @"[   EMPTY LIST    ]";
    
    NSMutableString *desc = [NSMutableString stringWithFormat:@"[TAIL:  %p%@]<->", self.tail, ([self.tail isEqual:self.index]?@" :INDEX":@"")];

    ADSLink *iterate = [_list objectForKey:self.tail];
    
    do
    {
        id current = iterate.forward;
        iterate = [_list objectForKey:current];
        
        if(iterate.forward)
            [desc appendFormat:@"[%@%p]<->", ([current isEqual:self.index]?@"INDEX: ":@""), current];
        
    } while (iterate.forward);
    
    [desc appendFormat:@"[%@%p  :HEAD]", ([_head isEqual:self.index]?@"INDEX: ":@""), _head];
    
    [desc appendFormat:@"\n\n[INDEX: %p]", self.index];
    
    return desc;
}

- (BOOL)isEmpty
{
    BOOL success = YES;
    
    if(_head && self.index && _tail)
    {
        success = NO;
    }
    else if(!_head && !self.index && !_tail)
    {
        success = YES;
    }
    else
    {
        @throw [NSException exceptionWithName:ADSInconsistencyException reason:@"Internal Inconsistency" userInfo:nil];
    }
    
    return success;
}

#pragma mark - Taverse List

- (void)forward
{
    ADSLink *indexLink = [_list objectForKey:self.index];
    
    if(indexLink)
    {
        if(indexLink.forward)
            _index = indexLink.forward;
    }
    //else error
}

///Move backward in list
- (void)backward
{
    ADSLink *indexLink = [_list objectForKey:self.index];
    
    if(indexLink)
    {
        if(indexLink.back)
            _index = indexLink.back;
    }
    //else error
}

#pragma mark - Adding/Removing Nodes

///Add an object to the list. This object will be connected to head.
- (void)add:(id)anObject
{
    NSAssert(![_listContents containsObject:anObject], @"Linked lists can only contain one copy of each object");
    
    if([_listContents containsObject:anObject])
        return;
    
    [_listContents addObject:anObject];
    
    ADSLink *headLink = [_list objectForKey:_head];
    
    if(headLink)
    {
        headLink.forward = anObject; //set new object as the forward link
        
        ADSLink *objectLink = [ADSLink linkForward:NULL backward:_head];
        
        [_list setObject:objectLink forKey:anObject];
        
        _head = anObject;
    }
    else if([self isEmpty]) //this must be the first time we
    {
        ADSLink *objectLink = [ADSLink linkForward:NULL backward:NULL];
        [_list setObject:objectLink forKey:anObject];
        
        _head = _index = _tail = anObject;
    }
    else
    {
        @throw [NSException exceptionWithName:ADSInconsistencyException reason:@"Internal Inconsistency" userInfo:nil];
    }
}

///Remove the current object at index and connect (index - 1) to (index + 1)
- (void)remove
{
    id nodeToRemove = self.index;
    ADSLink *indexLink = [_list objectForKey:nodeToRemove];
    
    ADSLink *forwardLink = [_list objectForKey:indexLink.forward];
    ADSLink *backLink = [_list objectForKey:indexLink.back];
    
    if(!forwardLink && !backLink) //there is only one node, just call empty
    {
        [self empty];
    }
    else if(!backLink) //removing the tail
    {
        NSAssert([self.index isEqual:self.tail], @"Internal state in inconsistent");
        
        forwardLink.back = nil;
        _tail = _index = indexLink.forward;
        
    }
    else if(!forwardLink) //removing the head
    {
        NSAssert([self.index isEqual:self.head], @"Internal state in inconsistent");
        
        backLink.forward = nil;
        _head = _index = indexLink.back;
        
    }
    else //removing normal node
    {
        backLink.forward = indexLink.forward;
        forwardLink.back = indexLink.back;
        
        _index = indexLink.forward;
    }
    
    NSLog(@"REMOVING: %p", nodeToRemove);
    [_listContents removeObject:nodeToRemove];
    [_list removeObjectForKey:nodeToRemove];
}

///Remove all nodes forward of index, index will become head
- (void)trimForward
{
    if([self.index isEqual:self.head])
        return;
    
    ADSLink *indexLink = [_list objectForKey:self.index];
    id trimFromObject = indexLink.forward;
    
    while(trimFromObject)
    {
        ADSLink *objLink = [_list objectForKey:trimFromObject];
        
        NSLog(@"REMOVING: %p", trimFromObject);
        [_listContents removeObject:trimFromObject];
        [_list removeObjectForKey:trimFromObject];
        
        trimFromObject = objLink.forward;
    }
    
    indexLink.forward = nil;
    _head = _index;
}

///Remove all nodes behind index, index will become tail
- (void)trimBackward
{
    if([self.index isEqual:self.tail])
        return;
    
    ADSLink *indexLink = [_list objectForKey:self.index];
    id trimFromObject = indexLink.back;
    
    while(trimFromObject)
    {
        ADSLink *objLink = [_list objectForKey:trimFromObject];
        
        NSLog(@"REMOVING: %p", trimFromObject);
        [_listContents removeObject:trimFromObject];
        [_list removeObjectForKey:trimFromObject];
        
        trimFromObject = objLink.back;
    }
    
    indexLink.back = nil;
    _tail = _index;
}

///Trim both forwards and backwards leaving only the object at `index` e.g. NULL<->index<->NULL
- (void)trimAll
{
    [self trimForward];
    [self trimBackward];
}

///Remov all objects
- (void)empty
{
    [_list removeAllObjects];
    [_listContents removeAllObjects];
    _index = _tail = _head = nil;
}

@end

@implementation ADSDoublyLinkedList (Extended)

/** Jump the index to anObject if it exists otherwise no changes are made
 @param anObject: the object to search for and move index to
 @return YES for successful jump, NO if anObject was not found
 */
- (BOOL)jump:(id)anObject
{
    BOOL success = NO;
    
    ADSLink *indexLink = [_list objectForKey:anObject];
    
    if(indexLink)
    {
        success = YES;
        _index = anObject;
    }
    
    return success;
}

- (void)jumpToHead
{
    [self jump:self.head];
}

- (void)jumpToTail
{
    [self jump:self.tail];
}

- (void)swapObject:(id)firstObject withObject:(id)secondObject
{
    ADSLink *firstLink = [_list objectForKey:firstObject];
    ADSLink *secondLink = [_list objectForKey:secondObject];
    
    if(firstLink && secondLink)
    {
        [_list removeObjectForKey:firstObject];
        [_list removeObjectForKey:secondObject];
        
        { //Update the links for the newly added secondObject
            
            ADSLink *backLink = [_list objectForKey:firstLink.back];
            backLink.forward = secondObject;
            
            ADSLink *forwardLink = [_list objectForKey:firstLink.forward];
            forwardLink.back = secondObject;
            
            if(!forwardLink)
                _head = secondObject;
            
            if(!backLink)
                _tail = secondObject;
            
            [_list setObject:firstLink forKey:secondObject];
        }
        
        { //Update the links for the newly added firstObject
            
            ADSLink *backLink = [_list objectForKey:secondLink.back];
            backLink.forward = firstObject;
        
            ADSLink *forwardLink = [_list objectForKey:secondLink.forward];
            forwardLink.back = firstObject;
            
            if(!forwardLink)
                _head = firstObject;
            
            if(!backLink)
                _tail = firstObject;
            
            [_list setObject:secondLink forKey:firstObject];
        }
    }
    else if(firstLink) //TODO: refactor these with less code dupe.
    {
        [_list removeObjectForKey:firstObject];
        
        { //Update the links for the newly added secondObject
            
            ADSLink *backLink = [_list objectForKey:firstLink.back];
            backLink.forward = secondObject;
            
            ADSLink *forwardLink = [_list objectForKey:firstLink.forward];
            forwardLink.back = secondObject;
            
            if(!forwardLink)
                _head = secondObject;
            
            if(!backLink)
                _tail = secondObject;
            
            [_list setObject:firstLink forKey:secondObject];
        }
    }
    else if(secondLink)
    {
        [_list removeObjectForKey:secondObject];
        
        { //Update the links for the newly added firstObject
            
            ADSLink *backLink = [_list objectForKey:secondLink.back];
            backLink.forward = firstObject;
            
            ADSLink *forwardLink = [_list objectForKey:secondLink.forward];
            forwardLink.back = firstObject;
            
            if(!forwardLink)
                _head = firstObject;
            
            if(!backLink)
                _tail = firstObject;
            
            [_list setObject:secondLink forKey:firstObject];
        }
    }
    //else if(!(firstLink && secondLink)) //neither object is in list
}

- (id)nextObject
{
    @synchronized(self)
    {
        if([self.index isEqual:self.head])
        {
            return nil;
        }
        else
        {
            [self forward];
            return self.index;
        }
    }
}

- (id)previousObject
{
    @synchronized(self)
    {
        if([self.index isEqual:self.tail])
        {
            return nil;
        }
        else
        {
            [self backward];
            return self.index;
        }
    }
}

- (id)nextObjectAfter:(id)anObject
{
    ADSLink *objLink = [_list objectForKey:anObject];
    
    return objLink.forward;
}

- (id)previousObjectBefore:(id)anObject
{    
    ADSLink *objLink = [_list objectForKey:anObject];
    
    return objLink.back;
}

- (void)add:(id)anObject before:(id)existingObject
{
    NSAssert(![_listContents containsObject:anObject], @"Linked lists can only contain one copy of each object");
    
    if([_listContents containsObject:anObject])
        return;
    
    [_listContents addObject:anObject];
    
    if([existingObject isEqual:self.tail])
    {
        [self addAtTail:anObject];
    }
    else
    {
        ADSLink *existingLink = [_list objectForKey:existingObject];
        id backObject = existingLink.back;
        ADSLink *beforeLink = [_list objectForKey:backObject];
        
        NSAssert((existingLink && beforeLink), @"List is corrupt!");
        
        existingLink.back = anObject;
        beforeLink.forward = anObject;
        
        ADSLink *newLink = [ADSLink linkForward:existingObject backward:backObject];
        [_list setObject:newLink forKey:anObject];
    }
}

- (void)add:(id)anObject after:(id)existingObject
{
    NSAssert(![_listContents containsObject:anObject], @"Linked lists can only contain one copy of each object");
    
    if([existingObject isEqual:self.head])
    {
        [self add:anObject]; //this will add object to _listContents
    }
    else
    {
        if([_listContents containsObject:anObject])
            return;
        
        [_listContents addObject:anObject];
        
        ADSLink *existingLink = [_list objectForKey:existingObject];
        id forwardObject = existingLink.forward;
        ADSLink *afterLink = [_list objectForKey:forwardObject];
        
        NSAssert((existingLink && afterLink), @"List is corrupt!");
        
        existingLink.forward = anObject;
        afterLink.back = anObject;
        
        ADSLink *newLink = [ADSLink linkForward:forwardObject backward:existingObject];
        [_list setObject:newLink forKey:anObject];
    }
}

- (void)addAtTail:(id)anObject
{
    NSAssert(![_listContents containsObject:anObject], @"Linked lists can only contain one copy of each object");
    
    if([_listContents containsObject:anObject])
        return;
    
    [_listContents addObject:anObject];
    
    ADSLink *tailLink = [_list objectForKey:_tail];
    
    NSAssert(!tailLink.back, @"Tail is corrupt!");
    
    ADSLink *newLink = [ADSLink linkForward:self.tail backward:nil];
    
    tailLink.back = anObject;
    _tail = anObject;
    
    [_list setObject:newLink forKey:anObject];
}

@end
