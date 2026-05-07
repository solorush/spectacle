#import "SpectacleLoginItemHelper.h"
#import <ServiceManagement/ServiceManagement.h>

@implementation SpectacleLoginItemHelper

+ (BOOL)isLoginItemEnabledForBundle:(NSBundle *)bundle
{
  NSString *bundleIdentifier = bundle.bundleIdentifier;
  if (!bundleIdentifier) return NO;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  NSArray *jobs = (__bridge_transfer NSArray *)SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
#pragma clang diagnostic pop
  for (NSDictionary *job in jobs) {
    if ([job[@"Label"] isEqualToString:bundleIdentifier]) {
      return [job[@"OnDemand"] boolValue];
    }
  }
  return NO;
}

+ (void)enableLoginItemForBundle:(NSBundle *)bundle
{
  NSString *bundleIdentifier = bundle.bundleIdentifier;
  if (!bundleIdentifier) return;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  SMLoginItemSetEnabled((__bridge CFStringRef)bundleIdentifier, YES);
#pragma clang diagnostic pop
}

+ (void)disableLoginItemForBundle:(NSBundle *)bundle
{
  NSString *bundleIdentifier = bundle.bundleIdentifier;
  if (!bundleIdentifier) return;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  SMLoginItemSetEnabled((__bridge CFStringRef)bundleIdentifier, NO);
#pragma clang diagnostic pop
}

@end
