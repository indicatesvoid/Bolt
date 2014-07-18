//
//  DragDropView.h
//  SDFlasher
//
//  Created by William Clark on 7/17/14.
//  Copyright (c) 2014 fuseproject. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DragDropView : NSView

@property (nonatomic, strong) IBOutlet NSView *view;
@property (nonatomic, assign) BOOL directoryMode;

-(void)postNotificationWithString:(NSString *)draggedPath;

@end
