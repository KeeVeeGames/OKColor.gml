
// var gamutX = (mouse_x - 200) / 200;
// var gamutY = (mouse_y - 200) / 200;

// var whiteX = 0.31272;
// var whiteY = 0.32903;
// var redX = 0.64 - whiteX;
// var redY = 0.33 - whiteY;
// var greenX = 0.30 - whiteX;
// var greenY = 0.60 - whiteY;
// var blueX = 0.15 - whiteX;
// var blueY = 0.06 - whiteY;
// var whiteX = 0;
// var whiteY = 0;

// var gamutCrossGreen = (gamutX * greenY - gamutY * greenX);
// var gamutCrossRed = (gamutX * redY - gamutY * redX);
// var gamutCrossBlue = (gamutX * blueY - gamutY * blueX);

// var crossSide0 = ((redX * greenY - redY * greenX) * (redX * gamutY - redY * gamutX) >= 0) && (gamutCrossGreen * gamutCrossRed <= 0);
// var crossSide1 = ((greenX * blueY - greenY * blueX) * (greenX * gamutY - greenY * gamutX) >= 0) && (gamutCrossBlue * gamutCrossGreen <= 0);
// var crossSide2 = ((blueX * redY - blueY * redX) * (blueX * gamutY - blueY * gamutX) >= 0) && (gamutCrossRed * gamutCrossBlue <= 0);

// var intersection;

// if (crossSide0) {
//     intersection = _segmentIntersection(redX, redY, greenX, greenY, gamutX, gamutY, whiteX, whiteY);
// }
// else if (crossSide1) {
//     intersection = _segmentIntersection(greenX, greenY, blueX, blueY, gamutX, gamutY, whiteX, whiteY);
// }
// else if (crossSide2) {
//     intersection = _segmentIntersection(blueX, blueY, redX, redY, gamutX, gamutY, whiteX, whiteY);
// }

// draw_line(redX * 200 + 200, redY * 200 + 200, greenX * 200 + 200, greenY * 200 + 200);
// draw_line(greenX * 200 + 200, greenY * 200 + 200, blueX * 200 + 200, blueY * 200 + 200);
// draw_line(blueX * 200 + 200, blueY * 200 + 200, redX * 200 + 200, redY * 200 + 200);
// draw_line(gamutX * 200 + 200, gamutY * 200 + 200, whiteX * 200 + 200, whiteY * 200 + 200);

// draw_circle(intersection.x * 200 + 200, intersection.y * 200 + 200, 4, false);

// draw_text(redX * 200 + 200, redY * 200 + 200, $"RED {crossSide0}");
// draw_text(greenX * 200 + 200, greenY * 200 + 200, $"GREEN {crossSide1}");
// draw_text(blueX * 200 + 200, blueY * 200 + 200, $"BLUE {crossSide2}");

// draw_text(20, 20, string(point_direction(gamutX, gamutY, whiteX, whiteY)));

if (surface_exists(color2.debugSurf)) {
    draw_surface(color2.debugSurf, 200, 200);
}
        
if (!keyboard_check_pressed(vk_space)) {
    surface_free(surf1);
    surface_free(surf2);
    surface_free(surf3);
}

color2 = new OKColor().setOKLCH(mouse_x / 500, mouse_y / 500, 0);

if (!surface_exists(surf1)) {
    surf1 = surface_create(720, 80);

    surface_set_target(surf1);
    for (var i = 0; i < 360; i++) {
        var hue = i;
        // show_debug_message(hue);
        color1.setHSL(hue, mouse_y / 500, mouse_x / 500);
        var rgb = color1.colorRGB(OKColorMapping.Clip);
        // show_debug_message(rgb);
        draw_set_color(make_color_rgb(rgb.r, rgb.g, rgb.b));
        draw_rectangle(i * 2, 0, i * 2 + 1, 80, false);
    }
    surface_reset_target();
}

val += mouse_wheel_down() - mouse_wheel_up();

if (!surface_exists(surf2)) {
    surf2 = surface_create(720, 80);
    
    surface_set_target(surf2);
    draw_clear_alpha(c_black, 1);
    for (var i = val; i < val + 360; i++) {
        var h = (29.2338851923426 + i) % 360;
        color2.setOKLCH(, , h);
        var rgb = color2.colorRGB(OKColorMapping.Geometric);
        // show_debug_message(rgb);
        draw_set_color(make_color_rgb(rgb.r, rgb.g, rgb.b));
        draw_rectangle(i * 2, 0, i * 2 + 1, 80, false);
    }
    surface_reset_target();
}

if (!surface_exists(surf3)) {
    surf3 = surface_create(720, 80);
    
    surface_set_target(surf3);
    for (var i = 0; i < 360; i++) {
        var h = (29.2338851923426 + i) % 360;
        color2.setOKLCH(, , h);
        var rgb = color2.colorRGB(OKColorMapping.OKLCH);
        // var rgb = color2.getRGB();
        // show_debug_message(rgb);
        draw_set_color(make_color_rgb(rgb.r, rgb.g, rgb.b));
        draw_rectangle(i * 2, 0, i * 2 + 1, 80, false);
    }
    surface_reset_target();
}

draw_surface(surf1, 600, 100);
draw_surface(surf2, 600, 180);
draw_surface(surf3, 600, 260);

draw_rectangle(0, 0, 500, 500, true);