/**
 * Copyright (c) 2016-present Mesosfer, Cubeacon.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "AppDelegate.h"
#import <Cubeacon/Cubeacon.h>
#import <Mesosfer/Mesosfer.h>

@interface AppDelegate () <CBBluetoothManagerDelegate, CBBeaconManagerDelegate>

@property (nonatomic, strong) CBBluetoothManager *bluetoothManager;
@property (nonatomic, strong) CBBeaconManager *beaconManager;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // initialize mesosfer sdk
    [Mesosfer initializeWithApplicationId:@"YOUR-MESOSFER-APP-ID" clientKey:@"YOUR-MESOSFER-CLIENT-KEY"];
    
    // initialize cubeacon sdk
    [Cubeacon initialize];
    
    // initialize bluetooth manager
    self.bluetoothManager = [[CBBluetoothManager alloc] initWithDelegate:self];
    
    // initialize beacon manager
    self.beaconManager = [[CBBeaconManager alloc] init];
    self.beaconManager.delegate = self;
    
    // register user notification
    UIUserNotificationSettings *setting = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil];
    [application registerUserNotificationSettings:setting];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark ---

- (void)searchForStorylineWithRegion:(CBRegion*)region andEvent:(MFBeaconEvent)event {
    NSLog(@"Searching for storyline %@", event == MFBeaconEventEnter ? @"ENTER" : @"EXIT");
    MFQuery *query = [MFStorylineDetail query];
    [query whereKey:STORYLINE_DETAIL_KEY_BEACONS equalTo:region.identifier];
    [query whereKey:STORYLINE_DETAIL_KEY_EVENT equalTo:@(event)];
    [query setLimit:1];
    [query findAsyncWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        // check if there is an exception happen
        if (error) {
            NSLog(@"Error when finding storyline: %@", error);
            return;
        }
        
        NSLog(@"Found storyline detail: %lu", objects.count);
        if (objects && objects.count > 0) {
            MFStorylineDetail *detail = objects[0];
            NSLog(@"Storyline: %@", detail);
            [self displayStoryline:detail];
        }
    }];
}

- (void)displayStoryline:(MFStorylineDetail*)detail {
    if (detail.campaign == MFStorylineCampaignText) {
        NSString *title = detail.alertTitle;
        NSString *message = detail.alertMessage;
        
        // check application state, if in :
        // - background : show local notification
        // - foreground : show alert controller
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            notification.alertTitle = title;
            notification.alertBody = message;
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
            
        } else {//if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    }
}

- (void)sendLogWithRegion:(CBRegion*)region andEvent:(MFBeaconEvent)event {
    NSString *beaconId = region.identifier;
    
    MFLog *log = [MFLog logWithBeacon:[MFBeacon beaconWithObjectId:beaconId]
                                event:event
                               module:MFBeaconModulePresence];
    [log sendAsyncWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error when sending log: %@", error);
            return;
        }
        
        NSLog(@"Log %@ sent.", event == MFBeaconEventEnter ? @"ENTER" : @"EXIT");
    }];
}

#pragma mark - Beacon manager delegate methods

- (void)didEnterRegion:(CBRegion *)region {
    NSLog(@"Entering region: %@", region);
    [self searchForStorylineWithRegion:region andEvent:MFBeaconEventEnter];
    [self sendLogWithRegion:region andEvent:MFBeaconEventEnter];
}

- (void)didExitRegion:(CBRegion *)region {
    NSLog(@"Exiting region: %@", region);
    [self searchForStorylineWithRegion:region andEvent:MFBeaconEventExit];
    [self sendLogWithRegion:region andEvent:MFBeaconEventExit];
}

- (void)didDetermineState:(CBRegionState)state forRegion:(CBRegion *)region {
    NSLog(@"Change state %hhu for region: %@", state, region);
}

- (void)didChangeAuthorizationStatus:(CBAuthorizationStatus)status {
    // start download beacon when authorized
    if (status == CBAuthorizationStatusAuthorizedAlways || status == CBAuthorizationStatusAuthorizedWhenInUse) {
        // querying all beacon
        [[MFBeacon query] findAsyncWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            // check if there is an exception happen
            if (error) {
                NSLog(@"Error when downloading beacons: %@", error);
                return;
            }
            
            // get the result
            if (objects) {
                // populate the result into list of region for scanning
                NSMutableArray *regions = [[NSMutableArray alloc] init];
                for (MFBeacon *beacon in objects) {
                    NSLog(@"Beacon: %@", beacon.dictionary);
                    CBRegion *region = [[CBRegion alloc] initWithProximityUUID:beacon.proximityUUID
                                                                         major:[beacon.major intValue]
                                                                         minor:[beacon.minor intValue]
                                                                    identifier:beacon.objectId];
                    [regions addObject:region];
                }
                // start monitoring using regions
                [self.beaconManager startMonitoringForRegions:regions];
            } else {
                NSLog(@"Beacon not found.");
            }
        }];
    }
}

#pragma mark - BLuetooth manager delegate methods

- (void)bluetoothManagerDidUpdateState:(CBBluetoothManager *)manager {
    if (manager.state == CBBluetoothStatePoweredOn) {
        [self.beaconManager requestAlwaysAuthorization];
    }
}


@end
