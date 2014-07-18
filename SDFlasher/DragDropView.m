//
//  DragDropView.m
//  SDFlasher
//
//  Created by William Clark on 7/17/14.
//  Copyright (c) 2014 fuseproject. All rights reserved.
//

#import "DragDropView.h"

@implementation DragDropView

- (id)initWithFrame:(NSRect)frame
{
    [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    
    self.directoryMode = false;
    
    NSString* nibName = NSStringFromClass([self class]);
    self = [super initWithFrame:frame];
    if (self) {
        if ([[NSBundle mainBundle] loadNibNamed:nibName
                                          owner:self
                                topLevelObjects:nil]) {
            [self.view setFrame:[self bounds]];
            [self addSubview:self.view];
        }
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
//    [[NSColor colorWithWhite:0.85f alpha:1.0f] setFill];
//    NSRectFill(dirtyRect);
//    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    pboard = [sender draggingPasteboard];
    NSArray *list = [pboard propertyListForType:NSFilenamesPboardType];
    if ([list count] == 1) {
        BOOL isDirectory = NO;
        NSString *fileName = [list objectAtIndex:0];
        [[NSFileManager defaultManager] fileExistsAtPath:fileName
                                             isDirectory: &isDirectory];
        if (isDirectory || !self.directoryMode) {
            NSLog(@"Path: %@", fileName);
            [self postNotificationWithString:fileName];
        } else {
            NSLog(@"NOO");
        }
    }
    return YES;
}

-(void)postNotificationWithString:(NSString *)draggedPath {
    NSString *notificationName = @"FileDropped";
    NSString *key = @"PathString";
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:draggedPath forKey:key];
    
    NSLog(@"Posting notification with path: %@", draggedPath);
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self userInfo:dictionary];
}

@end
