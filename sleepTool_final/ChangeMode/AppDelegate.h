//
//  AppDelegate.h
//  ChangeMode
//
//  Created by Int on 2017/6/17.
//  Copyright © 2017年 Int. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ChangeModeView.h"
#import "SerialPort.h"

#define STATION_PATH @"/Users/swee/Desktop/sleepTool_final/station_info.json"
@interface AppDelegate : NSObject <NSApplicationDelegate, ChangeModeViewDelegateAppDelegate>
{
    ChangeModeView * _singleWindowType[4];
    NSThread * _startBtnThread[4];
    SerialPort * _portName[4];
    NSString * _currentDateTimePath[4];
    
    NSString * _tsId;    
    NSString * _cmdStr ;
    NSString * _logPath;
    NSString * _autoRun;
    NSString * _sfcURL;
//    NSTask * _task;
    NSTask * _task[4];
    NSString * _returnSFCInfo[4];
    NSString * _sn[4];
}

@end

