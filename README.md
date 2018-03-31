# LANE
LÖVE animation editor

This tutorial is copied from my [devlog](http://pancakegames.sofapizza.de:4000).

The interface
---
![Interface](http://pancakegames.sofapizza.de:4000/assets/1/interface.png)

In the image above, you can see there are 5 distinct areas:
1. Spritesheet area
2. Timeline
3. Preview
4. Draw order
5. Properties

In a test setup, they might look like this:
![Interface](http://pancakegames.sofapizza.de:4000/assets/1/interface_filled.png)

Spritesheet area
---

The top-most buttons in the spritesheet are `Save` and `Load`. You can use these to save and load your finished project as `.ani` files (which is just serialized lua tables) and is very easy to import into your own project (we'll get to that later).

Clicking on the page icon will open a dialog, where you are prompted to locate the spritesheet that you would like to import into the editor. The sheet is then cut into a grid of size  `Frame width` * `Frame height`, which you can provide in the input fields below.

Timeline
---

In this area, one can add `keys`, which are visible in the Preview. Start by adding an animation by clicking on the page icon. You will be prompted to name that animation, e.g. `walking`. You can also delete and rename this animation with their respective trash can and ibeam icon.

In order to understand `keys` better, we will insert one into the preview window.

Preview
---

The preview is where the animations come to live. Select a row and column from the spritesheet by clicking on a part of the image and move your mouse into the preview area. The slice of the image will appear with a rectangle and a little greyed out - you can now place the slice by clicking the left mouse button. And voilà, a `key` appeared in the timeline!

Let's click on the name Sprite1 in the timeline and rename it to something reasonable... "Player".
Drag the timeline cursor, that is the blue indicator on the 0-second mark, by left clicking and holding. Let go, when it is at the 0.5-second mark. We can add another key to the same sprite by clicking the green + next to the "Player" text.

Properties
---

The properties window holds information about position, scale, rotation and the column/row that the frame is in the spritesheet. Select the key at the 0.5-second mark by either moving the timeline cursor to 0.5 seconds and clicking the image in the preview, or by clicking on the diamond in the timeline itself. Let's change the `column` property from `1` to `2` and -just for fun- the scale to `2` as well.

We're good to go! Let's start the animation, by hitting the play button in the timeline window. You should see the sprite changing in the preview area. You can export the animation by hitting save, or fiddle around some more. You can add more sprites by clicking into the spritesheet and then into the preview editor, change their draw order in the draw order area and just go ham with animations!


Hotkeys
---
The following hotkeys work globally:
- `p` Start/Pause playback
- `t` Stop playback

The following hotkeys work, if a key is selected:
- `c` Increase column property
- `w` Increase row property
- `a` Add a key at the current time
- `n` Jump to the next key of the current sprite
- `d` Delete a key

The following hotkeys work, if a key is selected and the mouse is in the preview window:
- `g` Grab and move key
- `r` Rotate key
- `s` Scale key
