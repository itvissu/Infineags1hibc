//
//  IPCInfinea.m
//  Cordova Plugin - Johnson & Johnson
//
//  Created by Brad Schuran on 1/27/17.
//  Copyright © 2017 Infinite Peripherals. All rights reserved.
//

#import "IPCInfinea.h"

@implementation Infinea

- (void)pluginInitialize
{
    
}

/* Start - Delegates */
-(void)connectionState:(int)state
{
    if(state==CONN_CONNECTED)
    {
        NSError *error;
        
        [sdk barcodeEngineResetToDefaults:&error];
        [sdk barcodeSetTypeMode:BARCODE_TYPE_EXTENDED error:nil];
        
        if([sdk getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_INTERMEC)
        {
            NSError *error;
            
            const uint8_t intermecInit[]=
            {
                0x41,
                0x4f,0x40,1,
            };
            [sdk barcodeIntermecSetInitData:[NSData dataWithBytes:intermecInit length:sizeof(intermecInit)] error:&error];
        }
        
    }
    
    NSString *func=[NSString stringWithFormat:@"%@(%@);",[cb valueForKey:@"barcodeStatusCallback"],state==CONN_CONNECTED?@"true":@"false"];
    
    [(UIWebView*)super.webView stringByEvaluatingJavaScriptFromString:func];
    
}

-(void)barcodeNSData:(NSData *)barcode type:(int)type {
    
    // Check and convert the GS1 barcode
    NSMutableString *_string = [NSMutableString stringWithString:@""];
    NSString *final = @"";
    NSString *gsReplace = @"";
    
    // GS 1 Replacement
    if(type == 30){
        gsReplace = @"]d2";
    }
    else if(type == 15){
        gsReplace = @"]C1";
    }
    
    for (int i = 0; i < barcode.length; i++) {
        unsigned char _byte;
        [barcode getBytes:&_byte range:NSMakeRange(i, 1)];
        
        if (_byte >= 32 && _byte < 127) {
            [_string appendFormat:@"%c", _byte];
        } else {
            [_string appendFormat:@"%@", gsReplace];
        }
    }
    
    if ([_string containsString:gsReplace]) {
        if(![_string hasPrefix:gsReplace]) {
            [_string insertString:gsReplace atIndex:0];
        }
    }
    
    // Add prefix automatically on those codes
    if(type == 30 || type == 15){
        if(![_string hasPrefix:gsReplace]) {
            [_string insertString:gsReplace atIndex:0];
        }
    }
    
    final = _string;
    
    // HIBC Check
    if (type == 7) {
        if([_string hasPrefix:@"*+"]) {
            NSRange characterRange = [_string rangeOfString: @"*+"];
            if (NSNotFound != characterRange.location) {
                final = [_string stringByReplacingCharactersInRange: characterRange
                                                         withString: @"]C0+"];
            }
        }
        else if([_string hasPrefix:@"+"]){
            NSRange characterRange = [_string rangeOfString: @"+"];
            if (NSNotFound != characterRange.location) {
                final = [_string stringByReplacingCharactersInRange: characterRange
                                                         withString: @"]C0+"];
            }
        }
    }
    
    NSString *func=[NSString stringWithFormat:@"%@(\"%@\",%d,\"%@\");",[cb valueForKey:@"barcodeDataCallback"],final,type,[sdk barcodeType2Text:type]];
    [(UIWebView*)super.webView stringByEvaluatingJavaScriptFromString:func];
}

- (void)deviceButtonPressed: (int)which
{
    NSString *func=[NSString stringWithFormat:@"%@(%d,%@);",[cb valueForKey:@"buttonPressedCallback"],which, @"true"];
    NSLog(@"%@",func);
    [(UIWebView*)super.webView stringByEvaluatingJavaScriptFromString:func];
}

- (void)deviceButtonReleased: (int)which
{
    NSString *func=[NSString stringWithFormat:@"%@(%d,%@);",[cb valueForKey:@"buttonPressedCallback"],which, @"false"];
    
    [(UIWebView*)super.webView stringByEvaluatingJavaScriptFromString:func];
}

/* End - Delegates */


-(void)initWithCallbacks:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    
    @try {
        sdk=[DTDevices sharedDevice];
        sdk.delegate=self;
        [sdk connect];
        [sdk setAutoOffWhenIdle:36000 whenDisconnected:36000 error:nil];
        
        cb= [[command.arguments objectAtIndex:0] copy];
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } @catch (id exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)deviceInfo:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    
    @try {
        NSDictionary *deviceDetails = [[NSDictionary alloc] init];
        deviceDetails = [self getDeviceDetails];
        
        NSData *JSONData = [NSJSONSerialization dataWithJSONObject:deviceDetails
                                                           options:0
                                                             error:nil];
        
        NSString *JSONString = [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding];
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:JSONString];
        
        
    } @catch (id exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSDictionary *)getDeviceDetails
{
    NSMutableDictionary *dictDTDevice = [[NSMutableDictionary alloc] init];
    sdk=[DTDevices sharedDevice];
    sdk.delegate=self;
    [sdk connect];
    
    NSString *hardwareSDK = @"";
    NSString *hardwareSerialNumber = @"";
    NSString *hardwareName = @"";
    NSString *hardwareModel = @"";
    NSString *hardwareRevision = @"";
    NSString *hardwareBattery = @"";
    NSString *hardwareVoltage = @"";
    NSString *hardwareFirmware = @"";
    NSString *hardwareKioskMode = @"";
    NSString *hardwarePassThruSync = @"";
    NSString *hardwareBackupCharge = @"";
    NSString *error = @"";
    
    if (sdk.connstate == CONN_CONNECTED) {
        hardwareSDK = [NSString stringWithFormat:@"%d.%d", sdk.sdkVersion/100, sdk.sdkVersion%100];
        hardwareSerialNumber = sdk.serialNumber;
        hardwareName = sdk.deviceName;
        hardwareModel = sdk.deviceModel;
        hardwareFirmware = sdk.firmwareRevision;
        hardwareRevision = sdk.hardwareRevision;
        
        BOOL isKioskMode = NO;
        [sdk getKioskMode:&isKioskMode error:nil];
        hardwareKioskMode = (isKioskMode ? @"True" : @"False");
        
        // Battery
        DTBatteryInfo *batteryInfo = [sdk getBatteryInfo:nil];
        if (batteryInfo) {
            hardwareBattery = [NSString stringWithFormat:@"%i", batteryInfo.capacity];
            hardwareVoltage = [NSString stringWithFormat:@"%0.2f", batteryInfo.voltage];
        }
        
        // Pass thru sync
        BOOL passThruSync = NO;
        [sdk getPassThroughSync:&passThruSync error:nil];
        hardwarePassThruSync = passThruSync ? @"True" : @"False";
        
        
        // Backup charge
        BOOL isCharging = NO;
        [sdk getCharging:&isCharging error:nil];
        hardwareBackupCharge = isCharging ? @"True" : @"False";
    }
    else{
        error = @"Device not connected";
    }
    
    // set object
    [dictDTDevice setObject:hardwareFirmware forKey:@"firmware"];
    [dictDTDevice setObject:hardwareModel forKey:@"model"];
    [dictDTDevice setObject:hardwareName forKey:@"hardwareName"];
    [dictDTDevice setObject:hardwareSDK forKey:@"sdkVersion"];
    [dictDTDevice setObject:hardwareSerialNumber forKey:@"serial"];
    [dictDTDevice setObject:hardwareBattery forKey:@"batteryLevel"];
    [dictDTDevice setObject:hardwarePassThruSync forKey:@"passThruSync"];
    [dictDTDevice setObject:hardwareBackupCharge forKey:@"backupCharge"];
    [dictDTDevice setObject:error forKey:@"error"];
    
    return dictDTDevice;
}

