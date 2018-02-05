//
//  AppDelegate.m
//  ChangeMode
//
//  Created by Int on 2017/6/17.
//  Copyright © 2017年 Int. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self.window setMovableByWindowBackground:YES];
    _cmdStr = [[NSString alloc] init];
    _logPath = [[NSString alloc] init];
    _autoRun =[[NSString alloc] init];
    _tsId = [[NSString alloc] init];
    _sfcURL = [[NSString alloc] init];
    
    for (int i=0; i<4; i++)
    {
        _portName[i] = [[SerialPort alloc] init];
        _task[i] = [[NSTask alloc] init];
        _returnSFCInfo[i] = [[NSString alloc] init];
        
        _singleWindowType[i] = [[ChangeModeView alloc] initWithNibName:@"ChangeModeView" bundle:nil];
        _singleWindowType[i].delegateForAppDelegate = self;
    }
    _cmdStr = [self _getPlistForKey:@"CMD"];
    _logPath = [self _getPlistForKey:@"logPath"];
    _autoRun = [self _getPlistForKey:@"autoRun"];
    _sfcURL = [self _getPlistForKey:@"SFC_URL"];
    _tsId = [self _getJsonForKey:@"STATION_ID"];
    //根据singleWindow定义主窗口大小
   

    [self.window setContentSize:CGSizeMake(_singleWindowType[0].view.frame.size.width*4, _singleWindowType[0].view.frame.size.height)];
    
    [self _showView];
    if([_tsId isEqualToString:@"ERROR"])
    {
        
    }
    if([_autoRun isEqualToString:@"YES"])
    {
        for (int i=0; i<4; i++)
        {
            NSThread * _autoRunThread = [[NSThread alloc]initWithTarget:self selector:@selector(_autoRun:) object:[NSNumber numberWithInt:i]];
            [_autoRunThread start];
        }
    }
    
    
}


- (void)_showView
{
    for (int i=0; i<4; i++)
    {
        
        [_singleWindowType[i].view setFrameOrigin:CGPointMake(_singleWindowType[i].view.frame.size.width*i, 0)];
        [self.window.contentView addSubview:_singleWindowType[i].view];
    }
    for(int i=0; i<4; i++){
        if([_autoRun isEqualToString:@"YES"]){
            _singleWindowType[i].startBtn.enabled = NO;
        }
        else
        {
            [_singleWindowType[i].startBtn setTitle: @"START"];
            _singleWindowType[i].startBtn.enabled = YES;
        }
    }
    
}

