//
//  AppDelegate.h
//  SDFlasher
//
//  Created by William Clark on 7/17/14.
//  Copyright (c) 2014 fuseproject. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    AuthorizationRef _authRef;
}
/** UI outlets **/
@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *SDBrowseBox;
@property (weak) IBOutlet NSTextField *imageBrowseBox;
@property (weak) IBOutlet NSButton *uploadBtn;
@property (weak) IBOutlet NSProgressIndicator *spinner;

/** UI actions **/
- (IBAction)browseForSDClicked:(id)sender;
- (IBAction)browseForImageClicked:(id)sender;
- (IBAction)uploadClicked:(id)sender;

/** NSNotification handlers **/
- (void)gotMountPoint:(NSNotification *)notification;
- (void)didUnmount:(NSNotification *)notification;
- (void)didUpload:(NSNotification *)notification;

/** Methods **/
- (void)flashSDCard;
- (BOOL) runProcessAsAdministrator:(NSString*)scriptPath
                     withArguments:(NSArray *)arguments
                            output:(NSString **)output
                  errorDescription:(NSString **)errorDescription;

/** Misc properties **/
@property (strong) NSString* mountPoint;
@property (strong) NSString* mountPointRaw;
@property (strong) NSString* imagePath;
@property (nonatomic, assign) BOOL uploadEnabled;
@end
