
#import <Foundation/Foundation.h>


void AT_dispatch_after_ms(int64_t delay_ms, dispatch_block_t block);
void AT_dispatch_after_ms_on_queue(int64_t delay_ms, dispatch_queue_t queue, dispatch_block_t block);


// 0 = not scheduled, not running
// 1 or more = scheduled or running
typedef volatile int64_t ATCoalescedState;

// Done callback can be called on any queue/thread.
typedef void (^ATCoalescedBlock)(dispatch_block_t done);

// Can be called on any queue/thread. Will call the given block on the main queue (or the given serial queue).
void AT_dispatch_coalesced(ATCoalescedState *state, int64_t delay_ms, ATCoalescedBlock block);
void AT_dispatch_coalesced_on_queue(ATCoalescedState *state, int64_t delay_ms, dispatch_queue_t serial_queue, ATCoalescedBlock block);
