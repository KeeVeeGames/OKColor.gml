
// if (surface_exists(color2.debugSurf)) {
//     draw_surface(color2.debugSurf, 200, 200);
// }
        
if (!keyboard_check_pressed(vk_space)) {
    surface_free(surf1);
    surface_free(surf2);
    surface_free(surf3);
    
    color2 = new OKColor().setOKLCH(mouse_x / 500, mouse_y / 500, 0);
}

// color2 = new OKColor().setOKLCH(mouse_x / 500, mouse_y / 500, 0);

if (!surface_exists(surf1)) {
    surf1 = surface_create(720, 80);

    surface_set_target(surf1);
    for (var i = 0; i < 360; i++) {
        var hue = i;
        // show_debug_message(hue);
        // color1.setHSV(hue, mouse_y / 500, mouse_x / 500);
        // color1 = new OKColor().setOKLCH(mouse_x / 500, mouse_y / 500, 0);
        // color3 = new OKColor().setOKLCH(mouse_x / 500, mouse_y / 500, 250);
        color1 = new OKColor().setColor(#FF4576);
        color3 = new OKColor().setColor(#45FF76);
        // var color = color1.color();
        var color = color1.mix(color3, i / 360).color();
        // show_debug_message(rgb);
        draw_set_color(color);
        draw_rectangle(i * 2, 0, i * 2 + 1, 80, false);
    }
    surface_reset_target();
}

val += mouse_wheel_down() - mouse_wheel_up();

if (!surface_exists(surf2)) {
    surf2 = surface_create(720, 80);
    
    // surface_set_target(surf2);
    // draw_clear_alpha(c_black, 1);
    // for (var i = val; i < val + 360; i++) {
    //     var h = (29.2338851923426 + i) % 360;
    //     color2.setOKLCH(, , h);
    //     var rgb = color2.colorRGB(OKColorMapping.Chroma);
    //     // show_debug_message(rgb);
    //     draw_set_color(make_color_rgb(rgb.r, rgb.g, rgb.b));
    //     draw_rectangle(i * 2, 0, i * 2 + 1, 80, false);
    // }
    // surface_reset_target();
}

if (!surface_exists(surf3)) {
    surf3 = surface_create(720, 80);
    
    // surface_set_target(surf3);
    // for (var i = 0; i < 360; i++) {
    //     var h = (29.2338851923426 + i) % 360;
    //     color2.setOKLCH(, , h);
    //     var rgb = color2.colorRGB(OKColorMapping.OKChroma);
    //     // var rgb = color2.getRGB();
    //     // show_debug_message(rgb);
    //     draw_set_color(make_color_rgb(rgb.r, rgb.g, rgb.b));
    //     draw_rectangle(i * 2, 0, i * 2 + 1, 80, false);
    // }
    // surface_reset_target();
}

draw_surface(surf1, 600, 100);
// draw_surface(surf2, 600, 180);
// draw_surface(surf3, 600, 260);

draw_set_color(c_white);
draw_rectangle(0, 0, 500, 500, true);