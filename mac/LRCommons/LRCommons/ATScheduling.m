
#import "ATScheduling.h"


void AT_dispatch_after_ms(int64_t delay_ms, dispatch_block_t block) {
    AT_dispatch_after_ms_on_queue(delay_ms, dispatch_get_main_queue(), block);
}

void AT_dispatch_after_ms_on_queue(int64_t delay_ms, dispatch_queue_t queue, dispatch_block_t block) {
    if (delay_ms > 0)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay_ms * NSEC_PER_MSEC), queue, block);
    else
        dispatch_async(queue, block);
}


void AT_dispatch_coalesced(ATCoalescedState *state, int64_t delay_ms, ATCoalescedBlock block) {
    AT_dispatch_coalesced_on_queue_with_notifications(state, delay_ms, dispatch_get_main_queue(), block, NULL);
}

void AT_dispatch_coalesced_with_notifications(ATCoalescedState *state, int64_t delay_ms, ATCoalescedBlock block, ATCoalescedStateChangeNotificationBlock notificationBlock) {
    AT_dispatch_coalesced_on_queue_with_notifications(state, delay_ms, dispatch_get_main_queue(), block, notificationBlock);
}

void AT_dispatch_coalesced_on_queue(ATCoalescedState *state, int64_t delay_ms, dispatch_queue_t serial_queue, ATCoalescedBlock block) {
    AT_dispatch_coalesced_on_queue_with_notifications(state, delay_ms, serial_queue, block, NULL);
}

void AT_dispatch_coalesced_on_queue_with_notifications(ATCoalescedState *state, int64_t delay_ms, dispatch_queue_t serial_queue, ATCoalescedBlock block, ATCoalescedStateChangeNotificationBlock notificationBlock) {
    int64_t requests = OSAtomicIncrement64Barrier(state);
    if (requests != 1)
        return;

    if (notificationBlock)
        notificationBlock();

    void (^start_block)();
    start_block = ^{
        int64_t start = *state;
        block(^{
            if (!OSAtomicCompareAndSwap64Barrier(start, 0, state)) {
                dispatch_async(serial_queue, start_block);
            } else {
                if (notificationBlock)
                    notificationBlock();
            }
        });
    };

    AT_dispatch_after_ms_on_queue(delay_ms, serial_queue, start_block);
}
