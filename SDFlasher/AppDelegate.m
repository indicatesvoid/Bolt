//
//  AppDelegate.m
//  SDFlasher
//
//  Created by William Clark on 7/17/14.
//  Copyright (c) 2014 fuseproject. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self.uploadBtn setEnabled:NO];
    [self.spinner setDisplayedWhenStopped:NO];
    
    // set up event listeners
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didDropSDPath:)
     name:@"FileDropped"
     object:self.SDDragDropView];
    
    [self.SDDragDropView setDirectoryMode:true];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didDropImagePath:)
     name:@"FileDropped"
     object:self.imageDragDropView];
}

- (IBAction)browseForSDClicked:(id)sender {
    // notes:
    // http://cyborgdino.com/2012/02/nsopenpanel-displaying-a-file-open-dialog-in-os-x-10-7/
    
    // Loop counter.
    int i;
    
    // Create a File Open Dialog class.
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    
    // Enable options in the dialog.
    [openDlg setCanChooseFiles:NO];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setCanChooseDirectories:YES];
    
    // Display the dialog box.  If the OK pressed,
    // process the files.
    if ( [openDlg runModal] == NSOKButton ) {
        
        // Gets list of all files selected
        NSArray *files = [openDlg URLs];
        
        // check to see if we need to enable the upload button
        self.uploadEnabled = (self.imagePath != nil) ? TRUE : FALSE;
        [self.uploadBtn setEnabled:self.uploadEnabled];
        
        // Loop through the files and process them.
        for( i = 0; i < [files count]; i++ ) {
            // get mount point from path
            // adapted from http://stackoverflow.com/questions/2167558/give-the-mount-point-of-a-path
            // df "/Volumes/NO NAME" | tail -1 | awk '{ print $1 }'
            [self getMountPointForPath:[[files objectAtIndex:i] path]];
        }
    }
}

- (IBAction)browseForImageClicked:(id)sender {
    // Loop counter.
    int i;
    
    // Create a File Open Dialog class.
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    
    // Set array of file types
    NSArray *fileTypesArray;
    fileTypesArray = [NSArray arrayWithObjects:@"gz", @"tar.giz", nil];
    
    // Enable options in the dialog.
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowedFileTypes:fileTypesArray];
    [openDlg setAllowsMultipleSelection:NO];
    
    // Display the dialog box.  If the OK pressed,
    // process the files.
    if ( [openDlg runModal] == NSOKButton ) {
        
        // check to see if we need to enable the upload button
        self.uploadEnabled = (self.mountPoint != nil) ? TRUE : FALSE;
        [self.uploadBtn setEnabled:self.uploadEnabled];
        
        // Gets list of all files selected
        NSArray *files = [openDlg URLs];
        
        // Loop through the files and process them.
        for( i = 0; i < [files count]; i++ ) {
            self.imagePath = [[NSString alloc] initWithString:[[files objectAtIndex:i] path]];
            [self.imageBrowseBox setStringValue:self.imagePath];
            NSLog(@"File path: %@", self.imagePath);
        }
        
    }
}

- (IBAction)uploadClicked:(id)sender {
    if(self.imagePath == nil || self.mountPoint == nil) return;
    [self.spinner startAnimation:self];
    [self.uploadBtn setEnabled:NO];
    [self flashSDCard];
    [self.uploadBtn setEnabled:YES];
}

//--------------------------------------------------------------
// Notification handlers
//--------------------------------------------------------------

- (void)didDropImagePath:(NSNotification *)notification {
    NSLog(@"Dropped image path");
    // check to see if we need to enable the upload button
    self.uploadEnabled = (self.mountPoint != nil) ? TRUE : FALSE;
    [self.uploadBtn setEnabled:self.uploadEnabled];
    
    NSString *path = [[notification userInfo] objectForKey:@"PathString"];
    self.imagePath = path;
    [self.imageBrowseBox setStringValue:self.imagePath];
    NSLog(@"File path: %@", path);
}

- (void)didDropSDPath:(NSNotification *)notification {
    NSLog(@"Dropped SD path");
    // check to see if we need to enable the upload button
    self.uploadEnabled = (self.imagePath != nil) ? TRUE : FALSE;
    [self.uploadBtn setEnabled:self.uploadEnabled];
    
    NSString *path = [[notification userInfo] objectForKey:@"PathString"];
    [self getMountPointForPath:path];
//    [self.SDBrowseBox setStringValue:path];
    NSLog(@"File path: %@", path);
}
     
