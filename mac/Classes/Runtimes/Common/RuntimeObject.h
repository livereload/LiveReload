
@protocol RuntimeObject <NSObject>

@property(nonatomic, readonly) NSURL *url;
@property(nonatomic, readonly) BOOL valid;
@property(nonatomic, readonly) BOOL subtreeValidationInProgress;
@property(nonatomic, readonly) NSString *subtreeValidationResultSummary;

- (void)validate;

@end
