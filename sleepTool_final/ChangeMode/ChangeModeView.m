//
//  ChangeModeView.m
//  ChangeMode
//
//  Created by Int on 2017/6/17.
//  Copyright © 2017年 Int. All rights reserved.
//

#import "ChangeModeView.h"

@interface ChangeModeView ()

@end

@implementation ChangeModeView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)StartFunc:(id)sender
{
    [_delegateForAppDelegate StartFuncDelete:sender];
}


#pragma mark ----- 设置combobox响应事件 -----
- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
    return [_portNameArray count];
}
- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    return [_portNameArray objectAtIndex:index];
}

- (void)comboBoxWillPopUp:(NSNotification *)notification
{
    [self _GetPortName];
    if([_portNameArray count])
    {
        [_portNameComboBox removeAllItems];
        [_portNameComboBox addItemsWithObjectValues:_portNameArray];
    }
}
- (void)_GetPortName
{
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSArray * devices = [fileManager contentsOfDirectoryAtPath:@"/dev/" error:nil];
    
    _portNameArray = [[NSMutableArray alloc]init];
    [_portNameArray removeAllObjects];
    for (NSString * device in devices)
    {
        if ([device rangeOfString:@"cu.usb"].location != NSNotFound)
        {
            [_portNameArray addObject:[device substringFromIndex:device.length- 8]];
        }
    }
}

@end
