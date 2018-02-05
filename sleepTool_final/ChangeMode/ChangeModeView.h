//
//  ChangeModeView.h
//  ChangeMode
//
//  Created by Int on 2017/6/17.
//  Copyright © 2017年 Int. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <sys/termios.h>
#include<sys/types.h>
#include<sys/stat.h>
#import <dirent.h>

//回调AppDelegate
@protocol ChangeModeViewDelegateAppDelegate <NSObject>

- (void)StartFuncDelete:(id)sender;

@end

@interface ChangeModeView : NSViewController
{
    NSMutableArray * _portNameArray;
}

@property (weak) id<ChangeModeViewDelegateAppDelegate>delegateForAppDelegate;

@property (assign) int fd;
@property (weak) IBOutlet NSComboBox * portNameComboBox;
@property (weak) IBOutlet NSButton * startBtn;
@property (weak) IBOutlet NSTextField * statusTextField;

- (IBAction)StartFunc:(id)sender;

@end
