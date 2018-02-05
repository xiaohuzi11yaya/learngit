//
//  SerialPort.h
//  CommunicationPort
//
//  Created by Jerry on 15/4/24.
//  Copyright (c) 2015年 Jerry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/termios.h>
#include<sys/types.h>
#include<sys/stat.h>
#import <dirent.h>

@interface SerialPort: NSObject
@property (assign) int fd;


#define BUFFSIZE 8192

- (Boolean)_OpenPort:(NSString*)devName BaudRate:(int)baudRate;

- (Boolean)_ClosePort;

- (Boolean)_sendCMD:(NSString *)sendData;

- (NSData *)readDataInTime:(NSTimeInterval)timeOut withSize:(size_t)size endSign:(NSString *) endSign;

- (Boolean)readData:(NSString * __autoreleasing *)recv timeout:(NSTimeInterval)timeOut endSymble:(NSString *)endSymble;

- (Boolean)__setBaudRate:(int)baudRate;
@end
