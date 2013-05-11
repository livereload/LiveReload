
@protocol RuntimeObject <NSObject>

@property(nonatomic, readonly) NSURL *url;
@property(nonatomic, readonly) BOOL validationInProgress;
@property(nonatomic, readonly) BOOL validationPerformed;
@property(nonatomic, readonly) BOOL valid;
@property(nonatomic, readonly) NSString *validationResultSummary;

- (void)validate;

@end
