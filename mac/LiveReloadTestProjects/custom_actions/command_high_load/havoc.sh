#!/bin/bash
for ((i = 0; i < 10; ++i)); do
    cat bootstrap.less >bootstrap-$RANDOM.less
done
