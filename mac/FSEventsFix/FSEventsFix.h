/*
 * FSEventsFix
 *
 * Works around a long-standing bug in realpath() that prevents FSEvents API from
 * monitoring certain folders on a wide range of OS X releases (10.6-10.10 at least).
 *
 * The underlying issue is that for some folders, realpath() call starts returning
 * a path with incorrect casing (e.g. "/users/smt" instead of "/Users/smt").
 * FSEvents is case-sensitive and calls realpath() on the paths you pass in, so
 * an incorrect value returned by realpath() prevents FSEvents from seeing any
 * change events.
 *
 * See the discussion at https://github.com/thibaudgg/rb-fsevent/issues/10 about
 * the history of this bug and how this library came to exist.
 *
 * This library uses Facebook's fishhook to replace a custom implementation of
 * realpath in place of the system realpath; FSEvents will then invoke our custom
 * implementation (which does not screw up the names) and will thus work correctly.
 *
 * Our implementation of realpath is based on the open-source implementation from
 * OS X 10.10, with a single change applied (enclosed in "BEGIN WORKAROUND FOR
 * OS X BUG" ... "END WORKAROUND FOR OS X BUG").
 *
 * Include FSEventsFix.{h,c} into your project and call FSEventsFixInstall().
 *
 * You can check the installation result by reading FSEventsFix environment
 * variable. Possible values are:
 *
 * - (not set or empty string): not yet installed
 *
 * - "installed": successfully installed
 *
 * - "failed": installation or self-test failed
 *
 * - "unnecessary": the current version of OS X doesn't exhibit the bug (reserved for
 *   when Apple finally fixes the bug; not currently used)
 *
 * - "disabled": not used by the library, but if you set the variable to this value,
 *   the library will not be installed
 *
 * Please don't set FSEventsFix to any other values.
 *
 * See .c file for license & copyrights, but basically this is available under a mix
 * of MIT and BSD licenses.
 */

#ifndef FSEventsFixEnvVarName

#define FSEventsFixEnvVarName "FSEventsFix"
#define FSEventsFixEnvVarValueInstalled "installed"
#define FSEventsFixEnvVarValueFailed "failed"
#define FSEventsFixEnvVarValueUnnecessary "unnecessary"
#define FSEventsFixEnvVarValueDisabled "disabled"

void FSEventsFixInstall();

#endif
