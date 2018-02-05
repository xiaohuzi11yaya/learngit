//
//  SerialPort.m
//  CommunicationPort
//
//  Created by Jerry on 15/4/24.
//  Copyright (c) 2015年 Jerry. All rights reserved.
//

#import "SerialPort.h"

@implementation SerialPort

/**
 *  打开串口
 *
 *  @param devPath 通信设备在系统中的路径
 *  @param speed   打开串口时设置的波特率
 *
 *  @return 打开成功返回true，失败返回false
 */
//打开串口
- (Boolean)_OpenPort:(NSString*)devName BaudRate:(int)baudRate
{
    @autoreleasepool
    {
        NSString * _devPortPathTmp = [NSString stringWithFormat:@"/dev/cu.usbserial-%@", devName];
        struct termios termOpt;
        
        _fd = open([_devPortPathTmp cStringUsingEncoding:NSASCIIStringEncoding], O_RDWR | O_NONBLOCK | O_NOCTTY);
        if (_fd < 0)
        {
            goto error;
        }
        if (tcgetattr(_fd, &termOpt) < 0)
        {
            goto error;
        }
        
        termOpt.c_cflag &= ~(PARENB | CSTOPB);//使用奇偶校验 | 设置两个停止位
        termOpt.c_iflag &= ~(ICRNL | INLCR);//将输入的回车转化成换行（如果IGNCR未设置的情况下）| 将输入的NL（换行）转换成CR（回车）
        termOpt.c_oflag &= ~(OPOST | ONLCR | OCRNL);//处理后输出 | 将输入的NL（换行）转换成CR（回车）及NL（换行）| 将输入的CR（回车）转换成NL（换行）
        termOpt.c_lflag &= ~(ECHO | ECHOE | ECHOK | ECHONL | ICANON | ISIG);//显示输入字符 | 如果ICANON同时设置，ERASE将删除输入的字符 | 如果ICANON同时设置，KILL将删除当前行 | 使用标准输入模式 | 当输入INTR、QUIT、SUSP或DSUSP时，产生相应的信号
        
        //子进程中继承的串口句柄在用exec执行新程序时被关闭
        int fdFlag = fcntl(_fd, F_GETFD, 0);
        fcntl(_fd, F_SETFD, fdFlag | FD_CLOEXEC);
        tcflush(_fd, TCIOFLUSH);
        if (tcsetattr(_fd, TCSANOW, &termOpt) < 0)
        {
            goto error;
        }
        
        if (![self __setBaudRate:baudRate])
        {
            goto error;
        }
    }
    
    return true;
    
error:
    NSLog(@"error");
    close(_fd);
    return false;
}
//关闭串口
- (Boolean)_ClosePort
{
    if (_fd >= 0)
    {
        if (close(_fd) < 0)
        {
            //insert error log
            return false;
        }
    }
    _fd = -1;
    
    return true;
}

//发送数据
- (Boolean)_sendCMD:(NSString *)sendData
{
    @autoreleasepool
    {
        sendData = [sendData stringByAppendingString:@"\r"];
        const void * csend = [sendData cStringUsingEncoding:NSUTF8StringEncoding];
        size_t length = [sendData length];
        if (write(_fd, csend, length) < 0)
        {
            NSLog(@"write fail");
            return false;
        }
    }
    
    return true;
}


- (NSData *)readDataInTime:(NSTimeInterval)timeOut withSize:(size_t)size endSign:(NSString *)endsign
{
    char recvBuf[8196];
    ssize_t nreads;
    ssize_t nbytes;
    NSDate* start;
    
    start = [NSDate date];
    
    memset(recvBuf, 0, sizeof(recvBuf));
    nbytes = 0;
    
    //read() 转为非阻塞模式
    int flags = fcntl(STDIN_FILENO, F_GETFL);
    flags |= O_NONBLOCK;
    fcntl(STDIN_FILENO, F_SETFL, flags);
    //end
    
    //在超时或读取的数据长度达到size时停止
    while ([[NSDate date] timeIntervalSinceDate:start] < timeOut)
    {
        nreads = read(_fd, recvBuf, BUFFSIZE-1);//???
        recvBuf[nreads] = 0;
        
        if (nreads > 0)
        {
            nbytes += nreads;
        }
        if ([endsign length])//防止endsign不输入
        {
            if([[NSString stringWithUTF8String:recvBuf] rangeOfString:endsign].location != NSNotFound)
            {
                nbytes += nreads;
                break;
            }
        }
       
        if (nbytes >= size)
        {
            break;
        }
        
        usleep(1000);
    }
    
    NSData *retData = [[NSData alloc] initWithBytes:(const void*)recvBuf length:nbytes];
    
    //    if ([retData length] < 55)
    //        return NULL;
    
    return retData;
}

