# OKColor.gml [![Donate](https://img.shields.io/badge/donate-%E2%9D%A4-blue.svg)](https://musnik.itch.io/donate-me) [![License](https://img.shields.io/github/license/KeeVeeGames/OKColor.gml)](#!)
<img align="left" src="https://keevee.games/wp-content/uploads/2023/11/logo-300x300.png" alt="Logo" width="150">

**OKColor** is a color management library for GameMaker written in pure GML that implements recently created new "industry standard" [OKLab](https://bottosson.github.io/posts/oklab/)/[OKLCH](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl) models and some others.

It's simple to use with only one `OKColor` class and a bunch of methods providing [setting the color](), [models conversion](), [mixing]() and [getting the color for rendering]().

Navigate to [Installation]() and [How to use]().

## Why to use?

### Premise

The problem with the standard RGB and HSV models is that they're not taking into consideration the human perception of the color, meaning that using the same rules of setting its component values will result in colors that are not *looking* like they were created that way.

For example, two colors that only differs in `hue`, won't be consistent for our eye and seems like they have different `saturation`/`value` also, despite having the same ones in the code. The `hue` itself is also not ideal: it distributes colors unevenly, meaning adding the same amount of hue to different colors won't "move" them to the same distance in the color wheel. To overcome these issues many attempts were made to create a perceptually correct color model with the most recent one being the "OK" family of color models.

OKLab is the parental starting point and is based on another perceptual model named CIELab fixing some of its flaws. OKLCH is another member of the family and just a representation of OKLab in a "cylindrical" form, meaning it has the same relation to OKLab as HSV has to RGB, acting as its better alternative. Where `L` represents `lightness` as the loose analogue of `value` in HSV, `C` is the `chroma` which is equal to `saturation` and `H` as in the `hue`.  

> [!NOTE]
> Provided examples may read incorrectly if you have a badly calibrated display and or non-trichromatic color vision.

Here is an example of a gradient generated with HSV model, all colors have the same `saturation` and `value` with all the possible `hue`s:

![figure_1_1_hsv_gradient](https://github.com/KeeVeeGames/OKColor.gml/assets/10993317/9489a697-3c70-4807-99c1-e3faeff79839)

And here is another one, generated with the *perceptually uniform* OKLCH model with the same `lightness` and `chroma` and different `hue` giving more consistent color, reflecting how human vision works:

![figure_1_2_oklch_gradient](https://github.com/KeeVeeGames/OKColor.gml/assets/10993317/b04bf7ce-a1c1-44b9-b8fe-39b75e650b45)

Notice how there are differences in lightness for different hues in the top one and how the hue itself is distributed unevenly.

Converting both examples to perceptual grayscale shows the lightness flaws more obviously:

![figure_1_3_hsv_gradient_grayscale](https://github.com/KeeVeeGames/OKColor.gml/assets/10993317/7c273b8d-2890-4233-bab1-72c0fb377989)
![figure_1_2_oklch_gradient_grayscale](https://github.com/KeeVeeGames/OKColor.gml/assets/10993317/6fd99282-6c9f-4bbb-bde6-bb43e9b1ff77)

### Generating new colors

Most of the time, the choice of specific colors in the game is made manually by the artist / art director but there're some cases when the color is needed to be generated on the fly because of the specifics of a particular visual effect, a huge number of assets that are needed to be altered or user-inputted customization. So, if you're generating color palettes for your game in-code and need consistent and predictable outcomes you should use this library with the perceptual color model.

#### Consistent matching colors

Let's say you want some features on your character sprite to be recolored in-game, you may generate a new palette with a basic `hue` shift in HSV space or use OKLCH model and `chroma` shift in there which will give you more appealing results:

![figure_1_4_character_palette](https://github.com/KeeVeeGames/OKColor.gml/assets/10993317/8fb9fc13-f448-4701-b177-2147f413bb55)

With OKLCH the lightness is consistent throughout all the hue changes, shadows and highlights don't disappear and colors themselves are more pleasing. This extends to all other components: you can be sure that colors with the same `chroma` will have the same perceptual hue, unlike HSV which tends to shift hue when brightness is changed (for example making blue become [more purple]() when increasing `value`).

#### Predictable different colors

Otherwise, if instead you *need* the difference in color qualities such as for better accessibility, a perceptual color model is also beneficial.

For example, you want to color-code different collectables: make blue one standard, green lighter and red darker to make it easier for unconscious distinction and accessible for color-blind people. You can generate three colors in HSV (note how the `value` drops by 10% for every next color to make it darker):

* Green: `hsv(120, 80%, 80%)`
* Blue: `hsv(180, 80%, 70%)`
* Red: `hsv(0, 80%, 60%)`

You can also generate three colors in OKLCH pretty much the same way, where `L` represents lightness, a loose analogue of value, `C` is chroma/saturation and `H` is hue (lightness is also decreased by 10% each time):

* Green: `oklch(75%, 0.18, 142)`
* Blue: `oklch(65%, 0.18, 202)`
* Red: `oklch(55%, 0.18, 27)`

And apply these colors to collectable sprite:

![figure_1_5_orbs](https://github.com/KeeVeeGames/OKColor.gml/assets/10993317/503a0915-285a-4266-8688-f5b21524cf71)&nbsp;
![figure_1_5_orbs_grayscale](https://github.com/KeeVeeGames/OKColor.gml/assets/10993317/d5c64c46-bae9-438c-b108-69a72044b9e1)


After testing you will see that the resulting colors for HSV are not predictable: red is much darker than needed, but green and blue look like they have the same brightness. OKLCH, on the other hand, is much more reasonable and complements the 10% change: every next color is equally darker than the previous.

> [!IMPORTANT]
> Crucial information necessary for users to succeed.

> [!WARNING]
> Critical content demanding immediate user attention due to potential risks.

```mermaid
graph TD;
    XYZ-->LinearRGB;
    LinearRGB-->RGB;
    RGB-->HSV;
    RGB-->HSL;
    XYZ-->Lab;
    Lab-->LCH;
    XYZ-->LMS;
    LMS-->OKLab;
    OKLab-->OKLCH;
```

## TODO:
* ### ["Missing" color components](https://www.w3.org/TR/css-color-4/#missing)
  * Useful for proper [color mixing](https://www.w3.org/TR/css-color-4/#interpolation-missing).
  * Treat as 0 outside of mixing purposes.
  * Use [NaN (powerless)]() as a missing component?
* ### [“Powerless” color components](https://www.w3.org/TR/css-color-4/#powerless)
  * Basically the color components that are not contributing to the resulting rendered color, like `hue` in HSV, when the `saturation` is 0: no matter what hue angle is, the resulting color will be grey.
  * [Already implemented]() as NaN for `hue` in HSV/HSL implementations, should probably be extended to `lightness` cases and LCH models.
  * Combine with "missing" as the same thing?
* ### Alpha and premultiplied alpha
  * More sensible color mixing with [alpha interpolation](https://www.w3.org/TR/css-color-4/#interpolation-alpha).
* ### Linear RGB color mixing
* ### Hue/Chroma interpolation for color mixing?
  * Not sure if it is needed as Lab and OKLab models provide the subjectively best-looking mixing and LCH to my understanding should give the same results as Lab, but may be useful for someone.
* ### Wider color gamuts like P3 and Rec.2020?
  * For now, the only supported color space used in [mapping the colors]() for the rendering is sRGB. With the introduction of a wider range [surface formats](https://manual.yoyogames.com/GameMaker_Language/GML_Reference/Drawing/Surfaces/surface_create.htm) in GameMaker it's probably possible now to render colors outside of 0-1 sRGB gamut on HDR monitors and this feature might be useful. Even without that, it still can be useful for passing a wider range colors in surface buffers for the sake of HDR lighting and rendering.
* ### More white points than D65?
  * D50 white point for XYZ for better consistency?
* ### HWB color model?
* ### Shader function equivalents of generating and mixing colors?

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
