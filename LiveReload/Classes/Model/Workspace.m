
#import "Workspace.h"


static Workspace *sharedWorkspace;


@implementation Workspace

@synthesize projects=_projects;


#pragma mark -
#pragma mark Singleton

+ (Workspace *)sharedWorkspace {
    if (sharedWorkspace == nil) {
        sharedWorkspace = [[Workspace alloc] init];
    }
    return sharedWorkspace;
}


#pragma mark -
#pragma mark Init/dealloc

- (id)init {
    if (self = [super init]) {
        _projects = [[NSMutableSet alloc] init];

        // temporary projects for debugging, until we implement persistence
        [self addProjectsObject:[[[Project alloc] initWithPath:@"~/Dropbox"] autorelease]];
    }
    return self;
}

// just to make XDry happy; won't ever be deallocated
- (void)dealloc {
	[_projects release], _projects = nil;
	[super dealloc];
}


#pragma mark -
#pragma mark Projects set KVC accessors

- (void)addProjectsObject:(Project *)project {
    
}

- (void)removeProjectsObject:(Project *)project {
    
}


@end