-(void)setAutoTimeout:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSError *error;
    
    @try {
        bool success=false;
        int timeOff = [[command.arguments objectAtIndex:0] intValue];
        
        success = [sdk setAutoOffWhenIdle:timeOff whenDisconnected:30 error:&error];
        if (success) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        }
        else
        {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        }
    } @catch (id exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)setPassThrough:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSError *error;
    
    @try {
        bool success = false;
        bool mode = [[command.arguments objectAtIndex:0] boolValue];
        
        success = [sdk setPassThroughSync:mode error:&error];
        if (success) {
            
            if(!mode){
                success = [sdk setUSBChargeCurrent:1000 error:&error];
                
                if (success) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                }
                else{
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
                }
            }
            else{
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            }
        }
        else
        {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        }
    } @catch (id exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)setDeviceCharge:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSError *error;
    
    @try {
        bool success=false;
        bool mode = [[command.arguments objectAtIndex:0] boolValue];
        
        success = [sdk setCharging:mode error:&error];
        if (success) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        }
        else
        {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        }
    } @catch (id exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)setDeviceSound:(CDVInvokedUrlCommand *)command{
    CDVPluginResult* pluginResult = nil;
    NSError *error;
    
    @try {
        bool success=false;
        
        bool scanBeep = [[command.arguments objectAtIndex:0] boolValue];
        int volume = 10;
        int beepData[]={2000,400,5000,400};
        int length = 4;
        
        success = [sdk barcodeSetScanBeep:scanBeep volume:volume beepData:beepData length:length error:&error];
        
        if (success) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        }
        else
        {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        }
    } @catch (id exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


-(void)barScan:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSError *error;
    
    @try {
        NSString* myarg = [[command.arguments objectAtIndex:0] lowercaseString];
        bool success=false;
        
        if([myarg isEqualToString:@"on"] || [myarg isEqualToString:@"yes"] || [myarg isEqualToString:@"true"] || [myarg isEqualToString:@"1"])
            success=[sdk barcodeStartScan:&error];
        else
            success=[sdk barcodeStopScan:&error];
        
        if (success) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        }
        else
        {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        }
    } @catch (id exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)barSetScanMode:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSError *error;
    
    @try {
        bool success=false;
        
        success=[sdk barcodeSetScanMode:[[command.arguments objectAtIndex:0] intValue] error:&error];
        
        if (success) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        }
        else
        {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        }
    } @catch (id exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)barOpticonSetCustomConfig:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSError *error;
    
    @try {
        bool success=false;
        
        success=[sdk barcodeOpticonSetInitString:[command.arguments objectAtIndex:0] error:&error];
        
        if (success) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        }
        else
        {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        }
    } @catch (id exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)barIntermecSetCustomConfig:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSError *error;
    
    @try {
        bool success=false;
        NSArray *data=[command.arguments objectAtIndex:0];
        uint8_t buf[data.count];
        for(int i=0;i<data.count;i++)
            buf[i]=(uint8_t)[[data objectAtIndex:i] intValue];
        
        success=[sdk barcodeIntermecSetInitData:[NSData dataWithBytes:buf length:sizeof(buf)] error:&error];
        
        if (success) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        }
        else
        {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        }
    } @catch (id exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)barCodeSetParams:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSError *error;
    
    @try {
        bool success=false;
        NSArray *data=[command.arguments objectAtIndex:0];
        
        for(int i=0;i<data.count;i+=2)
        {
            success=[sdk barcodeCodeSetParam:[[data objectAtIndex:i] intValue] value:[[data objectAtIndex:i+1] intValue] error:&error];
            if(!success)
                break;
        }
        
        
        if (success) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        }
        else
        {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
        }
    } @catch (id exception) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception];
    }
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
