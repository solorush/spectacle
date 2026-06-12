#import "SpectacleLoginItemHelper.h"
#import <CoreServices/CoreServices.h>
#import <ServiceManagement/ServiceManagement.h>

@implementation SpectacleLoginItemHelper

+ (BOOL)isLoginItemEnabledForBundle:(NSBundle *)bundle
{
  if (@available(macOS 13.0, *)) {
    if (SMAppService.mainAppService.status == SMAppServiceStatusEnabled) {
      return YES;
    }
  }

  return [self isLegacyLoginItemEnabledForBundle:bundle];
}

+ (BOOL)isLegacyLoginItemEnabledForBundle:(NSBundle *)bundle
{
  LSSharedFileListRef sharedFileList = NULL;
  NSString *applicationPath = bundle.bundlePath;
  BOOL result = NO;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  sharedFileList = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
#pragma clang diagnostic pop

  if (!sharedFileList) {
    NSLog(@"Unable to create the shared file list.");
    return result;
  }

  UInt32 seedValue;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  NSArray *sharedFileListArray = CFBridgingRelease(LSSharedFileListCopySnapshot(sharedFileList, &seedValue));
#pragma clang diagnostic pop
  for (id sharedFile in sharedFileListArray) {
    LSSharedFileListItemRef sharedFileListItem = (__bridge LSSharedFileListItemRef)sharedFile;
    CFURLRef applicationPathURL = NULL;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    LSSharedFileListItemResolve(sharedFileListItem, 0, &applicationPathURL, NULL);
#pragma clang diagnostic pop
    if (applicationPathURL) {
      NSString *resolvedApplicationPath = [(__bridge NSURL *)applicationPathURL path];
      CFRelease(applicationPathURL);
      if ([resolvedApplicationPath isEqualToString:applicationPath]) {
        result = YES;
        break;
      }
    }
  }
  CFRelease(sharedFileList);
  return result;
}

+ (void)enableLoginItemForBundle:(NSBundle *)bundle
{
  if (@available(macOS 13.0, *)) {
    SMAppService *service = SMAppService.mainAppService;
    if (service.status == SMAppServiceStatusEnabled) {
      return;
    }

    NSError *error = nil;
    if (![service registerAndReturnError:&error]) {
      NSLog(@"Unable to enable login item: %@", error);
    }
    return;
  }

  [self enableLegacyLoginItemForBundle:bundle];
}

+ (void)enableLegacyLoginItemForBundle:(NSBundle *)bundle
{
  LSSharedFileListRef sharedFileList = NULL;
  NSString *applicationPath = bundle.bundlePath;
  NSURL *applicationPathURL = [NSURL fileURLWithPath:applicationPath];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  sharedFileList = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
#pragma clang diagnostic pop

  if (!sharedFileList) {
    NSLog(@"Unable to create the shared file list.");
    return;
  }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  LSSharedFileListItemRef sharedFileListItem = LSSharedFileListInsertItemURL(sharedFileList,
                                                                             kLSSharedFileListItemLast,
                                                                             NULL,
                                                                             NULL,
                                                                             (__bridge CFURLRef)applicationPathURL,
                                                                             NULL,
                                                                             NULL);
#pragma clang diagnostic pop
  if (sharedFileListItem) {
    CFRelease(sharedFileListItem);
  }
  CFRelease(sharedFileList);
}

+ (void)disableLoginItemForBundle:(NSBundle *)bundle
{
  if (@available(macOS 13.0, *)) {
    SMAppService *service = SMAppService.mainAppService;
    if (service.status != SMAppServiceStatusNotRegistered && service.status != SMAppServiceStatusNotFound) {
      NSError *error = nil;
      if (![service unregisterAndReturnError:&error] && error.code != kSMErrorJobNotFound) {
        NSLog(@"Unable to disable login item: %@", error);
      }
    }
  }

  [self disableLegacyLoginItemForBundle:bundle];
}

+ (void)disableLegacyLoginItemForBundle:(NSBundle *)bundle
{
  LSSharedFileListRef sharedFileList = NULL;
  NSString *applicationPath = bundle.bundlePath;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  sharedFileList = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
#pragma clang diagnostic pop

  if (!sharedFileList) {
    NSLog(@"Unable to create the shared file list.");
    return;
  }

  UInt32 seedValue;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  NSArray *sharedFileListArray = CFBridgingRelease(LSSharedFileListCopySnapshot(sharedFileList, &seedValue));
#pragma clang diagnostic pop
  for (id sharedFile in sharedFileListArray) {
    LSSharedFileListItemRef sharedFileListItem = (__bridge LSSharedFileListItemRef)sharedFile;
    CFURLRef applicationPathURL = NULL;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    OSStatus resolveResult = LSSharedFileListItemResolve(sharedFileListItem, 0, &applicationPathURL, NULL);
#pragma clang diagnostic pop
    if (resolveResult == noErr && applicationPathURL) {
      NSString *resolvedApplicationPath = [(__bridge NSURL *)applicationPathURL path];
      CFRelease(applicationPathURL);
      if ([resolvedApplicationPath isEqualToString:applicationPath]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        LSSharedFileListItemRemove(sharedFileList, sharedFileListItem);
#pragma clang diagnostic pop
      }
    }
  }
  CFRelease(sharedFileList);
}

@end
