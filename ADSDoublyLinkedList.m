//
//  ADSDoublyLinkedList.m
//  advanced-objective-c-data-structures
//
//  Created by Richard Stelling on 09/01/2014.
//  Copyright (c) 2014 Empirical Magic Ltd. All rights reserved.
//

#import "ADSDoublyLinkedList.h"

NSString *const ADSInconsistencyException = @"com.ads.exception.inconsistency";

@interface ADSLink : NSObject /*<NSCopying>*/

@property (strong, nonatomic) id forward; //if NULL we are the head
@property (strong, nonatomic) id back; //if NULL we are the tail

+ (instancetype)linkForward:(id)myForward backward:(id)myBackward;

@end

@implementation ADSLink

- (void)dealloc
{
    self.forward = nil;
    self.back = nil;
}

//- (id)copyWithZone:(NSZone *)zone
//{
//    return [ADSLink linkForward:self.forward backward:self.back];
//}

+ (instancetype)linkForward:(id)myForward backward:(id)myBackward
{
    ADSLink *me = [[ADSLink alloc] init];
    
    me.forward = myForward;
    me.back = myBackward;
    
    return me;
}

@end

@implementation ADSDoublyLinkedList
{
    NSMapTable *_list;
}

- (instancetype)init
{
    self = [super init];
    
    if(self)
    {
        _list = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                      valueOptions:NSPointerFunctionsStrongMemory/*weak?*/];
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
    
    [desc appendFormat:@"[%@%p  :HEAD]", ([self.head isEqual:self.index]?@"INDEX: ":@""), self.head];
    
    [desc appendFormat:@"\n\n[INDEX: %p]", self.index];
    
    return desc;
}

- (BOOL)isEmpty
{
    BOOL success = YES;
    
    if(self.head && self.index && self.tail)
    {
        success = NO;
    }
    else if(!self.head && !self.index && !self.tail)
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
    ADSLink *headLink = [_list objectForKey:self.head];
    
    if(headLink)
    {
        headLink.forward = anObject; //set new object as the forward link
        
        ADSLink *objectLink = [ADSLink linkForward:NULL backward:self.head];
        
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
    return NO;
}

@end
