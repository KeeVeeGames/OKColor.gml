# OKColor.gml [![Donate](https://img.shields.io/badge/donate-%E2%9D%A4-blue.svg)](https://musnik.itch.io/donate-me) [![License](https://img.shields.io/github/license/KeeVeeGames/OKColor.gml)](#!)
<img align="left" src="https://keevee.games/wp-content/uploads/2023/11/logo-300x300.png" alt="Logo" width="150">

**OKColor** is a color management library for GameMaker written in pure GML that implements the new "industry standard" [OKLab](https://bottosson.github.io/posts/oklab/)/[OKLCH](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl) models, among others.

It's simple to use with only one [`OKColor`](https://github.com/KeeVeeGames/OKColor.gml/wiki/API-Reference) class and a bunch of methods providing [setting the color](https://github.com/KeeVeeGames/OKColor.gml/wiki/API-Reference#setters), [models conversion](https://github.com/KeeVeeGames/OKColor.gml/wiki/API-Reference#getters), [mixing](https://github.com/KeeVeeGames/OKColor.gml/wiki/API-Reference#mixing) and [getting the color for rendering](https://github.com/KeeVeeGames/OKColor.gml/wiki/API-Reference#color-getters).

Navigate to [Installation](https://github.com/KeeVeeGames/OKColor.gml/tree/main#installation) and [How to use](https://github.com/KeeVeeGames/OKColor.gml/tree/main#how-to-use).

## Why to use?

### Premise

The problem with the standard RGB and HSV models is that they're not taking into consideration the human perception of the color. That means that if you follow the same rules to set the color components, the resulting colors might not *look* like these rules were followed.

For example, if two colors only differ in `hue`, they won't be consistent for our eyes and seems like they also have different `saturation`/`value`, despite having the same ones in the code. The `hue` itself is not perfect either: it distributes colors unevenly, so adding the same amount of hue to different colors won't make them "move" the same distance in the color wheel. To overcome these issues, there have been attempts to create a perceptually correct color model with the most recent one being the "OK" family of color models.

OKLab is the starting point of it and is inspired by a perceptual model called CIELab, fixing some of its flaws. OKLCH is another member of the family and just a representation of OKLab in a "cylindrical" form, meaning it has the same relation to OKLab as HSV has to RGB. So OKLCH is a better alternative to HSV, where `L` represents `lightness` as the loose analogue of `value`, `C` is the `chroma` which is equal to `saturation` and `H` as in the `hue`.  

> [!NOTE]
> Provided examples may read incorrectly if you have a badly calibrated display and or non-trichromatic color vision.

Here is an example of a gradient generated with HSV model, all colors have the same `saturation` and `value` and showing all the possible `hue`:

![figure_1_1_hsv_gradient](https://github.com/KeeVeeGames/OKColor.gml/assets/10993317/923cbbe4-0767-48a3-9886-b9ac327c315c)

And here is another one, generated with the *perceptually uniform* OKLCH model with the same `lightness` and `chroma` and different `hue` giving more consistent color, reflecting how human vision works:

![figure_1_2_oklch_gradient](https://github.com/KeeVeeGames/OKColor.gml/assets/10993317/16a83072-ba7d-40e0-aac5-cfb4a96d240c)

Notice how there are differences in lightness for different hues in the top one and how the hue itself is distributed unevenly.

Converting both examples to perceptual grayscale shows the lightness flaws more obviously:

![figure_1_3_hsv_gradient_grayscale](https://github.com/KeeVeeGames/OKColor.gml/assets/10993317/72a7efd0-8fb3-4c34-8943-b1c5b55ee62c)
![figure_1_2_oklch_gradient_grayscale](https://github.com/KeeVeeGames/OKColor.gml/assets/10993317/41f385fc-6c22-43f9-8f25-085d058d5689)

### Generating new colors

Usually, the choice of specific colors in the game is made manually by the game artists or art directors. However, there are some cases where colors need to be generated dynamically. This could be due to the specifics of a particular visual effect, a large number of assets requiring recolor or user-inputted customization. So, if you're generating color palettes for your game in-code and need consistent and predictable outcomes you should consider using this library with the perceptual color model (preferably OKLCH) instead of standard `make_color_rgb` and `make_color_hsv`.

> [!NOTE]
> You can use this OKLCH color picker to choose reference colors: [oklch.com](https://oklch.com/). Uncheck **"Show P3"** colors too see only sRGB colors that GameMaker rendering supports.

#### Consistent matching colors

Let's say you want to recolor specific features of your character sprite in-game. One way is to generate a new palette using a basic `hue` shift in the HSV space. Another option is to use the OKLCH model and apply a `hue` shift there. This latter approach often provides more appealing results:

![figure_1_4_character_palette](https://github.com/KeeVeeGames/OKColor.gml/assets/10993317/f547f063-48c1-442b-9db4-fd982cb91fc9)

With OKLCH the lightness is consistent throughout all the hue changes, shadows and highlights remain intact, and the overall visual is enhanced. This extends to other components: you can be sure that colors with the same `hue` will have the same perceptual hue, unlike HSV which tends to shift it when brightness is changed (for example making blue become [more purple]() when increasing `value`).

#### Predictable different colors

Otherwise, if instead you *need* the difference in color qualities such as for better accessibility, a perceptual color model is also beneficial.

For example, you want to color-code different collectables: blue one is standard, green is lighter and red is darker to make it easier for subconscious distinction and more accessible for color-blind people. You can generate the colors in HSV (note how the `value` drops by 10% for every next color to make it darker):

| HSV | hue | saturation | value |
| - | - | - | - |
| **green** | 120 | 80% | 90% |
| **blue** | 180 | 80% | 80% |
| **red** | 0 | 80% | 70% |

You can also generate three colors with OKLCH in a similar way (`lightness` is also decreased by 10% each time):

| OKLCH | lightness | chroma | hue |
| - | - | - | - |
| **green** | 75% | 0.18 | 142 |
| **blue** | 65% | 0.18 | 202 |
| **red** | 55% | 0.18 | 27 |

And apply these colors to a collectable sprite:

![figure_1_5_orbs](https://github.com/KeeVeeGames/OKColor.gml/assets/10993317/2f2acefc-5463-423a-969c-e6dd81dff3da)&nbsp;
![figure_1_5_orbs_grayscale](https://github.com/KeeVeeGames/OKColor.gml/assets/10993317/b350d477-0a76-424a-a316-76e91517dee3)

Testing would reveal that HSV results are not predictable: with the red appearing much darker than intended, and green and blue seemingly having similar brightness. OKLCH, on the other hand, provides more consistent and reasonable results, with each subsequent color being equally darker than the previous one, complementing the 10% change.

#### Palettes for GUI

Aside from actual gameplay graphics, OKLCH is valuable for generating colors for elements initially colored in code, such as text and GUI elements. It's not without reason that this model is emerging as a new standard for CSS. With it, you can define a formula, choose a few colors, and automatically generate an entire design system palette.

You can learn more on that here:  
https://stripe.com/blog/accessible-color-systems  
https://huetone.ardov.me/

### Mixing the colors

Perceptual models can be also beneficial when generating gradients or blending colors gradually over time. GameMaker's `merge_color` uses RGB model to mix colors and may suffer from the same disadvantages of unpredictable color qualities, non-linear distribution and component shifts. OKColor offers additional methods for mixing colors perceptually using Lab and OKLab models.

> [!IMPORTANT]
> Color mixing is a peculiar case. While it's almost universally better to use the advanced OKLab/OKLCH model for generating new colors, blending colors can perform better with a simpler Lab/LCH model or even the standard RGB for certain requirements. Make your decision based on tests with your specific colors and/or provided examples.

Here are some examples of gradients created in RGB, OKLab and Lab:

![figure_1_6_red_green_gradient](https://github.com/KeeVeeGames/OKColor.gml/assets/10993317/54a412c9-1e93-4e11-8971-3ad252e0a066)&nbsp;
![figure_1_7_aqua_gred_gradient](https://github.com/KeeVeeGames/OKColor.gml/assets/10993317/5ea8d41f-2c69-41b2-a359-19b1308885ae)

Take a look at how RGB produces ugly grayish colors in the middle, whereas perceptual models yield more consistent results. The Lab variant can also provide a bit more saturation.

![figure_1_8_green_purple_gradient](https://github.com/KeeVeeGames/OKColor.gml/assets/10993317/1415165f-31ad-4a00-9c8e-a2a2437dbc72)&nbsp;
![figure_1_9_blue_yellow_gradient](https://github.com/KeeVeeGames/OKColor.gml/assets/10993317/3df8bbee-5ba0-40c2-a47c-3e952445ccae)

When dealing with colors that are fairly distant from each other on the hue wheel, Lab introduces a hue shift that is not present in OKLab. However, you can use it if it aligns with your requirements for mixing while moving along the hue.

![figure_1_10_blue_white_gradient](https://github.com/KeeVeeGames/OKColor.gml/assets/10993317/5291ea92-e3cd-42cc-a55b-fb624eca7bd3)&nbsp;
![figure_1_11_black_white_gradient](https://github.com/KeeVeeGames/OKColor.gml/assets/10993317/5507afb0-981f-4c26-9ed3-e1d09aba66ab)

Gradients that transition to white exhibit significant hue shifts for some colors, as shown in this example, which is usually unnecessary. In such cases, OKLab should be preferred. The black and white variant also highlights the difference in the linear distribution of OKLab and the non-linearity of RGB and Lab.

## Installation

Copy the [OKColor](https://github.com/KeeVeeGames/OKColor.gml/blob/main/OKColor/scripts/OKColor/OKColor.gml) script into your project.   
Or get the latest asset package from the [releases page](https://github.com/KeeVeeGames/OKColor.gml/releases) and import it into IDE.

## How to use

The basic using is pretty simple and straightforward. To create a new color, use the `OKColor` constructor to create a new instance and set the color with a wide choice of [setter methods](https://github.com/KeeVeeGames/OKColor.gml/wiki/API-Reference#setters).

```js
var okcolor = new OKColor().setColor(#3f97d8);
```

Method chaining and optional arguments for setting components separately are also supported so you can do:

```js
var okcolor = new OKColor().setColor(#3f97d8).setOKLCH(, , 120);
```

You can convert colors to other model with [getter functions](https://github.com/KeeVeeGames/OKColor.gml/wiki/API-Reference#getters):

```js
var hsv = okcolor.getHSV();

show_debug_message($"hue: {hsv.h}, saturation: {hsv.s}, value: {hsv.v}");
```

[Mixing colors](https://github.com/KeeVeeGames/OKColor.gml/wiki/API-Reference#mixing) works like `merge_color` / `lerp`:

```js
var okcolor1 = new OKColor().setColor(#3f97d8).setOKLCH(, , 120);
var okcolor2 = new OKColor().setRGB(242,42,133);

var newcolor = okcolor1.mix(okcolor2, 0.5);
```

To get color for rendering you should use [color getter methods](https://github.com/KeeVeeGames/OKColor.gml/wiki/API-Reference#color-getters):

```js
var okcolor = new OKColor().setColor(#3f97d8).setOKLCH(, , 120);

draw_set_color(okcolor.color());
```

For deep info on extended functionality about setters, getters, mixing, gamut mapping, and other check out the next section.

## More info

* **[API Reference](https://github.com/KeeVeeGames/OKColor.gml/wiki/API-Reference)**
  * [Setters](https://github.com/KeeVeeGames/OKColor.gml/wiki/API-Reference#setters)
  * [Getters](https://github.com/KeeVeeGames/OKColor.gml/wiki/API-Reference#getters)
  * [Color Getters](https://github.com/KeeVeeGames/OKColor.gml/wiki/API-Reference#color-getters)
  * [Gamut Mapping](https://github.com/KeeVeeGames/OKColor.gml/wiki/API-Reference#gamut-mapping)
  * [Mixing](https://github.com/KeeVeeGames/OKColor.gml/wiki/API-Reference#mixing)
  * [Cloning](https://github.com/KeeVeeGames/OKColor.gml/wiki/API-Reference#cloning)
* **[Architecture](https://github.com/KeeVeeGames/OKColor.gml/wiki/Architecture)**
* **[How to contribute](https://github.com/KeeVeeGames/OKColor.gml/blob/main/CONTRIBUTING.md)**

## TODO:
* **["Missing" color components](https://www.w3.org/TR/css-color-4/#missing)**
  * Useful for proper [color mixing](https://www.w3.org/TR/css-color-4/#interpolation-missing).
  * Treat as 0 outside of mixing purposes.
  * Use [NaN (powerless)]() as a missing component?
* **[“Powerless” color components](https://www.w3.org/TR/css-color-4/#powerless)**
  * Basically the color components that are not contributing to the resulting rendered color, like `hue` in HSV, when the `saturation` is 0: no matter what hue angle is, the resulting color will be grey.
  * [Already implemented]() as NaN for `hue` in HSV/HSL implementations, should probably be extended to `lightness` cases and LCH models.
  * Combine with "missing" as the same thing?
* **Alpha and premultiplied alpha**
  * More sensible color mixing with [alpha interpolation](https://www.w3.org/TR/css-color-4/#interpolation-alpha).
* **Linear RGB color mixing**
* **Hue/Chroma interpolation for color mixing?**
  * Not sure if it is needed as Lab and OKLab models provide the subjectively best-looking mixing and LCH to my understanding should give the same results as Lab, but may be useful for someone.
* **Wider color gamuts like P3 and Rec.2020?**
  * For now, the only supported color space used in [mapping the colors]() for the rendering is sRGB. With the introduction of a wider range [surface formats](https://manual.yoyogames.com/GameMaker_Language/GML_Reference/Drawing/Surfaces/surface_create.htm) in GameMaker it's probably possible now to render colors outside of 0-1 sRGB gamut on HDR monitors and this feature might be useful. Even without that, it still can be useful for passing a wider range colors in surface buffers for the sake of HDR lighting and rendering.
* **More white points than D65?**
  * D50 white point for XYZ for better consistency?
* **HWB color model?**
* **Shader function equivalents of generating and mixing colors?**

## Author:
Nikita Musatov - [MusNik / KeeVee Games](https://twitter.com/keeveegames)

## References
Sitnik, A. and Turner, T. (2022) "[OKLCH in CSS: why we moved from RGB and HSL](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl)"  
Ottosson, Björn (2020) "[A perceptual color space for image processing](https://bottosson.github.io/posts/oklab/)"  
Ottosson, Björn (2020) "[How software gets color wrong](https://bottosson.github.io/posts/gamutclipping/)"  
Ottosson, Björn (2021) "[sRGB gamut clipping](https://bottosson.github.io/posts/oklab/)"  
Cereda, M., Plutino, A. and Rizzi A. (2021) "[Quick Gamut mapping for simplified color correction](https://jcolore.gruppodelcolore.it/ojs/index.php/CCSJ/article/view/CCSJ.130209)", University of Milan  
Morovič, Ján (2008) "[Color gamut mapping](https://onlinelibrary.wiley.com/doi/book/10.1002/9780470758922)", Chapter 10, John Wiley & Sons  
Schanda, J. (2007) "[Colorimetry: understanding the CIE system"](https://onlinelibrary.wiley.com/doi/book/10.1002/9780470175637), Chapter 3, John Wiley & Sons  
Fairchild, Mark D. (2013) "[Color Appearance Models](https://onlinelibrary.wiley.com/doi/book/10.1002/9781118653128), John Wiley & Sons  
Verou, Lea and Lilley, Chris (2023) "[Color.js](https://github.com/LeaVerou/color.js)"  
Atkins Jr., T., Lilley, C., Verou, L., and Baron, D. (2021) "[CSS Color Module Level 4](https://www.w3.org/TR/css-color-4/)", W3C  
Lilley, C., Kravets, U., Verou, L., and Argyle, A. (2022) "[CSS Color Module Level 5](https://www.w3.org/TR/css-color-5/)", W3C  
Levien, Raph (2021) "[An interactive review of Oklab](https://raphlinus.github.io/color/2021/01/18/oklab-critique.html)"
