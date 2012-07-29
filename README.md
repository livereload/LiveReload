# DMTabBar

DMTabBar is a XCode 4.x like segmented control. It's emulate the behavior of the segmented control used inside XCode's Inspector Window.

Daniele Margutti, <http://www.danielem.org>

![DMTabBar Example Project](http://danielemargutti.com/wp-content/uploads/2012/06/DMTabBar.png)

## How to get started

It's very simple to use:
* make your DMTabBar class via code (it's an NSView subclass) or via IB
* create an NSArray of DMTabBarItems elements and assign it to DMTabBar tabBarItems property. Each item is a button and can have several attributes (you can simply set the NSImage's icon property)
* handle selection changes using - (void) handleTabBarItemSelection:(DMTabBarEventsHandler) selectionHandler; method.

It uses ARC and blocks so you it should be compatible with MacOS X 10.6 or later.

## Change log

### June 19, 2012

* First version

## Donations

If you found this project useful, please donate.
There’s no expected amount and I don’t require you to.

<a href='https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=GS3DBQ69ZBKWJ">CLICK THIS LINK TO DONATE USING PAYPAL</a>

## License (MIT)

Copyright (c) 2012 Daniele Margutti

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