- (void)_autoRun:(NSNumber *)indexNumber
{
    int index = [indexNumber intValue];
    while (true)
    {
        [self _waitUartConnectedIndex:index];
        [self _ForStartBtn:[NSNumber numberWithInt:index]];
        
        sleep(3);
        
        [_singleWindowType[index].statusTextField setStringValue:@"Waiting"];
        [_singleWindowType[index].statusTextField setTextColor:[NSColor grayColor]];
    }
}
- (void)_waitUartConnectedIndex:(int)index
{
    NSString * _recvStr = @"";
    NSArray * _endSymbleArray = [[NSArray alloc]initWithObjects:@"] :-)", @"Login:", @"login:", @"root#", @"[m]", nil];
    
    while (true)
    {
        NSString * _portNameStr = _singleWindowType[index].portNameComboBox.stringValue;
        if ([_portNameStr isEqualToString:@""] || _portNameStr==nil)
        {
            usleep(10000);
            continue;
        }
        [_portName[index] _OpenPort:_portNameStr BaudRate:115200];
        
        if ([[NSThread currentThread] isCancelled])
        {
            [_portName[index] _ClosePort];
            [NSThread exit];
        }
        [_portName[index] _sendCMD:@" "];
        [_portName[index] readData:&_recvStr timeout:1 endSymble:@""];
        NSString * _recvStrDelSpace = [_recvStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        for (id _endSymble in _endSymbleArray)
        {
            if ([_recvStrDelSpace hasSuffix:_endSymble])
            {
                [_portName[index] _ClosePort];
                return;
            }
        }
        
        usleep(10000);
    }
}

- (void)StartFuncDelete:(id)sender
{
    for (int i=0; i<4; i++)
    {
        if (sender == _singleWindowType[i].startBtn)
        {
            [self _threadForStartBtn:i];
            return;
        }
    }
}
- (void)_threadForStartBtn:(int)index
{
    _startBtnThread[index] = [[NSThread alloc]initWithTarget:self selector:@selector(_ForStartBtn:) object:[NSNumber numberWithInt:index]];
    [_startBtnThread[index] start];
}
- (void)_ForStartBtn:(NSNumber *)indexNumber
{
    int index = [indexNumber intValue];
    
    _currentDateTimePath[index] = [self _getCurrentTime];
    [self _createLogFile:index];
    [self _writeLog:@"Log Start" index:index];
    [_singleWindowType[index].statusTextField setStringValue:[NSString stringWithFormat:@"Testing%d", index]];
    [_singleWindowType[index].statusTextField setTextColor:[NSColor blueColor]];
    [_singleWindowType[index].startBtn setEnabled:NO];
    
    NSString * _portNameStr = _singleWindowType[index].portNameComboBox.stringValue;
    NSLog(@"portNameStr:%@",_portNameStr);
    if ([_portNameStr isEqualToString:@""] || _portNameStr==nil)
    {
        [_singleWindowType[index].statusTextField setStringValue:[NSString stringWithFormat:@"status%d", index]];
        [_singleWindowType[index].statusTextField setTextColor:[NSColor blackColor]];
        [_startBtnThread[index] cancel];
        if([ _autoRun isEqualToString:@"NO"]){
            [_singleWindowType[index].startBtn setEnabled:YES];
        }
        // --- add error log
        [self _writeLog:@"\n port can't read.\n" index:index];
        
        
        return;
    }
    
    //打开端口
    if (![_portName[index] _OpenPort:_portNameStr BaudRate:115200])
    {
        [_singleWindowType[index].statusTextField setStringValue:[NSString stringWithFormat:@"Fail%d", index]];
        [_singleWindowType[index].statusTextField setTextColor:[NSColor redColor]];
        [_startBtnThread[index] cancel];
        if([ _autoRun isEqualToString:@"NO"]){
            [_singleWindowType[index].startBtn setEnabled:YES];
        }
        [self _writeLog:@" port can't open." index:index];
        // --- add open port fail log
        return;
    }
    //模式更改操作
    if ([self _modelChangeAction:index])
    {
        [self _writeLog: @"\nmodel change success\n" index:index];
        @try {
            
            _returnSFCInfo[index] = [self cmdSFC:index cmd:[NSString stringWithFormat:@"curl -d 'sn=%@&c=QUERY_RECORD&p=action:pass_station,tsid:%@,emp:0000000' %@;echo ",_sn[index], _tsId, _sfcURL]];
            [self _writeLog: [NSString stringWithFormat:@"SFC return Info：%@",_returnSFCInfo[index]] index:index];
            
            if([_returnSFCInfo[index] containsString:@"SFC_OK"])
            {
                [_singleWindowType[index].statusTextField setStringValue:[NSString stringWithFormat:@"Success%d", index]];
                [_singleWindowType[index].statusTextField setTextColor:[NSColor greenColor]];
                [self _writeLog: @"\nSFC load SUCC\n" index:index];
            }else
            {
                [self _writeLog: @"\nSFC load FAIL\n" index:index];
                [_singleWindowType[index].statusTextField setStringValue:[NSString stringWithFormat:@"Fail%d", index]];
                [_singleWindowType[index].statusTextField setTextColor:[NSColor redColor]];
            }
        } @catch (NSException *e) {
            NSLog(@"Exception: %@", e);
            NSAlert *alert = [[NSAlert alloc] init];
            
            [alert addButtonWithTitle:@"OK"];
            
            [alert setMessageText:@"SFC connect error!"];
            
            [alert setInformativeText:@"点击确定，退出！"];
            
            [alert setAlertStyle:NSWarningAlertStyle];
            
            NSUInteger action = [alert runModal];
            if(action == NSAlertFirstButtonReturn)
            {
                NSLog(@"defaultButton clicked!");
                exit(0);
            }
        }
        
    }
    else
    {
        [self _writeLog: @"\nmodel change error\n" index:index];
        [_singleWindowType[index].statusTextField setStringValue:[NSString stringWithFormat:@"Fail%d", index]];
        [_singleWindowType[index].statusTextField setTextColor:[NSColor redColor]];
    }
    
    //关掉端口
    [_portName[index] _ClosePort];
    [self _writeLog: @"\nport close\n" index:index];
    
    
    [_startBtnThread[index] cancel];
    if([ _autoRun isEqualToString:@"NO"]){
        [_singleWindowType[index].startBtn setEnabled:YES];
    }
}

- (Boolean)_modelChangeAction:(int)index
{
    //先下空格
    if (![_portName[index] _sendCMD:@" "])
    {
        // --- add send @" " cmd fail log
        [self _writeLog: @"\nsend @" " cmd fail \n" index:index];
        return false;
    }
    NSString * _recvStrTmp = [[NSString alloc] initWithData:[_portName[index] readDataInTime:2 withSize:1000000 endSign:@""] encoding:NSUTF8StringEncoding];
    [self _writeLog:_recvStrTmp index:index];
    NSString * _recvStrDelSpaceTmp = [_recvStrTmp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([_recvStrDelSpaceTmp containsString:@":-)"])
    {
        [self _writeLog: @"\ncurrentz model: diags.\n" index:index];
        
        _sn[index] = [self _getSN:index];
        [_portName[index] _sendCMD:_cmdStr];
        usleep(50000);
        return true;
        
    }
    else if ([_recvStrDelSpaceTmp containsString:@"Login:"] || [_recvStrDelSpaceTmp containsString:@"login:"])
    {
        [self _writeLog: @"\ncurrent model: os.\n" index:index];
        if (![self _OSToDiag:index])
        {
            // --- add _OSToDiag fail log
            [self _writeLog: @"\n_OSToDiag fail\n " index:index];
            return false;
        }
    }
    else if ([_recvStrDelSpaceTmp containsString:@"root#"])
    {
        [self _writeLog: @"\ncurrent model: enterOS.\n" index:index];
        if (![self _enterOSToDiag:index])
        {
            // --- add _enterOSToDiag fail log
            [self _writeLog: @"\n_enterOSToDiag fail \n" index:index];
            return false;
        }
    }
    else if ([_recvStrDelSpaceTmp containsString:@"[m]"])
    {
        [self _writeLog: @"\ncurrent model: recover.\n" index:index];
        if (![self _recoverToDiag:index])
        {
            // --- add _recoverToDiag fail log
            [self _writeLog: @"\n_recoverToDiag fail.\n" index:index];
            return false;
        }
    }
    else
    {
        // --- add no end symble fail log
        [self _writeLog: @"\nno end symble\n" index:index];
        return false;
    }
    _sn[index] = [self _getSN:index];
    [_portName[index] _sendCMD:_cmdStr];
    [self _writeLog:[NSString stringWithFormat:@"send cmd :%@", _cmdStr] index:index];
    
    usleep(500000);
    return true;
    
}
- (NSString *)_getPlistForKey:(NSString *)key
{
    NSString *plistFile = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"plist"];
    NSLog(@"%@",plistFile);
    NSMutableDictionary *dataDic =[[NSMutableDictionary alloc] initWithContentsOfFile:plistFile];
    NSString * infomation = [dataDic objectForKey:key];
    return infomation;
    
}

- (NSString *)_getJsonForKey:(NSString *)key
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if([ fm fileExistsAtPath:STATION_PATH]){
        
        NSString *content =[NSString stringWithContentsOfFile:STATION_PATH encoding:NSUTF8StringEncoding error:nil];
        NSData * data = [content dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dataDic =[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        dataDic = [dataDic objectForKey:@"ghinfo"];
        NSString *infomation = [dataDic objectForKey:key];
        return infomation;
    }
    return @"ERROR";
    
}
-(NSString *)_getSN:(int) index
{
    [self _writeLog:@"send get SN CMD" index:index];
    NSString *sn;
    while(true){
        [_portName[index] _sendCMD:@"syscfg print SrNm"];
        NSString * _rootRecvStrTmp = @"";
        _rootRecvStrTmp =  [[NSString alloc] initWithData:[_portName[index]  readDataInTime:2 withSize:1000000 endSign:@":-)"] encoding:NSUTF8StringEncoding];
        [self _writeLog:_rootRecvStrTmp  index:index ];
        
        sn = [self Regex:@"Serial: (\\w+)\\s*\\[" content:_rootRecvStrTmp];
        if ([_rootRecvStrTmp containsString:@":-)"] && [sn isEqualToString:@""] == false)
        {
            
            [self _writeLog:[NSString stringWithFormat:@"SN: %@",sn] index:index];
            return sn;
        }
    }
    
}
/*
 Describe : According to regular expression catch the values of content
 Input    : reular expression & content
 Output   : NA
 */
- (NSString *)Regex:(NSString *)regex
            content:(NSString *)content
{
    NSRegularExpression * regexTmp = [[NSRegularExpression alloc] initWithPattern:regex
                                                                          options:0
                                                                            error:0];
    NSTextCheckingResult * matchResTmp = [regexTmp firstMatchInString:content
                                                              options:0
                                                                range:NSMakeRange(0, [content length])];
    NSRange rangeOfValue = [matchResTmp rangeAtIndex:1];
    NSString * result = [content substringWithRange:rangeOfValue];
    return result;
}
- (NSString *)cmdSFC:(int)index cmd:(NSString *)cmd
{
    
    // 初始化并设置shell路径
    [_task[index] setLaunchPath: @"/bin/bash"];
    // -c 用来执行string-commands（命令字符串），也就说不管后面的字符串里是什么都会被当做shellcode来执行
    NSArray *arguments = [NSArray arrayWithObjects: @"-c", cmd, nil];
    [_task[index] setArguments: arguments];
    
    // 新建输出管道作为Task的输出
    NSPipe *pipe = [NSPipe pipe];
    [_task[index] setStandardOutput: pipe];
    
    // 开始task
    NSFileHandle *file = [pipe fileHandleForReading];
    [_task[index] launch];
    
    [_task[index] waitUntilExit];
    // 获取运行结果
    NSString *data = [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    return data;
}

- (Boolean)_OSToDiag:(int)index
{
    [_portName[index] _sendCMD:@"root"];
    NSString * _rootRecvStrTmp = @"";
    _rootRecvStrTmp =  [[NSString alloc] initWithData:[_portName[index] readDataInTime:2 withSize:1000000 endSign:@"Password:"] encoding:NSUTF8StringEncoding];
    [self _writeLog:_rootRecvStrTmp index:index];
    if ([_rootRecvStrTmp containsString:@"Password:"])
    {
        [_portName[index] _sendCMD:@"alpine"];
        NSString * _alpineRecvStrTmp =  [[NSString alloc] initWithData:[_portName[index] readDataInTime:1 withSize:1000000 endSign:@"root#"] encoding:NSUTF8StringEncoding];
        if([_alpineRecvStrTmp containsString:@"root#"])
        {
            [self _writeLog:_alpineRecvStrTmp index:index];
            return [self _enterOSToDiag:index];
        }
        else
        {
            // --- add send alpine cmd fail log
            [self _writeLog: @"\nsend alpine cmd fail\n" index:index];
            return false;
        }
    }
    else
    {
        // --- add send root cmd fail log
        [self _writeLog: @"\nsend root cmd fail\n" index:index];
        return false;
    }
}
- (Boolean)_enterOSToDiag:(int)index
{
    [_portName[index] _sendCMD:@"reboot"];
    int _num = 20;
    while (true)
    {
        _num--;
        
        NSString * _spaceRecvStrTmp = @"";
        [_portName[index] _sendCMD:@" "];
        //[self readData:&_spaceRecvStrTmp timeout:1 endSymble:@""];
        // NSData * test = [_portName[_singleIndex] readDataInTime:2 withSize:100000] ;
        
        _spaceRecvStrTmp = [[NSString alloc] initWithData:[_portName[index] readDataInTime:1 withSize:100000 endSign:@"[1m?SYNTAX ERROR\n[m]"]  encoding:NSUTF8StringEncoding];
        
        NSString * _spaceRecvDelSpaceTmp = [_spaceRecvStrTmp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        [self _writeLog:_spaceRecvDelSpaceTmp index:index];
        if ([_spaceRecvDelSpaceTmp containsString:@"]"] )
        {
            [_portName[index] _sendCMD:@" "];
            //[self readData:&_spaceRecvStrTmp timeout:1 endSymble:@""];]
            _spaceRecvStrTmp = [[[NSString alloc] initWithData:[_portName[index] readDataInTime:1 withSize:100000 endSign:@"[m]"]  encoding:NSUTF8StringEncoding]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [self _writeLog:[NSString stringWithFormat:@"diags 后的返回字符串%@",_spaceRecvStrTmp] index:index];
            if([_spaceRecvStrTmp containsString:@"[m]"])
            {
                [self _writeLog: @"\nsend reboot cmd enter recover model\n" index:index];
                break;
            }
            
        }
        
        if (_num == 0)
        {
            [self _writeLog: @"\nreboot send ' ' more than 20 times\n" index:index];
            return false;
        }
    }
    return [self _recoverToDiag:index];
    
}
- (Boolean)_recoverToDiag:(int)index
{
    [_portName[index] _sendCMD:@"diags"];
    //[self readData:&_recoverRecvStrTmp timeout:2 endSymble:@""];
    NSString * _recoverRecvStrTmp = [[NSString alloc] initWithData:[_portName[index] readDataInTime:21 withSize:1000000 endSign:@":-)"] encoding:NSUTF8StringEncoding];
    NSString * _recoverRecvDelSpaceTmp = [_recoverRecvStrTmp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self _writeLog:_recoverRecvStrTmp index:index];
    if (![_recoverRecvDelSpaceTmp containsString:@":-)"])
    {
        [self _writeLog: @"\nsend diags cmd can't enter diags model\n" index:index];
        return false;
    }
    
    return true;
}

//write date and log to .log file
-(void) _writeLog:(NSString *)log index:(int)index
{
    [self _writeDataToFile:index content:@"\n================================================\n"];
    [self _writeDataToFile:index content:[[self _getCurrentTime] stringByAppendingString:log]];
}

/*
 Describe : Writing datas to report
 Input    : faction'name & decriptions.
 Output   : NA
 */
- (void)_createLogFile:(int)index
{
    NSFileManager * fm = [NSFileManager defaultManager];
     [fm createDirectoryAtPath:[NSString stringWithFormat:@"%@",_logPath] withIntermediateDirectories:true attributes:nil error:nil];
    [fm createFileAtPath:[NSString stringWithFormat:@"%@/report_%@_%d.log", _logPath,_currentDateTimePath[index],index]
                contents:nil
              attributes:nil];

}

-(NSString *) _getCurrentTime
{
    NSDate * senddate=[NSDate date];
    NSDateFormatter *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"YYYYMMddHHmmss"];
    NSString * morelocationString=[dateformatter stringFromDate:senddate];
    return morelocationString;
}

- (void)_writeDataToFile:(int)index
                content:(NSString *)content
{
    NSFileHandle *fh = [[NSFileHandle alloc] init];
    NSData *stringData = [[NSData alloc] init];
    fh = [NSFileHandle fileHandleForUpdatingAtPath:[NSString stringWithFormat:@"%@/report_%@_%d.log", _logPath, _currentDateTimePath[index],index]];
    [fh seekToEndOfFile];
    stringData = [content dataUsingEncoding:NSUTF8StringEncoding];
    [fh writeData:stringData];
    [fh closeFile];
}

//---------------------------------
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}


@end
