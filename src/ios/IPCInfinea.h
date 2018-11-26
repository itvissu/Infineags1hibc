//
//  IPCInfinea.h
//  Cordova Plugin - Johnson & Johnson
//
//  Created by Brad Schuran on 1/27/17.
//  Copyright © 2017 Infinite Peripherals. All rights reserved.
//

#import <Cordova/CDVPlugin.h>
#import "DTDevices.h"


@interface Infinea : CDVPlugin
{
    NSDictionary *cb;
    DTDevices *sdk;
}

-(void)pluginInitialize;
-(void)initWithCallbacks:(CDVInvokedUrlCommand*)command;

-(void)deviceInfo:(CDVInvokedUrlCommand*)command;
-(void)setAutoTimeout:(CDVInvokedUrlCommand*)command;
-(void)setPassThrough:(CDVInvokedUrlCommand*)command;
-(void)setDeviceCharge:(CDVInvokedUrlCommand*)command;
-(void)setDeviceSound:(CDVInvokedUrlCommand *)command;

-(void)barScan:(CDVInvokedUrlCommand*)command;
-(void)barSetScanMode:(CDVInvokedUrlCommand*)command;
-(void)barOpticonSetCustomConfig:(CDVInvokedUrlCommand*)command;
-(void)barIntermecSetCustomConfig:(CDVInvokedUrlCommand*)command;
-(void)barCodeSetParams:(CDVInvokedUrlCommand*)command;

@end