//- (NSData *)readDataInTime:(NSTimeInterval)timeOut withSize:(size_t)size
//{
//    char recvBuf[8192];
//    ssize_t nreads;
//    ssize_t nbytes;
//    NSDate* start;
//    
//    start = [NSDate date];
//    
//    memset(recvBuf, 0, sizeof(recvBuf));
//    nbytes = 0;
//    
//    //read() 转为非阻塞模式
//    int flags = fcntl(STDIN_FILENO, F_GETFL);
//    flags |= O_NONBLOCK;
//    fcntl(STDIN_FILENO, F_SETFL, flags);
//    //end
//    
//    //在超时或读取的数据长度达到size时停止
//    while ([[NSDate date] timeIntervalSinceDate:start] < timeOut)
//    {
//        nreads = read(_fd, recvBuf+nbytes, BUFFSIZE);
//        if (nreads > 0)
//            nbytes += nreads;
//        
//        if (nbytes >= size)
//            break;
//        usleep(1);
//    }
//    
//    NSData *retData = [[NSData alloc] initWithBytes:(const void*)recvBuf length:nbytes];
//    
//    //    if ([retData length] < 55)
//    //        return NULL;
//    
//    return retData;
//}


//接收数据
- (Boolean)readData:(NSString * __autoreleasing *)recv timeout:(NSTimeInterval)timeOut endSymble:(NSString *)endSymble
{
    char recvBuf[BUFFSIZE];
    ssize_t nreads;
    NSMutableData * _stageData = [NSMutableData data];
    NSDate * _startDate = [NSDate date];
    
    while (true)
    {
        nreads = read(_fd, recvBuf, BUFFSIZE-1);
        recvBuf[nreads] = 0;
        if (nreads > 0)
        {
            
            NSData * _appendData = [NSData dataWithBytes:recvBuf length:nreads];
            if (_appendData)
            {
                [_stageData appendData:_appendData];
            }
            if ([endSymble length])
            {
                NSString * _recvStrTmp = [NSString stringWithUTF8String:recvBuf];
                NSString * _recvStrTmpNoEndSpace = [_recvStrTmp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if ([_recvStrTmpNoEndSpace hasSuffix:endSymble])
                {
                    break;
                }
            }
        }
        else if (nreads == 0)
        {
            NSLog(@"\nread end\n");
            break;
        }
        strcpy(recvBuf, "");
        
        NSTimeInterval _currentTime = [[NSDate date] timeIntervalSinceDate:_startDate];
        if (_currentTime > timeOut)
        {
            break;
        }
    }
    *recv = [[NSString alloc] initWithData:_stageData encoding:NSASCIIStringEncoding];
    
    return true;
}

//++++++++++++++++++++++==
/**
 *  设置串口波特率的大小
 *
 *  @param baudRate 波特率数值
 *
 *  @return 设置成功返回true，失败返回false
 */
- (Boolean)__setBaudRate:(int)baudRate
{
    const speed_t baudRatesDef[] = { B50, B75, B110, B134, B150, B200, B300, B600, B1200, B1800, B2400, B4800, B9600, B115200, B19200, B38400 };
    const int baudRates[] = { 50, 75, 110, 134, 150, 200, 300, 600, 1200, 1800, 2400, 4800, 9600, 115200, 19200, 38400 };
    
    struct termios termOpt;
    int nlevels = sizeof(baudRates);
    int index = 0;
    while (baudRates[index]!=baudRate && index<nlevels)
    {
        index++;
    }
    
    if (index == nlevels)
    {
        return false;
    }
    if (tcgetattr(_fd, &termOpt) < 0)
    {
        return false;
    }
    
    cfsetspeed(&termOpt, baudRatesDef[index]);
    tcflush(_fd, TCIOFLUSH);
    if (tcsetattr(_fd, TCSANOW, &termOpt) < 0)
    {
        return false;
    }
    
    return true;
}
@end
