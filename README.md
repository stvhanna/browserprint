# Browserprint
An open-source browser fingerprinting suite, inspired by the EFF's Panopticlick.

## Supported Tests
Browserprint implements the following tests:

### Monitor Contrast Level
A rough measure of the level of contrast of the monitor the browser is being displayed on.
Detected using a CAPTCHA with a couple of light grey letters that disappear when a monitor's contrast is sufficiently high.

### Colour Vision
[Test removed for ethics reasons. Last in commit 5858dd7]
Whether you have any issues seeing colour (note: this isn't necessarily correct and should be taken with a grain of salt).
Detected using a CAPTCHA with colour vision test plates (people with certain types of colour blindness see different numbers).

### User Agent
The User-Agent header sent with the HTTP request for the page.

### HTTP\_ACCEPT Headers
The concatenation of three headers from the HTTP request:
the Accept request header, the Accept-Encoding request header, and the Accept-Language request header.

### Platform (JavaScript)
The name of the platform the browser is running on, detected using JavaScript.

### Platform (Flash)
The name of the platform the browser is running on, detected using Flash.

### Browser Plugin Details
A list of the browsers installed plugins as detected using JavaScript.

### Time Zone
The time-zone configured on the client's machine.

### Screen Size and Color Depth
The screen size and colour depth of the monitor displaying the client's web browser.

### Screen Size (Flash)
The resolution of the client's monitor(s).
Different from the other screen size test in that this number can be the cumulative resolution of the monitors in multiple monitor set ups.

### Screen Size (CSS)
The screen size and colour depth of the monitor displaying the client's web browser, detected using CSS.
Deprecated because in the current implementation zooming changes the result in newer browsers.

### Language (Flash)
The language of the client's browser, as detected using Flash.

### System Fonts (Flash)
The fonts installed on the client's machine, detected using Flash.

### System Fonts (JS/CSS)
The fonts installed on the client's machine, detected using JavaScript.
Fonts list may be incomplete.

### System Fonts (CSS)
The fonts installed on the client's machine, detected using CSS without JavaScript.
Fonts list may be incomplete.
CSS font fingerprinting can be blocked by disabling CSS or by disabling JavaScript using the NoScript extension (despite the test not using JavaScript).

### Character Sizes
The height and width of a set of Unicode characters rendered at 2200pt with a variety of styles applied to them (e.g. sans-serif).
Different systems render these characters differently and this is one way to detect that without using a canvas.

### Are Cookies Enabled?
Whether cookies are enabled.

### Limited supercookie test
Three tests of whether DOM storage is supported (and enabled) in the client's web browser.
Tests for localStorage, sessionStorage, and Internet Explorer's userData.

### HSTS enabled?
HSTS is a web security enhancement that is used to make future connections to a domain exclusively HTTPS, not HTTP.
HSTS can be abused to store a super cookie on your machine that can then be used to track you, theoretically without even needing JavaScript.

### IndexedDB Enabled Test
Detects whether the browser supports IndexedDB, a database embedded within the browser.

### Do Not Track header
The value of the DNT (Do Not Track) header from the HTTP request.

### Client/server time difference (minutes)
The approximate amount of difference between the time on the client's computer and the clock on the server.
e.g., the clock on the client's computer is 5 minutes ahead of the clock on the server.

### Date/Time format test
When the JavaScript function toLocaleString() is called on a date it can reveal information about the language of the browser via the names of days and months.
For instance the output 'Thursday January 01, 10:30:00 GMT+1030 1970' reveals that English is our configured language because 'Thursday' is English.
Additionally different browsers tend to return differently formatted results.
For instance Opera returns the above whereas Firefox returns '1/1/1970 9:30:00 am' for the same date (UNIX epoch).
Additionally timezone information may be revealed.
For instance the above were taken on a computer configured for CST (+9:30), which is why the times shown aren't midnight.

### Math / Tan function
The same math functions run on different platforms and browsers can produce different results.
In particular we are interested in the output of Math.tan(-1e300), which has been observed to produce different values depending on operating system.
For instance on a 64bit Linux machine it produces the value -1.4214488238747245 and on a Windows machine it produces the value -4.987183803371025.

### Using Tor?
Checks whether a client's request came from a Tor exit node, and hence whether they're using Tor.
It does so by performing a TorDNSEL request for each client.

### Tor Browser Bundle version
The version of the Tor Browser Bundle (TBB) you are using (if you're using the TBB).

### Blocking Ads?
Checks whether ad blocking software is installed.
It does so by attempting to display 2 ads and trying to call a function from a script named like an ad serving script.
The Google ad may also be affected by tracker blocking software.

### Blocking like/share buttons?
Checks whether software is installed that blocks or modifies like or share buttons.
It does so by attempting to display 3 share buttons and checking if they're displayed properly.

### Canvas
Rendering of a specific picture with the HTML5 Canvas element following a fixed set of instructions.
The picture presents some slight noticeable variations depending on the OS and the browser used.

### WebGL Vendor
Name of the WebGL Vendor. Some browsers give the full name of the underlying graphics card used by the device.

### WebGL Renderer
Name of the WebGL Renderer. Some browsers give the full name of the underlying graphics driver.

### Touch Support
Primative touch screen detection.

### Audio Fingerprints
A set of fingerprinting tests that work using the AudioContext API.
Based on fingerprinting code from the wild.
