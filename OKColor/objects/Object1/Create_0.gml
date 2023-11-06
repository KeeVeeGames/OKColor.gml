color1 = new OKColor().setOKLCH(0.5445, 0.205, 24.35);
color2 = new OKColor().setOKLCH(0.4496, 0.242, 265.76);
color3 = new OKColor().setOKLCH(0.4496, 0.242, 265.76);

// // color2 = new OKColor().setLinearRGB(0.5775804404, 0.1274376804, 0.3049873141);

show_debug_message(color1.getRGB());
show_debug_message(color3.getRGB());

surf1 = /*#cast*/ -1;    /// @is {surface}
surf2 = /*#cast*/ -1;    /// @is {surface}
surf3 = /*#cast*/ -1;    /// @is {surface}

// _segmentIntersection = function(x1, y1, x2, y2, x3, y3, x4, y4)->struct {
//     var top = (x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3);
//     var bottom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1);
//     var t = top / bottom;
    
//     return { x : lerp(x1, x2, t), y : lerp(y1, y2, t) };
// }

val = 0;

// var test1 = new Test();
// var test2 = new Test();

// test1.add();
// test2.add();
// test2.add();
// test2.add();

// show_debug_message(static_get(test1));
// show_debug_message(static_get(test2));
// show_debug_message(test1);
// show_debug_message(test2);