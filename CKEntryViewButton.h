@interface CKEntryViewButton : UIButton
	@property (nonatomic, retain) UIColor *ckTintColor;

	+ (id) entryViewButtonImageForType:(long long)arg1;

	- (id) ckTintColor;
	- (long long) entryViewButtonType;
@end