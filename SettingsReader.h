#define kPrefsPlistPath @"/var/mobile/Library/Preferences/com.kayfam.appselector.plist"

static NSDictionary *storage;

@interface SettingsReader: NSObject
+ (NSDictionary*) dictionary;

+ (NSString*) getObject:(NSString*)key;
+ (BOOL) getBool:(NSString*)key default:(BOOL)value;
@end