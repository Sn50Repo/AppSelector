#import "SettingsReader.h"

@implementation SettingsReader
+ (NSDictionary*) dictionary {
	if (!storage) {
		storage = [NSDictionary dictionaryWithContentsOfFile:kPrefsPlistPath];
	}
	return storage;
}

+ (NSString*) getObject:(NSString*)key {
	return [[self dictionary] objectForKey:key];
}

+ (BOOL) getBool:(NSString*)key default:(BOOL)value {
	if ([[self dictionary] valueForKey:key] == nil) {
		return value;
	}
	return [[[self dictionary] valueForKey:key] boolValue];
}
@end