- (void)gotMountPoint:(NSNotification *)notification {
    NSFileHandle *fh = [notification object];
    NSData *data = [fh availableData];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    
    [self processMountPoint:str];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object:[notification object]];
}

- (void)didUnmount:(NSNotification *)notification {
    NSFileHandle *fh = [notification object];
    NSData *data = [fh availableData];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSLog(@"Unmount: %@", str);
}

- (void)didUpload:(NSNotification *)notification {
    NSFileHandle *fh = [notification object];
    NSData *data = [fh availableData];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSLog(@"Flash: %@", str);
    
    [self.spinner stopAnimation:self];
}

//--------------------------------------------------------------

//--------------------------------------------------------------
// METHODS
//--------------------------------------------------------------

-(void)getMountPointForPath:(NSString *) path {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/bash"];
    
    NSMutableString *cmd = [[NSMutableString alloc] init];
    [cmd appendString:@"/bin/df "];
    [cmd appendString:@"\""];
    [cmd appendString:path];
    [cmd appendString:@"\" | tail -1 | awk '{ print $1 }'"];
    
    NSLog(cmd);
    
    [task setArguments:@[ @"-c", cmd ]];
    
    // handle output
    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];
    NSFileHandle *fh = [outputPipe fileHandleForReading];
    [fh waitForDataInBackgroundAndNotify];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gotMountPoint:) name:NSFileHandleDataAvailableNotification object:fh];
    //            [[outputPipe fileHandleForReading] readToEndOfFileInBackgroundAndNotify];
    
    [task launch];
}

-(void)processMountPoint:(NSString *)str {
    NSLog(@"Processing mount point: %@", str);
    // strip any newline characters
    str = [str stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    // perform a regex on the returned mountPoint,
    // e.g. to turn /dev/disk1s2 into /dev/rdisk1
    // using sed, the command would be:
    // sed 's/s[0-9]//g' | sed 's/\/disk/\/rdisk/g'
    NSError *error = nil;
    NSRegularExpression *removeSectorRegex = [NSRegularExpression regularExpressionWithPattern:@"s\\d+" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *stringNoSector = [removeSectorRegex stringByReplacingMatchesInString:str options:0 range:NSMakeRange(0, [str length]) withTemplate:@""];
    
    // SAFETY CHECK — never allow user to set mount point to /dev/disk0 (that would suck balls)
    NSRegularExpression *diskZeroRegex = [NSRegularExpression regularExpressionWithPattern:@"disk0" options:NSRegularExpressionCaseInsensitive error:&error];
    NSRange textRange = NSMakeRange(0, str.length);
    NSRange matchRange = [diskZeroRegex rangeOfFirstMatchInString:str options:NSMatchingReportProgress range:textRange];
    
    if(matchRange.location != NSNotFound) {
        // shit, we found a match. Abort! Abort! Do not press the red button!
        [self.uploadBtn setEnabled:NO];
        [self.SDBrowseBox setStringValue:@"WRONG DISK SELECTED"];
        return;
    }
    
    // we're safe, move on
    self.mountPoint = stringNoSector;
    
    NSRegularExpression *addPrefixRegex = [NSRegularExpression regularExpressionWithPattern:@"/disk" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *stringWithPrefix = [addPrefixRegex stringByReplacingMatchesInString:stringNoSector options:0 range:NSMakeRange(0, [stringNoSector length]) withTemplate:@"/rdisk"];
    self.mountPointRaw = stringWithPrefix;
    
    NSLog(@"Mount point: %@", self.mountPoint);
    [self.SDBrowseBox setStringValue:self.mountPoint];
}

-(void)flashSDCard {
    // reference:
    // http://smittytone.wordpress.com/2013/09/06/back-up-a-raspberry-pi-sd-card-using-a-mac/
    
    // unmount //
    NSTask *unmount = [[NSTask alloc] init];
    [unmount setLaunchPath:@"/bin/bash"];
    NSMutableString *unmountCmd = [[NSMutableString alloc] initWithString:@"diskutil unmountDisk "];
    [unmountCmd appendString:self.mountPoint];
    
    [unmount setArguments:@[ @"-c", unmountCmd ]];
    
    NSLog(@"Unmount cmd: %@", unmountCmd);
    
    // handle output
    NSPipe *unmountOutput = [NSPipe pipe];
    [unmount setStandardOutput:unmountOutput];
    NSFileHandle *fh = [unmountOutput fileHandleForReading];
    [fh waitForDataInBackgroundAndNotify];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUnmount:) name:NSFileHandleDataAvailableNotification object:fh];
    
    [unmount launch];
    [unmount waitUntilExit];
    
    // flash //
    NSString* output = nil;
    NSString* processErrorDescription = nil;
    
    NSString *imagePathQuoted = [NSString stringWithFormat:@"'%@'", self.imagePath];
    NSString *ddCommand = [NSString stringWithFormat:@"sudo dd of=%@ bs=1m", self.mountPointRaw];
    
    BOOL success = [self runProcessAsAdministrator:@"gzip" withArguments:[NSArray arrayWithObjects:@"-dc", imagePathQuoted, @"|", ddCommand, nil] output:&output errorDescription:&processErrorDescription];
    
    if(!success) NSLog(@"Failed with exit code %@", processErrorDescription);
    else {
        NSLog(@"Flash: %@", output);
    }
    
    [self.spinner stopAnimation:self];
    
/** OLD METHOD -- will not work due to elevated privileges requirement **/
//    NSTask *flash = [[NSTask alloc] init];
//    [flash setLaunchPath:@"/bin/bash"];
//    
//    NSMutableString *flashCmd = [[NSMutableString alloc] init];
//    [flashCmd appendString:@"gzip -dc \""];
//    [flashCmd appendString:self.imagePath];
//    [flashCmd appendString:@"\" | sudo dd of="];
//    [flashCmd appendString:self.mountPoint];
//    [flashCmd appendString:@" bs=1m"];
//    
//    [flash setArguments:@[ @"-c", flashCmd ]];
//    
//    NSLog(@"Flash cmd: %@", flashCmd);
//    
//    // handle output
//    NSPipe *flashOutput = [NSPipe pipe];
//    [flash setStandardOutput:flashOutput];
//    fh = [flashOutput fileHandleForReading];
//    [fh waitForDataInBackgroundAndNotify];
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpload:) name:NSFileHandleDataAvailableNotification object:fh];
//    
//    [flash launch];
//    [flash waitUntilExit];
}

