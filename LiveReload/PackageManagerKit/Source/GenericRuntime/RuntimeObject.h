
@protocol RuntimeObject <NSObject>

@property(nonatomic, readonly) NSURL *url;
@property(nonatomic, readonly) BOOL valid;
@property(nonatomic, readonly) BOOL subtreeValidationInProgress;
@property(nonatomic, readonly) NSString *subtreeValidationResultSummary;

// for the Preferences window
@property(nonatomic, readonly) NSString *imageName;
@property(nonatomic, readonly) NSString *mainLabel;
@property(nonatomic, readonly) NSString *detailLabel;

- (void)validate;

@end
