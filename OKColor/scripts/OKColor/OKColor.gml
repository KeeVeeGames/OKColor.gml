#macro OKCOLOR_WARNINGS 1

enum _OKColorModel {
    gmcolor,
    string,
    RGB,
    LinearRGB,
    HSV,
    HSL,
    LMS,
    Lab,
    LCH,
    OKLab,
    OKLCH,
    _sizeof
}

enum OKColorMapping {
    Clip,
    Geometric,
    Chroma,
    OKChroma,
    _sizeof
}

function OKColor() constructor {
    _x = 0;
    _y = 0;
    _z = 0;
    
    _cache = array_create(_OKColorModel._sizeof);
    _cache[_OKColorModel.gmcolor] = { cached : true, value : #000000 };
    _cache[_OKColorModel.string] = { cached : true, value : "#000000" };
    _cache[_OKColorModel.RGB] = { cached : true, r : 0, g : 0, b : 0 };
    _cache[_OKColorModel.LinearRGB] = { cached : true, r : 0, g : 0, b : 0 };
    _cache[_OKColorModel.HSV] = { cached : true, h : 0, s : 0, v : 0 };
    _cache[_OKColorModel.HSL] = { cached : true, h : 0, s : 0, v : 0 };
    _cache[_OKColorModel.LMS] = { cached : true, l : 0, m : 0, s : 0 };
    _cache[_OKColorModel.Lab] = { cached : true, l : 0, a : 0, b : 0 };
    _cache[_OKColorModel.LCH] = { cached : true, l : 0, c : 0, h : 0 };
    _cache[_OKColorModel.OKLab] = { cached : true, l : 0, a : 0, b : 0 };
    _cache[_OKColorModel.OKLCH] = { cached : true, l : 0, c : 0, h : 0 };
    
    _gamutMapping = array_create(OKColorMapping._sizeof);
    _gamutMapping[OKColorMapping.Clip] = _mapGamutRGBClip;
    _gamutMapping[OKColorMapping.Geometric] = _mapGamutRGBGeometric;
    _gamutMapping[OKColorMapping.Chroma] = _mapGamutRGBChroma;
    _gamutMapping[OKColorMapping.OKChroma] = _mapGamutRGBOKChroma;
    
    _gamutMappingDefault = OKColorMapping.OKChroma;
    
    debugSurf = /*#cast*/ -1 /*#as surface*/;
    
    #region Private
    
    static _whitepointX = 0.3127;
    static _whitepointY = 0.3290;
    static _whitepoint = { x : _whitepointX / _whitepointY, y : 1, z : (1 - _whitepointX - _whitepointY) / _whitepointY };
    
    static _setDirty = function() {
        for (var i = 0; i < _OKColorModel._sizeof; i++) {
            _cache[i].cached = false;
        }
    }
    
    static _gamutSegmentIntersection = function(x1, y1, x2, y2, x3, y3, x4, y4)/*->struct*/ {
        var top = (x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3);
        var bottom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1);
        var t = top / bottom;
        
        if (t < 0) return { x : x1, y : y1 };
        if (t > 1) return { x : infinity, y : infinity };
        
        return { x : lerp(x1, x2, t), y : lerp(y1, y2, t) };
    }
    
    static _gamutPointOnSegment = function(px, py, x1, y1, x2, y2)/*->bool*/ {
        var t1 = (px - x1) / (x2 - x1);
        var t2 = (py - y1) / (y2 - y1);
        
        return t1 == t2 && t1 >= 0 && t1 <= 1 && t2 >= 0 && t2 <= 1;
    }
    
    static _gamutReduceComponent = function(componentValue/*:number*/, componentSetter/*:function<number, void>*/)/*->struct*/ {
        var jnd = 0.02;             // "just noticable difference"
        var epsilon = 0.0001;
        var minComponent = 0;
        var maxComponent = componentValue;
        var minInGamut = true;
        
        static _gamutWorkingColor = new OKColor();
        static _gamutClippedColor = new OKColor();
        
        _gamutWorkingColor.setXYZ(_x, _y, _z);
        var workingRGB = _gamutWorkingColor.getRGB();
        var clippedRGB = _gamutClipRGB(workingRGB);
        _gamutClippedColor.setRGB(clippedRGB.r, clippedRGB.g, clippedRGB.b);
        
        var deltaE = _deltaEOKLab(_gamutClippedColor.getOKLab(), _gamutWorkingColor.getOKLab());
        if (deltaE < jnd) return { r : clippedRGB.r, g : clippedRGB.g, b : clippedRGB.b };
        
        while (maxComponent - minComponent > epsilon) {
            var component = (minComponent + maxComponent) / 2;
            method(_gamutWorkingColor, componentSetter)(component);
            workingRGB = _gamutWorkingColor.getRGB();
            
            if (minInGamut && _inGamutRGB(workingRGB)) {
                minComponent = component;
            } else {
                clippedRGB = _gamutClipRGB(workingRGB);
                deltaE = _deltaEOKLab(_gamutClippedColor.getOKLab(), _gamutWorkingColor.getOKLab());
                
                if (deltaE < jnd) {
                    if (jnd - deltaE < epsilon) {
                        return { r : clippedRGB.r, g : clippedRGB.g, b : clippedRGB.b };
                    } else {
                        minInGamut = false;
                        minComponent = component;
                    }
                } else {
                    maxComponent = component;
                }
            }
        }
        
        return { r : clippedRGB.r, g : clippedRGB.g, b : clippedRGB.b };
    }
    
    static _inGamutRGB = function(rgb/*:struct*/) {
        return (rgb.r >= 0 && rgb.r <= 255)
        && (rgb.g >= 0 && rgb.g <= 255)
        && (rgb.b >= 0 && rgb.b <= 255);
    }
    
    static _gamutClipRGB = function(rgb/*:struct*/)/*->struct*/ {
        return {
            r : clamp(rgb.r, 0, 255),
            g : clamp(rgb.g, 0, 255),
            b : clamp(rgb.b, 0, 255)
        };
    }
    
    static _deltaEOKLab = function(oklab1/*:struct*/, oklab2/*:struct*/)/*->number*/ {
        var delta_l = oklab1.l - oklab2.l;
        var delta_a = oklab1.a - oklab2.a;
        var delta_b = oklab1.b - oklab2.b;
        return sqrt(delta_l * delta_l + delta_a * delta_a + delta_b * delta_b);
    }
    
    static _componentRGBtoLinearRGB = function(component/*:number*/)/*->number*/ {
        component /= 255;
        
        if (component >= 0.04045) {
            return power((component + 0.055) / 1.055, 2.4);
        } else {
            return component / 12.92;
        }
    }
    
    static _componentLinearRGBtoRGB = function(component/*:number*/)/*->number*/ {
        if (component >= 0.0031308) {
            return (1.055 * power(component, 1.0 / 2.4) - 0.055) * 255;
        } else {
            return component * 12.92 * 255;
        }
    }
    
    static _piecewiseHSVtoRGB = function(n/*:number*/, hsv/*:struct*/)/*->number*/ {
        var h = hsv.h;
        var s = hsv.s;
        var v = hsv.v;
        
        var k = (n + h / 60) % 6;
        
        return v - v * s * max(0, min(k, 4 - k, 1));
    }
    
    static _piecewiseHSLtoRGB = function(n/*:number*/, hsl/*:struct*/)/*->number*/ {
        var h = hsl.h;
        var s = hsl.s;
        var l = hsl.l;
        
        var k = (n + h / 30) % 12;
        var a = s * min(l, 1 - l);
        
        return l - a * max(-1, min(k - 3, 9 - k, 1));
    }
    
    static _updateXYZfromLab = function(lab/*:struct*/) {
        var epsilon = 24/116;
        var k = 24389/27;
        
        var fY = (lab.l + 16) / 116;
        var fX = (lab.a / 500) + fY;
        var fZ = fY - lab.b / 200;
        
        _x = fX > epsilon ? power(fX, 3) * _whitepoint.x : (116 * fX - 16) / k * _whitepoint.x;
        _y = lab.l > 8 ? power(fY, 3) * _whitepoint.y : lab.l / k * _whitepoint.y;
        _z = fZ > epsilon ? power(fZ, 3) * _whitepoint.z : (116 * fZ - 16) / k * _whitepoint.z;
    }
    
    static _matrixXYZtoLinearRGB = [
        3.2409699419045226, -0.9692436362808796, 0.0556300796969936, 0,
        -1.5373831775700939, 1.8759675015077204, -0.2039769588889765, 0,
        -0.4986107602930034, 0.0415550574071756, 1.0569715142428784, 0,
        0, 0, 0, 1
    ];
    
    static _matrixLinearRGBtoXYZ = [
        0.4123907992659593, 0.2126390058715102, 0.0193308187155918, 0,
        0.3575843393838780, 0.7151686787677560, 0.1191947797946260, 0,
        0.1804807884018343, 0.0721923153607337, 0.9505321522496607, 0,
        0, 0, 0, 1
    ];
    
    static _matrixXYZtoLMS = [
        0.8190224432164319, 0.0329836671980271, 0.048177199566046255, 0,
        0.3619062562801221, 0.9292868468965546, 0.26423952494422764, 0,
        -0.12887378261216414, 0.03614466816999844, 0.6335478258136937, 0,
        0, 0, 0, 1
    ];
    
    static _matrixLMStoXYZ = [
        1.2268798733741557, -0.04057576262431372, -0.07637294974672142, 0,
        -0.5578149965554813, 1.1122868293970594, -0.4214933239627914, 0,
        0.28139105017721583, -0.07171106666151701, 1.5869240244272418, 0,
        0, 0, 0, 1
    ];
    
    static _matrixLMStoOKLab = [
        0.2104542553, 1.9779984951, 0.0259040371, 0,
        0.7936177850, -2.4285922050, 0.7827717662, 0,
        -0.0040720468, 0.4505937099, -0.8086757660, 0,
        0, 0, 0, 1
    ];
    
    static _matrixOKLabtoLMS = [
        0.99999999845051981432, 1.0000000088817607767, 1.0000000546724109177, 0,
        0.39633779217376785678, -0.1055613423236563494, -0.089484182094965759684, 0,
        0.21580375806075880339, -0.063854174771705903402, -1.2914855378640917399, 0,
        0, 0, 0, 1
    ];
    
    #endregion
    
    #region Gamut mapping
    
    static _mapGamutRGBClip = function()/*->struct*/ {
        _updateRGB();
        var cacheRGB = _cache[_OKColorModel.RGB];
        
        return _gamutClipRGB(cacheRGB);
    }
    
    static _mapGamutRGBGeometric = function()/*->struct*/ {
        _updateRGB();
        var cacheRGB = _cache[_OKColorModel.RGB];
        
        if (_inGamutRGB(cacheRGB)) {
            return { r : cacheRGB.r, g : cacheRGB.g, b : cacheRGB.b };
        }
        
        var gamutX = _x / (_x + _y + _z) - _whitepointX;
        var gamutY = _y / (_x + _y + _z) - _whitepointY;
        var redX = 0.64 - _whitepointX;
        var redY = 0.33 - _whitepointY;
        var greenX = 0.30 - _whitepointX;
        var greenY = 0.60 - _whitepointY;
        var blueX = 0.15 - _whitepointX;
        var blueY = 0.06 - _whitepointY;
        
        var intersection1 = _gamutSegmentIntersection(gamutX, gamutY, 0, 0, redX, redY, greenX, greenY);
        var intersection2 = _gamutSegmentIntersection(gamutX, gamutY, 0, 0, greenX, greenY, blueX, blueY);
        var intersection3 = _gamutSegmentIntersection(gamutX, gamutY, 0, 0, blueX, blueY, redX, redY);
        
        var mappedX = gamutX + _whitepointX;
        var mappedY = gamutY + _whitepointY;
        
        if (_gamutPointOnSegment(intersection1.x, intersection1.y, redX, redY, greenX, greenY)) {
            mappedX = intersection1.x + _whitepointX;
            mappedY = intersection1.y + _whitepointY;
        }
        else if (_gamutPointOnSegment(intersection2.x, intersection2.y, greenX, greenY, blueX, blueY)) {
            mappedX = intersection2.x + _whitepointX;
            mappedY = intersection2.y + _whitepointY;
        }
        if (_gamutPointOnSegment(intersection3.x, intersection3.y, blueX, blueY, redX, redY)) {
            mappedX = intersection3.x + _whitepointX;
            mappedY = intersection3.y + _whitepointY;
        }
        
        var newY = _y;
        var newX = (_y / mappedY) * mappedX;
        var newZ = (_y / mappedY) * (1 - mappedX - mappedY);
        
        var vector = matrix_transform_vertex(_matrixXYZtoLinearRGB, newX, newY, newZ);
        
        // if (!surface_exists(debugSurf)) {
        //     debugSurf = surface_create(200, 200);
        // }
        
        // gamutX += _whitepointX;
        // gamutY += _whitepointY;
        // redX += _whitepointX;
        // redY += _whitepointY;
        // greenX += _whitepointX;
        // greenY += _whitepointY;
        // blueX += _whitepointX;
        // blueY += _whitepointY;
        
        // surface_set_target(debugSurf);
        // // draw_clear_alpha(c_black, 0);
        // draw_set_color(c_white);
        // draw_line(redX * 200, redY * 200, greenX * 200, greenY * 200);
        // draw_line(greenX * 200, greenY * 200, blueX * 200, blueY * 200);
        // draw_line(blueX * 200, blueY * 200, redX * 200, redY * 200);
        // // draw_line(gamutX * 200, gamutY * 200, _whitepointX * 200, _whitepointY * 200);
        
        // draw_circle(mappedX * 200, mappedY * 200, 4, false);
        // surface_reset_target();
        
        return _gamutClipRGB({
            r : _componentLinearRGBtoRGB(vector[0]),
            g : _componentLinearRGBtoRGB(vector[1]),
            b : _componentLinearRGBtoRGB(vector[2])
        });
    }
    
    static _mapGamutRGBChroma = function()/*->struct*/ {
        _updateLCH();
        var cacheLCH = _cache[_OKColorModel.LCH];
        var l = cacheLCH.l;
        
        if (l >= 100) return { r : 255, g : 255, b : 255 };
        if (l <= 0) return { r : 0, g : 0, b : 0 };
        
        _updateRGB();
        var cacheRGB = _cache[_OKColorModel.RGB];
        
        if (_inGamutRGB(cacheRGB)) {
            return { r : cacheRGB.r, g : cacheRGB.g, b : cacheRGB.b };
        }
        
        return _gamutReduceComponent(cacheLCH.c, function(chroma/*:number*/) { setLCH(, chroma); });
    }
    
    static _mapGamutRGBOKChroma = function()/*->struct*/ {
        _updateOKLCH();
        var cacheOKLCH = _cache[_OKColorModel.OKLCH];
        var l = cacheOKLCH.l;
        
        if (l >= 1) return { r : 255, g : 255, b : 255 };
        if (l <= 0) return { r : 0, g : 0, b : 0 };
        
        _updateRGB();
        var cacheRGB = _cache[_OKColorModel.RGB];
        
        if (_inGamutRGB(cacheRGB)) {
            return { r : cacheRGB.r, g : cacheRGB.g, b : cacheRGB.b };
        }
        
        return _gamutReduceComponent(cacheOKLCH.c, function(chroma/*:number*/) { setOKLCH(, chroma); });
    }
    
    #endregion
    
    #region Updates
    
    static _updateColor = function() {
        
    }
    
    static _updateString = function() {
        
    }
    
    static _updateRGB = function() {
        var cacheRGB = _cache[_OKColorModel.RGB];
        
        if (!cacheRGB.cached) {
            _updateLinearRGB();
            var cacheLinearRGB = _cache[_OKColorModel.LinearRGB];
            
            cacheRGB.r = _componentLinearRGBtoRGB(cacheLinearRGB.r);
            cacheRGB.g = _componentLinearRGBtoRGB(cacheLinearRGB.g);
            cacheRGB.b = _componentLinearRGBtoRGB(cacheLinearRGB.b);
            cacheRGB.cached = true;
        }
    }
    
    static _updateLinearRGB = function() {
        var cacheLinearRGB = _cache[_OKColorModel.LinearRGB];
        
        if (!cacheLinearRGB.cached) {
            var vector = matrix_transform_vertex(_matrixXYZtoLinearRGB, _x, _y, _z);
            
            cacheLinearRGB.r = vector[0];
            cacheLinearRGB.g = vector[1];
            cacheLinearRGB.b = vector[2];
            cacheLinearRGB.cached = true;
        }
    }
    
    static _updateHSV = function() {
        var cacheHSV = _cache[_OKColorModel.HSV];
        
        if (!cacheHSV.cached) {
            _updateRGB();
            var cacheRGB = _cache[_OKColorModel.RGB];
            var r = cacheRGB.r / 255;
            var g = cacheRGB.g / 255;
            var b = cacheRGB.b / 255;
            
            var maxComponent = max(r, g, b);
            var minComponent = min(r, g, b);
            
            var h = NaN;
            var s = 0;
            var v = maxComponent;
            var d = maxComponent - minComponent;
    
            if (d != 0) {
                s = (v == 0) ? 0 : d / v;
            
                switch (maxComponent) {
                    case r: h = (g - b) / d + (g < b ? 6 : 0); break;
                    case g: h = (b - r) / d + 2; break;
                    case b: h = (r - g) / d + 4; break;
                }
                
                h = (h * 60 + 360) % 360;
            }
            
            cacheHSV.h = h;
            cacheHSV.s = s;
            cacheHSV.v = v;
            cacheHSV.cached = true;
        }
    }
    
    static _updateHSL = function() {
        var cacheHSL = _cache[_OKColorModel.HSL];
        
        if (!cacheHSL.cached) {
            _updateRGB();
            var cacheRGB = _cache[_OKColorModel.RGB];
            var r = cacheRGB.r / 255;
            var g = cacheRGB.g / 255;
            var b = cacheRGB.b / 255;
            
            var maxComponent = max(r, g, b);
            var minComponent = min(r, g, b);
            
            var h = NaN;
            var s = 0;
            var l = (minComponent + maxComponent) / 2;
            var d = maxComponent - minComponent;
    
            if (d != 0) {
                s = (l == 0 || l == 1) ? 0 : (maxComponent - l) / min(l, 1 - l);
            
                switch (maxComponent) {
                    case r: h = (g - b) / d + (g < b ? 6 : 0); break;
                    case g: h = (b - r) / d + 2; break;
                    case b: h = (r - g) / d + 4; break;
                }
                
                h = (h * 60 + 360) % 360;
            }
            
            cacheHSL.h = h;
            cacheHSL.s = s;
            cacheHSL.l = l;
            cacheHSL.cached = true;
        }
    }
    
    static _updateLMS = function() {
        var cacheLMS = _cache[_OKColorModel.LMS];
        
        if (!cacheLMS.cached) {
            var vector = matrix_transform_vertex(_matrixXYZtoLMS, _x, _y, _z);
            
            cacheLMS.l = max(0, vector[0]);
            cacheLMS.m = max(0, vector[1]);
            cacheLMS.s = max(0, vector[2]);
            cacheLMS.cached = true;
        }
    }
    
    static _updateLab = function() {
        var cacheLab = _cache[_OKColorModel.Lab];
        
        if (!cacheLab.cached) {
            var epsilon = 216/24389;
            var k = 24389/27;
            
            var xNormalized = _x / _whitepoint.x;
            var yNormalized = _y / _whitepoint.y;
            var zNormalized = _z / _whitepoint.z;
            
            var fX = xNormalized > epsilon ? power(xNormalized, 1/3) : (k * xNormalized + 16) / 116;
            var fY = yNormalized > epsilon ? power(yNormalized, 1/3) : (k * yNormalized + 16) / 116;
            var fZ = zNormalized > epsilon ? power(zNormalized, 1/3) : (k * zNormalized + 16) / 116;
            
            cacheLab.l = 116 * fY - 16;
            cacheLab.a = 500 * (fX - fY);
            cacheLab.b = 200 * (fY - fZ);
            cacheLab.cached = true;
        }
    }
    
    static _updateLCH = function() {
        var cacheLCH = _cache[_OKColorModel.LCH];
        
        if (!cacheLCH.cached) {
            _updateLab();
            var cacheLab = _cache[_OKColorModel.Lab];
            
            var epsilon = 0.02;
            var a = cacheLab.a;
            var b = cacheLab.b;
            
            if (abs(a) < epsilon && abs(b) < epsilon) {
                cacheLCH.h = NaN;
            } else {
                cacheLCH.h = (darctan2(b, a) + 360) % 360;
            }
            
            cacheLCH.l = cacheLab.l;
            cacheLCH.c = sqrt(a * a + b * b);
            cacheLCH.cached = true;
        }
    }
    
    static _updateOKLab = function() {
        var cacheOKLab = _cache[_OKColorModel.OKLab];
        
        if (!cacheOKLab.cached) {
            _updateLMS();
            var cacheLMS = _cache[_OKColorModel.LMS];
            
            var vector = matrix_transform_vertex(_matrixLMStoOKLab, power(cacheLMS.l, 1/3), power(cacheLMS.m, 1/3), power(cacheLMS.s, 1/3));
            
            cacheOKLab.l = vector[0];
            cacheOKLab.a = vector[1];
            cacheOKLab.b = vector[2];
            cacheOKLab.cached = true;
        }
    }
    
    static _updateOKLCH = function() {
        var cacheOKLCH = _cache[_OKColorModel.OKLCH];
        
        if (!cacheOKLCH.cached) {
            _updateOKLab();
            var cacheOKLab = _cache[_OKColorModel.OKLab];
            
            var epsilon = 0.0002;
            var a = cacheOKLab.a;
            var b = cacheOKLab.b;
            
            if (abs(a) < epsilon && abs(b) < epsilon) {
                cacheOKLCH.h = NaN;
            } else {
                cacheOKLCH.h = (darctan2(b, a) + 360) % 360;
            }
            
            cacheOKLCH.l = cacheOKLab.l;
            cacheOKLCH.c = sqrt(a * a + b * b);
            cacheOKLCH.cached = true;
        }
    }
    
    #endregion
    
    #region Setters
    
    static setXYZ = function(x/*:number?*/ = undefined, y/*:number?*/ = undefined, z/*:number?*/ = undefined)/*->OKColor*/ {
        _x = x ?? _x;
        _y = y ?? _y;
        _z = z ?? _z;
        
        _setDirty();
        
        return self;
    }
    
    static setColor = function()/*->OKColor*/ {}
    
    static setString = function()/*->OKColor*/ {}
    
    static setRGB = function(red/*:number?*/ = undefined, green/*:number?*/ = undefined, blue/*:number?*/ = undefined)/*->OKColor*/ {
        // update values in case of setting parameters partially
        if (red == undefined || green == undefined || blue == undefined) {
            _updateRGB();
        }
        
        var cacheRGB = _cache[_OKColorModel.RGB];
        cacheRGB.r = red ?? cacheRGB.r;
        cacheRGB.g = green ?? cacheRGB.g;
        cacheRGB.b = blue ?? cacheRGB.b;
        
        var cacheLinearRGB = _cache[_OKColorModel.LinearRGB];
        cacheLinearRGB.r = _componentRGBtoLinearRGB(cacheRGB.r);
        cacheLinearRGB.g = _componentRGBtoLinearRGB(cacheRGB.g);
        cacheLinearRGB.b = _componentRGBtoLinearRGB(cacheRGB.b);
        
        var vector = matrix_transform_vertex(_matrixLinearRGBtoXYZ, cacheLinearRGB.r, cacheLinearRGB.g, cacheLinearRGB.b);
        _x = vector[0];
        _y = vector[1];
        _z = vector[2];
        
        _setDirty();
        cacheRGB.cached = true;
        cacheLinearRGB.cached = true;
        
        return self;
    }
    
    static setLinearRGB = function(red/*:number?*/ = undefined, green/*:number?*/ = undefined, blue/*:number?*/ = undefined)/*->OKColor*/ {
        // update values in case of setting parameters partially
        if (red == undefined || green == undefined || blue == undefined) {
            _updateLinearRGB();
        }
        
        var cacheLinearRGB = _cache[_OKColorModel.LinearRGB];
        cacheLinearRGB.r = red ?? cacheLinearRGB.r;
        cacheLinearRGB.g = green ?? cacheLinearRGB.g;
        cacheLinearRGB.b = blue ?? cacheLinearRGB.b;
        
        var vector = matrix_transform_vertex(_matrixLinearRGBtoXYZ, cacheLinearRGB.r, cacheLinearRGB.g, cacheLinearRGB.b);
        _x = vector[0];
        _y = vector[1];
        _z = vector[2];
        
        _setDirty();
        cacheLinearRGB.cached = true;
        
        return self;
    }
    
    static setHSV = function(hue/*:number?*/ = undefined, saturation/*:number?*/ = undefined, value/*:number?*/ = undefined)/*->OKColor*/ {
        // update values in case of setting parameters partially
        if (hue == undefined || saturation == undefined || value == undefined) {
            _updateHSV();
        }
        
        var cacheHSV = _cache[_OKColorModel.HSV];
        cacheHSV.h = hue ?? cacheHSV.h;
        cacheHSV.s = saturation ?? cacheHSV.s;
        cacheHSV.v = value ?? cacheHSV.v;
        
        var cacheRGB = _cache[_OKColorModel.RGB];
        
        if (is_nan(cacheHSV.h)) {
            cacheHSV.h = 0;
            var c = _piecewiseHSVtoRGB(0, cacheHSV) * 255;
            cacheRGB.r = c;
            cacheRGB.g = c;
            cacheRGB.b = c;
            cacheHSV.h = NaN;
        } else {
            cacheRGB.r = _piecewiseHSVtoRGB(5, cacheHSV) * 255;
            cacheRGB.g = _piecewiseHSVtoRGB(3, cacheHSV) * 255;
            cacheRGB.b = _piecewiseHSVtoRGB(1, cacheHSV) * 255;
        }
        
        var cacheLinearRGB = _cache[_OKColorModel.LinearRGB];
        cacheLinearRGB.r = _componentRGBtoLinearRGB(cacheRGB.r);
        cacheLinearRGB.g = _componentRGBtoLinearRGB(cacheRGB.g);
        cacheLinearRGB.b = _componentRGBtoLinearRGB(cacheRGB.b);
        
        var vector = matrix_transform_vertex(_matrixLinearRGBtoXYZ, cacheLinearRGB.r, cacheLinearRGB.g, cacheLinearRGB.b);
        _x = vector[0];
        _y = vector[1];
        _z = vector[2];
        
        _setDirty();
        cacheHSV.cached = true;
        cacheRGB.cached = true;
        cacheLinearRGB.cached = true;
        
        return self;
    }
    
    static setHSL = function(hue/*:number?*/ = undefined, saturation/*:number?*/ = undefined, lightness/*:number?*/ = undefined)/*->OKColor*/ {
        // update values in case of setting parameters partially
        if (hue == undefined || saturation == undefined || lightness == undefined) {
            _updateHSL();
        }
        
        var cacheHSL = _cache[_OKColorModel.HSL];
        cacheHSL.h = hue ?? cacheHSL.h;
        cacheHSL.s = saturation ?? cacheHSL.s;
        cacheHSL.l = lightness ?? cacheHSL.l;
        
        var cacheRGB = _cache[_OKColorModel.RGB];
        
        if (is_nan(cacheHSL.h)) {
            cacheHSL.h = 0;
            var c = _piecewiseHSLtoRGB(0, cacheHSL) * 255;
            cacheRGB.r = c;
            cacheRGB.g = c;
            cacheRGB.b = c;
            cacheHSL.h = NaN;
        } else {
            cacheRGB.r = _piecewiseHSLtoRGB(0, cacheHSL) * 255;
            cacheRGB.g = _piecewiseHSLtoRGB(8, cacheHSL) * 255;
            cacheRGB.b = _piecewiseHSLtoRGB(4, cacheHSL) * 255;
        }
        
        var cacheLinearRGB = _cache[_OKColorModel.LinearRGB];
        cacheLinearRGB.r = _componentRGBtoLinearRGB(cacheRGB.r);
        cacheLinearRGB.g = _componentRGBtoLinearRGB(cacheRGB.g);
        cacheLinearRGB.b = _componentRGBtoLinearRGB(cacheRGB.b);
        
        var vector = matrix_transform_vertex(_matrixLinearRGBtoXYZ, cacheLinearRGB.r, cacheLinearRGB.g, cacheLinearRGB.b);
        _x = vector[0];
        _y = vector[1];
        _z = vector[2];
        
        _setDirty();
        cacheHSL.cached = true;
        cacheRGB.cached = true;
        cacheLinearRGB.cached = true;
        
        return self;
    }
    
    static setLMS = function(long/*:number?*/ = undefined, medium/*:number?*/ = undefined, short/*:number?*/ = undefined)/*->OKColor*/ {
        if (long == undefined || medium == undefined || short == undefined) {
            _updateLMS();
        }
        
        var cacheLMS = _cache[_OKColorModel.LMS];
        cacheLMS.l = long != undefined ? max(0, long) : cacheLMS.l;
        cacheLMS.m = medium != undefined ? max(0, medium) : cacheLMS.m;
        cacheLMS.s = short != undefined ? max(0, short) : cacheLMS.s;
        
        vector = matrix_transform_vertex(_matrixLMStoXYZ, power(cacheLMS.l, 3), power(cacheLMS.m, 3), power(cacheLMS.s, 3));
        _x = vector[0];
        _y = vector[1];
        _z = vector[2];
        
        _setDirty();
        cacheLMS.cached = true;
        
        return self;
    }
    
    static setLab = function(lightness/*:number?*/ = undefined, a/*:number?*/ = undefined, b/*:number?*/ = undefined)/*->OKColor*/ {
    	// update values in case of setting parameters partially
        if (lightness == undefined || a == undefined || b == undefined) {
            _updateLab();
        }
        
        var cacheLab = _cache[_OKColorModel.OKLab];
        cacheLab.l = lightness ?? cacheLab.l;
        cacheLab.a = a ?? cacheLab.a;
        cacheLab.b = b ?? cacheLab.b;
        
        _updateXYZfromLab(cacheLab);
        
        _setDirty();
        cacheLab.cached = true;
        
        return self;
    }
    
    static setLCH = function(lightness/*:number?*/ = undefined, chroma/*:number?*/ = undefined, hue/*:number?*/ = undefined)/*->OKColor*/ {
        // update values in case of setting parameters partially
        if (lightness == undefined || chroma == undefined || hue == undefined) {
            _updateLCH();
        }
        
        var cacheLCH = _cache[_OKColorModel.LCH];
        cacheLCH.l = lightness ?? cacheLCH.l;
        cacheLCH.c = chroma ?? cacheLCH.c;
        cacheLCH.h = hue ?? cacheLCH.h;
        
        var cacheLab = _cache[_OKColorModel.Lab];
        cacheLab.l = cacheLCH.l;
        
        if (is_nan(cacheLCH.h)) {
            cacheLab.a = 0;
            cacheLab.b = 0;
        } else {
			cacheLab.a = lengthdir_x(cacheLCH.c, cacheLCH.h);
			cacheLab.b = -lengthdir_y(cacheLCH.c, cacheLCH.h);
        }
        
        _updateXYZfromLab(cacheLab);
        
        _setDirty();
        cacheLCH.cached = true;
        cacheLab.cached = true;
        
        return self;
    }
    
    static setOKLab = function(lightness/*:number?*/ = undefined, a/*:number?*/ = undefined, b/*:number?*/ = undefined)/*->OKColor*/ {
        // update values in case of setting parameters partially
        if (lightness == undefined || a == undefined || b == undefined) {
            _updateOKLab();
        }
        
        var cacheOKLab = _cache[_OKColorModel.OKLab];
        cacheOKLab.l = lightness ?? cacheOKLab.l;
        cacheOKLab.a = a ?? cacheOKLab.a;
        cacheOKLab.b = b ?? cacheOKLab.b;
        
        var cacheLMS = _cache[_OKColorModel.LMS];
        var vector = matrix_transform_vertex(_matrixOKLabtoLMS, cacheOKLab.l, cacheOKLab.a, cacheOKLab.b);
        cacheLMS.l = vector[0];
        cacheLMS.m = vector[1];
        cacheLMS.s = vector[2];
        
        vector = matrix_transform_vertex(_matrixLMStoXYZ, power(cacheLMS.l, 3), power(cacheLMS.m, 3), power(cacheLMS.s, 3));
        _x = vector[0];
        _y = vector[1];
        _z = vector[2];
        
        _setDirty();
        cacheOKLab.cached = true;
        cacheLMS.cached = true;
        
        return self;
    }
    
    static setOKLCH = function(lightness/*:number?*/ = undefined, chroma/*:number?*/ = undefined, hue/*:number?*/ = undefined)/*->OKColor*/ {
        // update values in case of setting parameters partially
        if (lightness == undefined || chroma == undefined || hue == undefined) {
            _updateOKLCH();
        }
        
        var cacheOKLCH = _cache[_OKColorModel.OKLCH];
        cacheOKLCH.l = lightness ?? cacheOKLCH.l;
        cacheOKLCH.c = chroma ?? cacheOKLCH.c;
        cacheOKLCH.h = hue ?? cacheOKLCH.h;
        
        var cacheOKLab = _cache[_OKColorModel.OKLab];
        cacheOKLab.l = cacheOKLCH.l;
        
        if (is_nan(cacheOKLCH.h)) {
            cacheOKLab.a = 0;
            cacheOKLab.b = 0;
        } else {
			cacheOKLab.a = lengthdir_x(cacheOKLCH.c, cacheOKLCH.h);
			cacheOKLab.b = -lengthdir_y(cacheOKLCH.c, cacheOKLCH.h);
        }
        
        var cacheLMS = _cache[_OKColorModel.LMS];
        var vector = matrix_transform_vertex(_matrixOKLabtoLMS, cacheOKLab.l, cacheOKLab.a, cacheOKLab.b);
        cacheLMS.l = vector[0];
        cacheLMS.m = vector[1];
        cacheLMS.s = vector[2];
        
        vector = matrix_transform_vertex(_matrixLMStoXYZ, power(cacheLMS.l, 3), power(cacheLMS.m, 3), power(cacheLMS.s, 3));
        _x = vector[0];
        _y = vector[1];
        _z = vector[2];
        
        _setDirty();
        cacheOKLCH.cached = true;
        cacheOKLab.cached = true;
        cacheLMS.cached = true;
        
        return self;
    }
    
    #endregion
    
    #region Getters
    
    static getXYZ = function()/*->struct*/ {
        return { x : _x, y : _y, z : _z };
    }
    
    static getRGB = function()/*->struct*/ {
        _updateRGB();
        var cacheRGB = _cache[_OKColorModel.RGB];
        return { r : cacheRGB.r, g : cacheRGB.g, b : cacheRGB.b };
    }
    
    static getLinearRGB = function()/*->struct*/ {
        _updateLinearRGB();
        var cacheLinearRGB = _cache[_OKColorModel.LinearRGB];
        return { r : cacheLinearRGB.r, g : cacheLinearRGB.g, b : cacheLinearRGB.b };
    }
    
    static getHSV = function()/*->struct*/ {
        _updateHSV();
        var cacheHSV = _cache[_OKColorModel.HSV];
        return { h : cacheHSV.h, s : cacheHSV.s, v : cacheHSV.v };
    }
    
    static getHSL = function()/*->struct*/ {
        _updateHSL();
        var cacheHSL = _cache[_OKColorModel.HSL];
        return { h : cacheHSL.h, s : cacheHSL.s, l : cacheHSL.l };
    }
    
    static getLMS = function()/*->struct*/ {
        _updateLMS();
        var cacheLMS = _cache[_OKColorModel.LMS];
        return { l : cacheLMS.l, m : cacheLMS.m, s : cacheLMS.s };
    }
    
    static getLab = function()/*->struct*/ {
        _updateLab();
        var cacheLab = _cache[_OKColorModel.Lab];
        return { l : cacheLab.l, a : cacheLab.a, b : cacheLab.b };
    }
    
    static getLCH = function()/*->struct*/ {
        _updateLCH();
        var cacheLCH = _cache[_OKColorModel.LCH];
        return { l : cacheLCH.l, c : cacheLCH.c, h : cacheLCH.h };
    }
    
    static getOKLab = function()/*->struct*/ {
        _updateOKLab();
        var cacheOKLab = _cache[_OKColorModel.OKLab];
        return { l : cacheOKLab.l, a : cacheOKLab.a, b : cacheOKLab.b };
    }
    
    static getOKLCH = function()/*->struct*/ {
        _updateOKLCH();
        var cacheOKLCH = _cache[_OKColorModel.OKLCH];
        return { l : cacheOKLCH.l, c : cacheOKLCH.c, h : cacheOKLCH.h };
    }
    
    #endregion
    
    #region Color Getters
    
    static color = function()/*->number*/ {
        
    }
    
    static colorHex = function()/*->string*/ {
        
    }
    
    static colorRGB = function(gamutMapping/*:int<OKColorMapping>*/ = _gamutMappingDefault)/*->struct*/ {
        return method(self, _gamutMapping[gamutMapping])();
    }
    
    #endregion
    
    #region Utility
    
    static clone = function()/*->OKColor*/ {
        return variable_clone(self);
    }
    
    static mix = function() {}
    
    #endregion
}