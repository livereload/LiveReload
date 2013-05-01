# How to change LiveReload's port number

Applies to: LiveReload 2.3.26+

By default, LiveReload app listens on port 35729, and does not officially support changing the port number.

However, **if you know what you're doing**, you can override the port number using a hidden setting.

## Method A: using HttpPort preference

To use 3001 as the listening port (for browser connections):

1.  Quit LiveReload app

2.  Launch Terminal app

3.  Run (paste and press Enter): `defaults write com.livereload.LiveReload HttpPort 3001`

4.  Restart LiveReload app

5.  Verify that it's using the new port number (see below)

To undo the override and revert to the default port:

1.  Quit LiveReload app

2.  Launch Terminal app

3.  Run (paste and press Enter): `defaults delete com.livereload.LiveReload HttpPort`

4.  Restart LiveReload app

5.  Verify that it's using the default port number (see below)

## Method B: using LRPortOverride env var

If you want to run multiple instances of LiveReload on different ports, or if you're running LiveReload from Xcode, or doing something equally crazy, you may find this method appealing. Just set e.g. LRPortOverride=3001 in your environment variables when launching LiveReload (I assume you know how to do it). This is not a permanent change, so no reverting instructions.

## Verifying that LiveReload uses the correct port

Check the snippet displayed in the main LiveReload window; it should show the port number you have set:

![](http://assets.livereload.com/docs/LiveReload-port-override-in-snippets.png)

## Browser extensions always use port 35729

You cannot change the port number in the browser extensions. If you use an alternative port in the LiveReload app, the JavaScript snippet in your only integration option.
