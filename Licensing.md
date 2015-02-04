Licensing Tools
===============

Build `LicensingTools` target in Xcode, then cd into the build products folder (Release configuration).

Generate licenses:

    ./LRLicenseGen 2 A 100 ~/Dropbox/LiveReload/Licensing/beta-2A-p0.txt
    ./LRLicenseGen 2 A 5000 ~/Dropbox/LiveReload/Licensing/beta-2A-p1.txt
    ./LRLicenseGen 2 A 5000 ~/Dropbox/LiveReload/Licensing/beta-2A-p2.txt
    ./LRLicenseGen 2 A 5000 ~/Dropbox/LiveReload/Licensing/beta-2A-p3.txt
    ./LRLicenseGen 2 A 5000 ~/Dropbox/LiveReload/Licensing/beta-2A-p4.txt
    ./LRLicenseGen 2 B 5000 ~/Dropbox/LiveReload/Licensing/beta-2B-p1.txt
    ./LRLicenseGen 2 B 5000 ~/Dropbox/LiveReload/Licensing/beta-2B-p2.txt
    ./LRLicenseGen 2 E 5000 ~/Dropbox/LiveReload/Licensing/beta-2E.txt

Add licenses to bloom filter (takes about ¼ second per license code; parallel processing recommended):

    ./LRLicenseBloomAdd ~/Dropbox/LiveReload/Licensing/beta-2A-p0.bloom ~/Dropbox/LiveReload/Licensing/beta-2A-p0.txt
    ./LRLicenseBloomAdd ~/Dropbox/LiveReload/Licensing/beta-2A-p1.bloom ~/Dropbox/LiveReload/Licensing/beta-2A-p1.txt
    ./LRLicenseBloomAdd ~/Dropbox/LiveReload/Licensing/beta-2A-p2.bloom ~/Dropbox/LiveReload/Licensing/beta-2A-p2.txt
    ./LRLicenseBloomAdd ~/Dropbox/LiveReload/Licensing/beta-2A-p3.bloom ~/Dropbox/LiveReload/Licensing/beta-2A-p3.txt
    ./LRLicenseBloomAdd ~/Dropbox/LiveReload/Licensing/beta-2A-p4.bloom ~/Dropbox/LiveReload/Licensing/beta-2A-p4.txt
    ./LRLicenseBloomAdd ~/Dropbox/LiveReload/Licensing/beta-2B-p1.bloom ~/Dropbox/LiveReload/Licensing/beta-2B-p1.txt
    ./LRLicenseBloomAdd ~/Dropbox/LiveReload/Licensing/beta-2B-p2.bloom ~/Dropbox/LiveReload/Licensing/beta-2B-p2.txt
    ./LRLicenseBloomAdd ~/Dropbox/LiveReload/Licensing/beta-2E.bloom ~/Dropbox/LiveReload/Licensing/beta-2E.txt

Merge bloom filters and save as a C header file:

    ./LRLicenseBloomEncode ~/dev/livereload/2/LiveReload/Classes/Licensing/LicensingBloomFilter.h ~/Dropbox/LiveReload/Licensing/*.bloom

Clean and rebuild `LicensingTools` after this step!

Verify that licenses work (this takes a long time as well, so stop when satisfied):

    ./LRLicenseVerify ~/Dropbox/LiveReload/Licensing/beta-2A-p0.txt

Verify that brute force searching does not result in any collisions quickly (pretty useless now that we're using PBKDF, but still good to know):

    ./LRLicenseCollision 2 A 10