// adapted from:
// http://stackoverflow.com/questions/3541654/how-to-give-permission-using-nstask-objective-c
// Could do this with more complicated shit like SMJobBless (makes me think of the pope) + XPC, but why bother really?
// (note — should you ever want to bother, see
// https://github.com/atnan/SMJobBlessXPC for a good example
- (BOOL) runProcessAsAdministrator:(NSString*)scriptPath
                     withArguments:(NSArray *)arguments
                            output:(NSString **)output
                  errorDescription:(NSString **)errorDescription {
    
    NSString * allArgs = [arguments componentsJoinedByString:@" "];
    NSString * fullScript = [NSString stringWithFormat:@"'%@' %@", scriptPath, allArgs];
    
    NSLog(@"Full script: %@", fullScript);
    
    NSDictionary *errorInfo = [NSDictionary new];
    NSString *script =  [NSString stringWithFormat:@"do shell script \"%@\" with administrator privileges", fullScript];
    
    NSAppleScript *appleScript = [[NSAppleScript new] initWithSource:script];
    NSAppleEventDescriptor * eventResult = [appleScript executeAndReturnError:&errorInfo];
    
    // Check errorInfo
    if (! eventResult)
    {
        // Describe common errors
        *errorDescription = nil;
        if ([errorInfo valueForKey:NSAppleScriptErrorNumber])
        {
            NSNumber * errorNumber = (NSNumber *)[errorInfo valueForKey:NSAppleScriptErrorNumber];
            if ([errorNumber intValue] == -128)
                *errorDescription = @"The administrator password is required to do this.";
        }
        
        // Set error message from provided message
        if (*errorDescription == nil)
        {
            if ([errorInfo valueForKey:NSAppleScriptErrorMessage])
                *errorDescription =  (NSString *)[errorInfo valueForKey:NSAppleScriptErrorMessage];
        }
        
        return NO;
    }
    else
    {
        // Set output to the AppleScript's output
        *output = [eventResult stringValue];
        
        return YES;
    }
}

@end
