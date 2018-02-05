//
//  types.h
//  Transformers
//
//  Created by panda on 15/5/29.
//  Copyright (c) 2015年 IEDC. All rights reserved.
//

#ifndef Transformers_types_h
#define Transformers_types_h
/**
 通信设备的类型
 */
typedef enum
{
    DEVICE = 0,     //机台
    FIXTURE,    //治具
    MIKEY,      //mikey板
    AUX,       //aux
    HALLEFFECT,
    HALLSENSOR,
    SCRIPTTYPE,
    GPIB
} TargetType;

#endif
