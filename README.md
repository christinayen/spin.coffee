Converted Felix Gnass' spin.js to CoffeeScript (Source: http://fgnass.github.com/spin.js/)

## Changes:
* plugin now fully relies on jQuery. I removed some helper-functions like merge() and css() because jQuery already has them.
* included a jQuery-Extension on top of the script
* changed the markup. spinner-div is now behind the target element, not in it.
* 4 new options for the jQuery-Extension:
  * hide: true (hides the target element as long as the spinner is spinning.)
  * offsetX: int (integer for x offset)
  * offsetY: int (integer for y offset)
  * preset: ['small', 'standard', 'large']
* $(target).spin('stop') stops the spinner. I found .spin(false) syntactically hard to remember ;)


## Todo
* Refactor IE-Part of the script (no need so far)
* insert() could probably refactored to use jQuery's own DOM-Insertion methods $(a).after() or $(a).append()
