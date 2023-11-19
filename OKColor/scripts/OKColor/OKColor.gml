#macro OKCOLOR_WARNINGS 1

// Feather ignore GM2017
// Feather ignore GM2043
// Feather ignore GM2023
// Feather ignore GM1042
// Feather ignore GM1044

enum _OKColorModel {
    RGB,            /// @is {RGBCachedStruct}
    LinearRGB,      /// @is {RGBCachedStruct}
    HSV,            /// @is {HSVCachedStruct}
    HSL,            /// @is {HSLCachedStruct}
    LMS,            /// @is {LMSCachedStruct}
    Lab,            /// @is {LabCachedStruct}
    LCH,            /// @is {LCHCachedStruct}
    OKLab,          /// @is {LabCachedStruct}
    OKLCH,          /// @is {LCHCachedStruct}
    _sizeof
}

enum OKColorMapping {
    None,           /// @is {function<void>}
    Clip,           /// @is {function<void>}
    Geometric,      /// @is {function<void>}
    Chroma,         /// @is {function<void>}
    OKChroma,       /// @is {function<void>}
    _sizeof
}

enum OKColorMixing {
    RGB,            /// @is {function<OKColor, number, void>}
    Lab,            /// @is {function<OKColor, number, void>}
    OKLab,          /// @is {function<OKColor, number, void>}
}

/// @description This constructor will return a new instance of the OKColor struct to hold a color data.
function OKColor() constructor {
    /// @hint new OKColor() This constructor will return a new instance of the OKColor struct to hold a color data.
    
    /// @ignore
    _x = 0;
    /// @ignore
    _y = 0;
    /// @ignore
    _z = 0;
    
    /// @ignore
    _cache = /*#cast*/ array_create(_OKColorModel._sizeof);   /// @is {enum_tuple<_OKColorModel>}
    _cache[_OKColorModel.RGB] = { cached : true, r : 0, g : 0, b : 0 };
    _cache[_OKColorModel.LinearRGB] = { cached : true, r : 0, g : 0, b : 0 };
    _cache[_OKColorModel.HSV] = { cached : true, h : 0, s : 0, v : 0 };
    _cache[_OKColorModel.HSL] = { cached : true, h : 0, s : 0, l : 0 };
    _cache[_OKColorModel.LMS] = { cached : true, l : 0, m : 0, s : 0 };
    _cache[_OKColorModel.Lab] = { cached : true, l : 0, a : 0, b : 0 };
    _cache[_OKColorModel.LCH] = { cached : true, l : 0, c : 0, h : 0 };
    _cache[_OKColorModel.OKLab] = { cached : true, l : 0, a : 0, b : 0 };
    _cache[_OKColorModel.OKLCH] = { cached : true, l : 0, c : 0, h : 0 };
    
    /// @ignore
    static _gamutMapping = /*#cast*/ array_create(OKColorMapping._sizeof);      /// @is {enum_tuple<OKColorMapping>}
    _gamutMapping[OKColorMapping.None] = _mapGamutNone;
    _gamutMapping[OKColorMapping.Clip] = _mapGamutRGBClip;
    _gamutMapping[OKColorMapping.Geometric] = _mapGamutRGBGeometric;
    _gamutMapping[OKColorMapping.Chroma] = _mapGamutRGBChroma;
    _gamutMapping[OKColorMapping.OKChroma] = _mapGamutRGBOKChroma;
    
    /// @ignore
    static _colorMixing = /*#cast*/ array_create(OKColorMixing.OKLab);      /// @is {enum_tuple<OKColorMixing>}
    _colorMixing[OKColorMixing.RGB] = _mixRGB;
    _colorMixing[OKColorMixing.Lab] = _mixLab;
    _colorMixing[OKColorMixing.OKLab] = _mixOKLab;
    
    /// @ignore
    static _gamutMappingDefault = OKColorMapping.OKChroma;      /// @is {int<OKColorMapping>}
    /// @ignore
    _gamutMappedColorCache = undefined;                         /// @is {OKColor?}
    /// @ignore
    _gamutMappedColorCacheId = -1;                              /// @is {int<OKColorMapping>}
    
    /// @ignore
    static _colorMixingDefault = OKColorMixing.OKLab;           /// @is {int<OKColorMixing>}
    
    /// @ignore
    static _whitepointX = 0.3127;
    /// @ignore
    static _whitepointY = 0.3290;
    /// @ignore
    static _whitepoint = { x : _whitepointX / _whitepointY, y : 1, z : (1 - _whitepointX - _whitepointY) / _whitepointY };  /// @is {XYZStruct}
    
    #region Private
    
    /// @ignore
    static _setDirty = function()/*->void*/ {
        for (var i = 0; i < _OKColorModel._sizeof; i++) {
            (_cache[i] /*#as IColorCachedStruct*/).cached = false;
        }
        
        _gamutMappedColorCacheId = -1;
    }
    
    /// @ignore
    static _gamutSegmentIntersection = function(x1/*:number*/, y1/*:number*/, x2/*:number*/, y2/*:number*/, x3/*:number*/, y3/*:number*/, x4/*:number*/, y4/*:number*/)/*->Vector2Struct*/ {
        var top = (x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3);
        var bottom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1);
        var t = top / bottom;
        
        if (t < 0) return { x : x1, y : y1 };
        if (t > 1) return { x : infinity, y : infinity };
        
        return { x : lerp(x1, x2, t), y : lerp(y1, y2, t) };
    }
    
    /// @ignore
    static _gamutPointOnSegment = function(px/*:number*/, py/*:number*/, x1/*:number*/, y1/*:number*/, x2/*:number*/, y2/*:number*/)/*->bool*/ {
        var t1 = (px - x1) / (x2 - x1);
        var t2 = (py - y1) / (y2 - y1);
        
        return t1 == t2 && t1 >= 0 && t1 <= 1 && t2 >= 0 && t2 <= 1;
    }
    
    /// @ignore
    static _inGamutRGB = function(rgb/*:RGBStruct*/)/*->bool*/ {
        return (rgb.r >= 0 && rgb.r <= 255)
        && (rgb.g >= 0 && rgb.g <= 255)
        && (rgb.b >= 0 && rgb.b <= 255);
    }
    
    /// @ignore
    static _gamutClipRGB = function(rgb/*:RGBStruct*/)/*->RGBStruct*/ {
        return {
            r : clamp(rgb.r, 0, 255),
            g : clamp(rgb.g, 0, 255),
            b : clamp(rgb.b, 0, 255)
        };
    }
    
    /// @ignore
    static _deltaEOKLab = function(oklab1/*:LabStruct*/, oklab2/*:LabStruct*/)/*->number*/ {
        var delta_l = oklab1.l - oklab2.l;
        var delta_a = oklab1.a - oklab2.a;
        var delta_b = oklab1.b - oklab2.b;
        
        return sqrt(delta_l * delta_l + delta_a * delta_a + delta_b * delta_b);
    }
    
    /// @ignore
    static _componentRGBtoLinearRGB = function(component/*:number*/)/*->number*/ {
        component /= 255;
        
        if (component >= 0.04045) {
            return power((component + 0.055) / 1.055, 2.4);
        } else {
            return component / 12.92;
        }
    }
    
    /// @ignore
    static _componentLinearRGBtoRGB = function(component/*:number*/)/*->number*/ {
        if (component >= 0.0031308) {
            return (1.055 * power(component, 1.0 / 2.4) - 0.055) * 255;
        } else {
            return component * 12.92 * 255;
        }
    }
    
    /// @ignore
    static _piecewiseHSVtoRGB = function(n/*:number*/, hsv/*:HSVStruct*/)/*->number*/ {
        var h = hsv.h;
        var s = hsv.s;
        var v = hsv.v;
        
        var k = (n + h / 60) % 6;
        
        return v - v * s * max(0, min(k, 4 - k, 1));
    }
    
    /// @ignore
    static _piecewiseHSLtoRGB = function(n/*:number*/, hsl/*:HSLStruct*/)/*->number*/ {
        var h = hsl.h;
        var s = hsl.s;
        var l = hsl.l;
        
        var k = (n + h / 30) % 12;
        var a = s * min(l, 1 - l);
        
        return l - a * max(-1, min(k - 3, 9 - k, 1));
    }
    
    /// @ignore
    static _setXYZfromLab = function(lab/*:LabStruct*/) {
        var epsilon = 24/116;
        var k = 24389/27;
        
        var fY = (lab.l + 16) / 116;
        var fX = (lab.a / 500) + fY;
        var fZ = fY - lab.b / 200;
        
        _x = fX > epsilon ? power(fX, 3) * _whitepoint.x : (116 * fX - 16) / k * _whitepoint.x;
        _y = lab.l > 8 ? power(fY, 3) * _whitepoint.y : lab.l / k * _whitepoint.y;
        _z = fZ > epsilon ? power(fZ, 3) * _whitepoint.z : (116 * fZ - 16) / k * _whitepoint.z;
    }
    
    /// @ignore
    static _matrixXYZtoLinearRGB = [
        3.2409699419045226, -0.9692436362808796, 0.0556300796969936, 0,
        -1.5373831775700939, 1.8759675015077204, -0.2039769588889765, 0,
        -0.4986107602930034, 0.0415550574071756, 1.0569715142428784, 0,
        0, 0, 0, 1
    ];
    
    /// @ignore
    static _matrixLinearRGBtoXYZ = [
        0.4123907992659593, 0.2126390058715102, 0.0193308187155918, 0,
        0.3575843393838780, 0.7151686787677560, 0.1191947797946260, 0,
        0.1804807884018343, 0.0721923153607337, 0.9505321522496607, 0,
        0, 0, 0, 1
    ];
    
    /// @ignore
    static _matrixXYZtoLMS = [
        0.8190224432164319, 0.0329836671980271, 0.048177199566046255, 0,
        0.3619062562801221, 0.9292868468965546, 0.26423952494422764, 0,
        -0.12887378261216414, 0.03614466816999844, 0.6335478258136937, 0,
        0, 0, 0, 1
    ];
    
    /// @ignore
    static _matrixLMStoXYZ = [
        1.2268798733741557, -0.04057576262431372, -0.07637294974672142, 0,
        -0.5578149965554813, 1.1122868293970594, -0.4214933239627914, 0,
        0.28139105017721583, -0.07171106666151701, 1.5869240244272418, 0,
        0, 0, 0, 1
    ];
    
    /// @ignore
    static _matrixLMStoOKLab = [
        0.2104542553, 1.9779984951, 0.0259040371, 0,
        0.7936177850, -2.4285922050, 0.7827717662, 0,
        -0.0040720468, 0.4505937099, -0.8086757660, 0,
        0, 0, 0, 1
    ];
    
    /// @ignore
    static _matrixOKLabtoLMS = [
        0.99999999845051981432, 1.0000000088817607767, 1.0000000546724109177, 0,
        0.39633779217376785678, -0.1055613423236563494, -0.089484182094965759684, 0,
        0.21580375806075880339, -0.063854174771705903402, -1.2914855378640917399, 0,
        0, 0, 0, 1
    ];
    
    #endregion
    
    #region Gamut mapping
    
    /// @ignore
    static _mapGamutNone = function()/*->void*/ {
        _updateRGB();
        var cacheRGB = _cache[_OKColorModel.RGB];
        
        (_gamutMappedColorCache /*#as OKColor*/).setRGB(cacheRGB.r, cacheRGB.g, cacheRGB.b);
    }
    
    /// @ignore
    static _mapGamutRGBClip = function()/*->void*/ {
        _updateRGB();
        var cacheRGB = _cache[_OKColorModel.RGB];
        
        var clippedRGB = _gamutClipRGB(cacheRGB);
        (_gamutMappedColorCache /*#as OKColor*/).setRGB(clippedRGB.r, clippedRGB.g, clippedRGB.b);
    }
    
    /// @ignore
    static _mapGamutRGBGeometric = function()/*->void*/ {
        if (_y >= 1) {
            (_gamutMappedColorCache /*#as OKColor*/).setXYZ(_whitepoint.x, _whitepoint.y, _whitepoint.z);
            exit;
        }
        else if (_y <= 0) {
            (_gamutMappedColorCache /*#as OKColor*/).setXYZ(0, 0, 0);
            exit;
        }
        
        _updateRGB();
        var cacheRGB = _cache[_OKColorModel.RGB];
        
        if (_inGamutRGB(cacheRGB)) {
            (_gamutMappedColorCache /*#as OKColor*/).setRGB(cacheRGB.r, cacheRGB.g, cacheRGB.b);
            exit;
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
        
        mappedX += (_whitepointX - mappedX) * sqr(min(_y, _whitepoint.y) / _whitepoint.y);
        mappedY += (_whitepointY - mappedY) * sqr(min(_y, _whitepoint.y) / _whitepoint.y);
        
        var newY = _y;
        var newX = (_y / mappedY) * mappedX;
        var newZ = (_y / mappedY) * (1 - mappedX - mappedY);
        
        (_gamutMappedColorCache /*#as OKColor*/).setXYZ(newX, newY, newZ);
        
        var rgb = _gamutClipRGB((_gamutMappedColorCache /*#as OKColor*/).getRGB());
        (_gamutMappedColorCache /*#as OKColor*/).setRGB(rgb.r, rgb.g, rgb.b);
    }
    
    /// @ignore
    static _mapGamutReduceComponent = function(componentValue/*:number*/, componentSetter/*:function<number, void>*/)/*->void*/ {
        var jnd = 0.02;             // "just noticable difference"
        var epsilon = 0.0001;
        var minComponent = 0;
        var maxComponent = componentValue;
        var minInGamut = true;
        
        /// @ignore
        static _gamutWorkingColor = new OKColor();
        /// @ignore
        static _gamutClippedColor = new OKColor();
        
        _gamutWorkingColor.setXYZ(_x, _y, _z);
        var workingRGB = _gamutWorkingColor.getRGB();
        var clippedRGB = _gamutClipRGB(workingRGB);
        _gamutClippedColor.setRGB(clippedRGB.r, clippedRGB.g, clippedRGB.b);
        
        var deltaE = _deltaEOKLab(_gamutClippedColor.getOKLab(), _gamutWorkingColor.getOKLab());
        if (deltaE < jnd) {
            (_gamutMappedColorCache /*#as OKColor*/).setRGB(clippedRGB.r, clippedRGB.g, clippedRGB.b);
            exit;
        }
        
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
                        (_gamutMappedColorCache /*#as OKColor*/).setRGB(clippedRGB.r, clippedRGB.g, clippedRGB.b);
                        exit;
                    } else {
                        minInGamut = false;
                        minComponent = component;
                    }
                } else {
                    maxComponent = component;
                }
            }
        }
        
        (_gamutMappedColorCache /*#as OKColor*/).setRGB(clippedRGB.r, clippedRGB.g, clippedRGB.b);
    }
    
    /// @ignore
    static _mapGamutRGBChroma = function()/*->void*/ {
        _updateLCH();
        var cacheLCH = _cache[_OKColorModel.LCH];
        var l = cacheLCH.l;
        
        if (l >= 100) {
            (_gamutMappedColorCache /*#as OKColor*/).setXYZ(_whitepoint.x, _whitepoint.y, _whitepoint.z);
            exit;
        }
        else if (l <= 0) {
            (_gamutMappedColorCache /*#as OKColor*/).setXYZ(0, 0, 0);
            exit;
        }
        
        _updateRGB();
        var cacheRGB = _cache[_OKColorModel.RGB];
        
        if (_inGamutRGB(cacheRGB)) {
            (_gamutMappedColorCache /*#as OKColor*/).setRGB(cacheRGB.r, cacheRGB.g, cacheRGB.b);
            exit;
        }
        
        _mapGamutReduceComponent(cacheLCH.c, function(chroma/*:number*/) { setLCH(, chroma); });
    }
    
    /// @ignore
    static _mapGamutRGBOKChroma = function()/*->void*/ {
        _updateOKLCH();
        var cacheOKLCH = _cache[_OKColorModel.OKLCH];
        var l = cacheOKLCH.l;
        
        if (l >= 1) {
            (_gamutMappedColorCache /*#as OKColor*/).setXYZ(_whitepoint.x, _whitepoint.y, _whitepoint.z);
            exit;
        }
        else if (l <= 0) {
            (_gamutMappedColorCache /*#as OKColor*/).setXYZ(0, 0, 0);
            exit;
        }
        
        _updateRGB();
        var cacheRGB = _cache[_OKColorModel.RGB];
        
        if (_inGamutRGB(cacheRGB)) {
            (_gamutMappedColorCache /*#as OKColor*/).setRGB(cacheRGB.r, cacheRGB.g, cacheRGB.b);
            exit;
        }
        
        _mapGamutReduceComponent(cacheOKLCH.c, function(chroma/*:number*/) { setOKLCH(, chroma); });
    }
    
    #endregion
    
    #region Color mixing
    
    /// @ignore
    static _mixRGB = function(mixColor/*:OKColor*/, amount/*:number*/)/*->void*/ {
        var cacheRGB1 = (_gamutMappedColorCache /*#as OKColor*/).getRGB();
        var cacheRGB2 = (mixColor._gamutMappedColorCache /*#as OKColor*/).getRGB();
        
        setRGB(
            lerp(cacheRGB1.r, cacheRGB2.r, amount),
            lerp(cacheRGB1.g, cacheRGB2.g, amount),
            lerp(cacheRGB1.b, cacheRGB2.b, amount)
        );
    }
    
    /// @ignore
    static _mixLab = function(mixColor/*:OKColor*/, amount/*:number*/)/*->void*/ {
        var cacheLab1 = (_gamutMappedColorCache /*#as OKColor*/).getLab();
        var cacheLab2 = (mixColor._gamutMappedColorCache /*#as OKColor*/).getLab();
        
        setLab(
            lerp(cacheLab1.l, cacheLab2.l, amount),
            lerp(cacheLab1.a, cacheLab2.a, amount),
            lerp(cacheLab1.b, cacheLab2.b, amount)
        );
    }
    
    /// @ignore
    static _mixOKLab = function(mixColor/*:OKColor*/, amount/*:number*/)/*->void*/ {
        var cacheOKLab1 = (_gamutMappedColorCache /*#as OKColor*/).getOKLab();
        var cacheOKLab2 = (mixColor._gamutMappedColorCache /*#as OKColor*/).getOKLab();
        
        setOKLab(
            lerp(cacheOKLab1.l, cacheOKLab2.l, amount),
            lerp(cacheOKLab1.a, cacheOKLab2.a, amount),
            lerp(cacheOKLab1.b, cacheOKLab2.b, amount)
        );
    }
    
    #endregion
    
    #region Updates
    
    /// @ignore
    static _updateMapped = function(gamutMapping/*:int<OKColorMapping>*/)/*->void*/ {
        _gamutMappedColorCache ??= new OKColor();
        
        if (_gamutMappedColorCacheId != gamutMapping) {
            method(self, _gamutMapping[gamutMapping] /*#as function<void>*/)();
            _gamutMappedColorCacheId = gamutMapping;
        }
    }
    
    /// @ignore
    static _updateRGB = function()/*->void*/ {
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
    
    /// @ignore
    static _updateLinearRGB = function()/*->void*/ {
        var cacheLinearRGB = _cache[_OKColorModel.LinearRGB];
        
        if (!cacheLinearRGB.cached) {
            var vector = matrix_transform_vertex(_matrixXYZtoLinearRGB, _x, _y, _z);
            
            cacheLinearRGB.r = vector[0];
            cacheLinearRGB.g = vector[1];
            cacheLinearRGB.b = vector[2];
            cacheLinearRGB.cached = true;
        }
    }
    
    /// @ignore
    static _updateHSV = function()/*->void*/ {
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
    
    /// @ignore
    static _updateHSL = function()/*->void*/ {
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
    
    /// @ignore
    static _updateLMS = function()/*->void*/ {
        var cacheLMS = _cache[_OKColorModel.LMS];
        
        if (!cacheLMS.cached) {
            var vector = matrix_transform_vertex(_matrixXYZtoLMS, _x, _y, _z);
            
            cacheLMS.l = max(0, vector[0]);
            cacheLMS.m = max(0, vector[1]);
            cacheLMS.s = max(0, vector[2]);
            cacheLMS.cached = true;
        }
    }
    
    /// @ignore
    static _updateLab = function()/*->void*/ {
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
    
    /// @ignore
    static _updateLCH = function()/*->void*/ {
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
    
    /// @ignore
    static _updateOKLab = function()/*->void*/ {
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
    
    /// @ignore
    static _updateOKLCH = function()/*->void*/ {
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
    
    /// @function setXYZ([x], [y], [z])
    /// @self OKColor
    /// @param {Real} [x] The X component definition of CIE XYZ color.
    /// @param {Real} [y] The Y component definition of CIE XYZ color.
    /// @param {Real} [z] The Z component definition of CIE XYZ color.
    /// @return {Struct.OKColor} The same OKColor instance that the method was called on, for method chaining.
    /// @description With this method, you can set a color in CIE XYZ format that is mostly used for technical needs. Arguments are optional so you can set components separately.
    static setXYZ = function(x/*:number?*/ = undefined, y/*:number?*/ = undefined, z/*:number?*/ = undefined)/*->OKColor*/ {
        /// @hint OKColor:setXYZ(?x:number?, ?y:number?, ?z:number?)->OKColor Returns the same OKColor instance that the method was called on, for method chaining.
        
        _x = x ?? _x;
        _y = y ?? _y;
        _z = z ?? _z;
        
        _setDirty();
        
        return self;
    }
    
    /// @function setColor(color)
    /// @self OKColor
    /// @param {Constant.Color} color The color definition in GameMaker supported format, can be c_color constant, #rrggbb, $bbggrr or a decimal number.
    /// @return {Struct.OKColor} The same OKColor instance that the method was called on, for method chaining.
    /// @description With this method, you can set a color in GameMaker format.
    static setColor = function(_color/*:int<color>*/)/*->OKColor*/ {
        /// @hint OKColor:setColor(color:int<color>)->OKColor Argument can be c_color constant, #rrggbb, $bbggrr or a decimal number. Returns the same OKColor instance that the method was called on, for method chaining.
        
        var cacheRGB = _cache[_OKColorModel.RGB];
        cacheRGB.r = color_get_red(_color);
        cacheRGB.g = color_get_green(_color);
        cacheRGB.b = color_get_blue(_color);
        
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
    
    /// @function setHex(hex)
    /// @self OKColor
    /// @param {String} hex The color definition in hex format as a string "#rrggbb".
    /// @return {Struct.OKColor} The same OKColor instance that the method was called on, for method chaining.
    /// @description Description
    static setHex = function(hex/*:string*/)/*->OKColor*/ {
        /// @hint OKColor:setHex(hex:string)->OKColor Argument in hex format as a string "#rrggbb". Returns the same OKColor instance that the method was called on, for method chaining.
        
        var dec = 0;
 
        var dig = "0123456789ABCDEF";
        var len = string_length(hex);
        for (var pos = 1; pos <= len; pos += 1) {
            dec = dec << 4 | (string_pos(string_char_at(hex, pos), dig) - 1);
        }
        
        var gmcolor = (dec & 0xFF0000) >> 16 | (dec & 0x00FF00) | (dec & 0x0000FF) << 16;
        
        return setColor(gmcolor);
    }
    
    /// @function setRGB([red], [green], [blue])
    /// @self OKColor
    /// @param {Real} [red] The red component definition of RGB color (in 0-255 range).
    /// @param {Real} [green] The green component definition of RGB color (in 0-255 range).
    /// @param {Real} [blue] The blue component definition of RGB color (in 0-255 range).
    /// @return {Struct.OKColor} The same OKColor instance that the method was called on, for method chaining.
    /// @description With this method, you can set a color in RGB format. Arguments are optional so you can set components separately.
    static setRGB = function(red/*:number?*/ = undefined, green/*:number?*/ = undefined, blue/*:number?*/ = undefined)/*->OKColor*/ {
        /// @hint OKColor:setRGB(?red:number?, ?green:number?, ?blue:number?)->OKColor Components are in 0-255 range. Returns the same OKColor instance that the method was called on, for method chaining.
        
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
    
    /// @function setLinearRGB([red], [green], [blue])
    /// @self OKColor
    /// @param {Real} [red] The red component definition of Linear RGB color (in 0-1 range).
    /// @param {Real} [green] The green component definition of Linear RGB color (in 0-1 range).
    /// @param {Real} [blue] The blue component definition of Linear RGB color (in 0-1 range).
    /// @return {Struct.OKColor} The same OKColor instance that the method was called on, for method chaining.
    /// @description With this method, you can set a color in non-gamma corrected Linear RGB format. Arguments are optional so you can set components separately.
    static setLinearRGB = function(red/*:number?*/ = undefined, green/*:number?*/ = undefined, blue/*:number?*/ = undefined)/*->OKColor*/ {
        /// @hint OKColor:setLinearRGB(?red:number?, ?green:number?, ?blue:number?)->OKColor Components are in 0-1 range. Returns the same OKColor instance that the method was called on, for method chaining.
        
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
    
    /// @function setHSV([hue], [saturation], [value])
    /// @self OKColor
    /// @param {Real} [hue] The hue component definition of HSV color (in 0-360 range).
    /// @param {Real} [saturation] The saturation component definition of HSV color (in 0-1 range).
    /// @param {Real} [value] The value component definition of HSV color (in 0-1 range).
    /// @return {Struct.OKColor} The same OKColor instance that the method was called on, for method chaining.
    /// @description With this method, you can set a color in HSV format. Arguments are optional so you can set components separately.
    static setHSV = function(hue/*:number?*/ = undefined, saturation/*:number?*/ = undefined, value/*:number?*/ = undefined)/*->OKColor*/ {
        /// @hint OKColor:setHSV(?hue:number?, ?saturation:number?, ?value:number?)->OKColor Hue in a 0-360 range, saturation and value is in 0-1. Returns the same OKColor instance that the method was called on, for method chaining.
        
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
    
    /// @function setHSL([hue], [saturation], [lightness])
    /// @self OKColor
    /// @param {Real} [hue] The hue component definition of HSL color (in 0-360 range).
    /// @param {Real} [saturation] The saturation component definition of HSL color (in 0-1 range).
    /// @param {Real} [lightness]The lightness component definition of HSL color (in 0-1 range).
    /// @return {Struct.OKColor} The same OKColor instance that the method was called on, for method chaining.
    /// @description With this method, you can set a color in HSL format. Arguments are optional so you can set components separately.
    static setHSL = function(hue/*:number?*/ = undefined, saturation/*:number?*/ = undefined, lightness/*:number?*/ = undefined)/*->OKColor*/ {
        /// @hint OKColor:setHSL(?hue:number?, ?saturation:number?, ?lightness:number?)->OKColor Hue in a 0-360 range, saturation and lightness is in 0-1. Returns the same OKColor instance that the method was called on, for method chaining.
        
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
    
    /// @function setLMS([long], [medium], [short])
    /// @self OKColor
    /// @param {Real} [long] The long wavelength definition of LMS color.
    /// @param {Real} [medium] The medium wavelength definition of LMS color.
    /// @param {Real} [short] The short wavelength definition of LMS color.
    /// @return {Struct.OKColor} The same OKColor instance that the method was called on, for method chaining.
    /// @description With this method, you can set a color in LMS format that is mostly used for technical needs. Arguments are optional so you can set components separately.
    static setLMS = function(long/*:number?*/ = undefined, medium/*:number?*/ = undefined, short/*:number?*/ = undefined)/*->OKColor*/ {
        /// @hint OKColor:setLMS(?long:number?, ?medium:number?, ?short:number?)->OKColor Returns the same OKColor instance that the method was called on, for method chaining.
        
        if (long == undefined || medium == undefined || short == undefined) {
            _updateLMS();
        }
        
        var cacheLMS = _cache[_OKColorModel.LMS];
        cacheLMS.l = long != undefined ? max(0, long) : cacheLMS.l;
        cacheLMS.m = medium != undefined ? max(0, medium) : cacheLMS.m;
        cacheLMS.s = short != undefined ? max(0, short) : cacheLMS.s;
        
        var vector = matrix_transform_vertex(_matrixLMStoXYZ, power(cacheLMS.l, 3), power(cacheLMS.m, 3), power(cacheLMS.s, 3));
        _x = vector[0];
        _y = vector[1];
        _z = vector[2];
        
        _setDirty();
        cacheLMS.cached = true;
        
        return self;
    }
    
    /// @function setLab([lightness], [a], [b])
    /// @self OKColor
    /// @param {Real} [lightness] The lightness component definition of CIELab color (in 0-100 range).
    /// @param {Real} [a] The a component definition of CIELab color (in -125 to 125 range).
    /// @param {Real} [b] The b component definition of CIELab color (in -125 to 125 range).
    /// @return {Struct.OKColor} The same OKColor instance that the method was called on, for method chaining.
    /// @description With this method, you can set a color in CIELab format. Arguments are optional so you can set components separately.
    static setLab = function(lightness/*:number?*/ = undefined, a/*:number?*/ = undefined, b/*:number?*/ = undefined)/*->OKColor*/ {
        /// @hint OKColor:setLab(?lightness:number?, ?a:number?, ?b:number?)->OKColor Lightness is in 0-100 range, a and b is in -125 to 125. Returns the same OKColor instance that the method was called on, for method chaining.
        
        // update values in case of setting parameters partially
        if (lightness == undefined || a == undefined || b == undefined) {
            _updateLab();
        }
        
        var cacheLab = _cache[_OKColorModel.Lab];
        cacheLab.l = lightness ?? cacheLab.l;
        cacheLab.a = a ?? cacheLab.a;
        cacheLab.b = b ?? cacheLab.b;
        
        _setXYZfromLab(cacheLab);
        
        _setDirty();
        cacheLab.cached = true;
        
        return self;
    }
    
    /// @function setLCH([lightness], [chroma], [hue])
    /// @self OKColor
    /// @param {Real} [lightness] The lightness component definition of CIELCH color (in 0-100 range).
    /// @param {Real} [chroma] The chroma component definition of CIELCH color (in 0-150 range).
    /// @param {Real} [hue] The hue component definition of CIELCH color (in 0-360 range).
    /// @return {Struct.OKColor} The same OKColor instance that the method was called on, for method chaining.
    /// @description With this method, you can set a color in CIELCH format. Arguments are optional so you can set components separately.
    static setLCH = function(lightness/*:number?*/ = undefined, chroma/*:number?*/ = undefined, hue/*:number?*/ = undefined)/*->OKColor*/ {
        /// @hint OKColor:setLCH(?lightness:number?, ?chroma:number?, ?hue:number?)->OKColor Lightness is in 0-100 range, chroma is in 0-150, hue is in 0-360. Returns the same OKColor instance that the method was called on, for method chaining.
        
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
        
        _setXYZfromLab(cacheLab);
        
        _setDirty();
        cacheLCH.cached = true;
        cacheLab.cached = true;
        
        return self;
    }
    
    /// @function setOKLab([lightness], [a], [b])
    /// @self OKColor
    /// @param {Real} [lightness] The lightness component definition of OKLab color (in 0-1 range).
    /// @param {Real} [a] The a component definition of OKLab color (in -0.4 to 0.4 range).
    /// @param {Real} [b] The b component definition of OKLab color (in -0.4 to 0.4 range).
    /// @return {Struct.OKColor} The same OKColor instance that the method was called on, for method chaining.
    /// @description With this method, you can set a color in OKLab format. Arguments are optional so you can set components separately.
    static setOKLab = function(lightness/*:number?*/ = undefined, a/*:number?*/ = undefined, b/*:number?*/ = undefined)/*->OKColor*/ {
        /// @hint OKColor:setOKLab(?lightness:number?, ?a:number?, ?b:number?)->OKColor Lightness is in 0-1 range, a and b is in -0.4 to 0.4. Returns the same OKColor instance that the method was called on, for method chaining.
        
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
    
    /// @function setOKLCH([lightness], [chroma], [hue])
    /// @self OKColor
    /// @param {Real} [lightness] The lightness component definition of OKLCH color (in 0-1 range).
    /// @param {Real} [chroma] The chroma component definition of OKLCH color (in 0 to 0.4 range).
    /// @param {Real} [hue] The hue component definition of OKLCH color (in 0-360 range).
    /// @return {Struct.OKColor} The same OKColor instance that the method was called on, for method chaining.
    /// @description With this method, you can set a color in OKLCH format. Arguments are optional so you can set components separately.
    static setOKLCH = function(lightness/*:number?*/ = undefined, chroma/*:number?*/ = undefined, hue/*:number?*/ = undefined)/*->OKColor*/ {
        /// @hint OKColor:setOKLCH(?lightness:number?, ?chroma:number?, ?hue:number?)->OKColor Lightness is in 0-1 range, chroma is in 0 to 0.4, hue is in 0-360. Returns the same OKColor instance that the method was called on, for method chaining.
        
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
    
    /// @function getXYZ()
    /// @self OKColor
    /// @pure
    /// @description With this method, you can get a color in raw CIE XYZ format that is mostly used for technical needs.
    static getXYZ = function()/*->XYZStruct*/ {
        /// @hint OKColor:getXYZ()->XYZStruct Get a color in raw CIE XYZ format that is mostly used for technical needs.
        
        return { x : _x, y : _y, z : _z };
    }
    
    /// @function getRGB()
    /// @self OKColor
    /// @pure
    /// @description With this method, you can get a color in raw RGB format.
    static getRGB = function()/*->RGBStruct*/ {
        /// @hint OKColor:getRGB()->RGBStruct Get a color in raw RGB format.
        
        _updateRGB();
        var cacheRGB = _cache[_OKColorModel.RGB];
        return { r : cacheRGB.r, g : cacheRGB.g, b : cacheRGB.b };
    }
    
    /// @function getLinearRGB()
    /// @self OKColor
    /// @pure
    /// @description With this method, you can get a color in raw non-gamma corrected Linear RGB format.
    static getLinearRGB = function()/*->RGBStruct*/ {
        /// @hint OKColor:getLinearRGB()->RGBStruct Get a color in raw non-gamma corrected Linear RGB format.
        
        _updateLinearRGB();
        var cacheLinearRGB = _cache[_OKColorModel.LinearRGB];
        return { r : cacheLinearRGB.r, g : cacheLinearRGB.g, b : cacheLinearRGB.b };
    }
    
    /// @function getHSV()
    /// @self OKColor
    /// @pure
    /// @description With this method, you can get a color in raw HSV format. Warning: hue in the resulting struct can be NaN, can be safely treated as 0 in outside use.
    static getHSV = function()/*->HSVStruct*/ {
        /// @hint OKColor:getHSV()->HSVStruct Get a color in raw HSV format. Warning: hue in the resulting struct can be NaN, can be safely treated as 0 in outside use.
        
        _updateHSV();
        var cacheHSV = _cache[_OKColorModel.HSV];
        return { h : cacheHSV.h, s : cacheHSV.s, v : cacheHSV.v };
    }
    
    /// @function getHSL()
    /// @self OKColor
    /// @pure
    /// @description With this method, you can get a color in raw HSL format. Warning: hue in the resulting struct can be NaN, can be safely treated as 0 in outside use.
    static getHSL = function()/*->HSLStruct*/ {
        /// @hint OKColor:getHSL()->HSLStruct Get a color in raw HSL format. Warning: hue in the resulting struct can be NaN, can be safely treated as 0 in outside use.
        
        _updateHSL();
        var cacheHSL = _cache[_OKColorModel.HSL];
        return { h : cacheHSL.h, s : cacheHSL.s, l : cacheHSL.l };
    }
    
    /// @function getLMS()
    /// @self OKColor
    /// @pure
    /// @description With this method, you can get a color in raw LMS format that is mostly used for technical needs.
    static getLMS = function()/*->LMSStruct*/ {
        /// @hint OKColor:getLMS()->LMSStruct Get a color in raw LMS format that is mostly used for technical needs.
        
        _updateLMS();
        var cacheLMS = _cache[_OKColorModel.LMS];
        return { l : cacheLMS.l, m : cacheLMS.m, s : cacheLMS.s };
    }
    
    /// @function getLab()
    /// @self OKColor
    /// @pure
    /// @description With this method, you can get a color in raw CIELab format.
    static getLab = function()/*->LabStruct*/ {
        /// @hint OKColor:getLab()->LabStruct Get a color in raw CIELab format.
        
        _updateLab();
        var cacheLab = _cache[_OKColorModel.Lab];
        return { l : cacheLab.l, a : cacheLab.a, b : cacheLab.b };
    }
    
    /// @function getLCH()
    /// @self OKColor
    /// @pure
    /// @description With this method, you can get a color in raw CIELCH format.
    static getLCH = function()/*->LCHStruct*/ {
        /// @hint OKColor:getLCH()->LCHStruct Get a color in raw CIELCH format.
        
        _updateLCH();
        var cacheLCH = _cache[_OKColorModel.LCH];
        return { l : cacheLCH.l, c : cacheLCH.c, h : cacheLCH.h };
    }
    
    /// @function getOKLab()
    /// @self OKColor
    /// @pure
    /// @description With this method, you can get a color in raw OKLab format.
    static getOKLab = function()/*->LabStruct*/ {
        /// @hint OKColor:getOKLab()->LabStruct Get a color in raw OKLab format.
        
        _updateOKLab();
        var cacheOKLab = _cache[_OKColorModel.OKLab];
        return { l : cacheOKLab.l, a : cacheOKLab.a, b : cacheOKLab.b };
    }
    
    /// @function getOKLCH()
    /// @self OKColor
    /// @pure
    /// @description With this method, you can get a color in raw OKLCH format.
    static getOKLCH = function()/*->LCHStruct*/ {
        /// @hint OKColor:getOKLCH()->LCHStruct Get a color in raw OKLCH format.
        
        _updateOKLCH();
        var cacheOKLCH = _cache[_OKColorModel.OKLCH];
        return { l : cacheOKLCH.l, c : cacheOKLCH.c, h : cacheOKLCH.h };
    }
    
    #endregion
    
    #region Color Getters
    
    /// @function color([gamutMapping])
    /// @self OKColor
    /// @pure
    /// @param {Enum.OKColorMapping} [gamutMapping] Gamut mapping type, default is OKLCH chroma reduction.
    /// @description With this method you can get a color value valid for rendering in GameMaker format usable for any system function like draw_set_color.
    static color = function(gamutMapping/*:int<OKColorMapping>*/ = _gamutMappingDefault)/*->int<color>*/ {
        /// @hint OKColor:color(?gamutMapping:int<OKColorMapping>)->int<color> Get a color value valid for rendering in GameMaker format usable for any system function like draw_set_color.
    
        _updateMapped(gamutMapping);
        var mappedRGB = (_gamutMappedColorCache /*#as OKColor*/).getRGB();
        
        return make_color_rgb(mappedRGB.r, mappedRGB.g, mappedRGB.b);
    }
    
    /// @function colorHex([gamutMapping])
    /// @self OKColor
    /// @pure
    /// @param {Enum.OKColorMapping} [gamutMapping] Gamut mapping type, default is OKLCH chroma reduction
    /// @description With this method you can get a color value valid for rendering in hex format as a string "#rrggbb".
    static colorHex = function(gamutMapping/*:int<OKColorMapping>*/ = _gamutMappingDefault)/*->string*/ {
        /// @hint OKColor:colorHex(?gamutMapping:int<OKColorMapping>)->string Get a color value valid for rendering in hex format as a string "#rrggbb".
        
        _updateMapped(gamutMapping);
        var mappedRGB = (_gamutMappedColorCache /*#as OKColor*/).getRGB();
        
        var dec = make_color_rgb(mappedRGB.b, mappedRGB.g, mappedRGB.r);
        var len = 6;
        var hex = "";
        
        var dig = "0123456789ABCDEF";
        // Feather ignore once GM1011
        while (len-- || dec) {
            hex = string_char_at(dig, (dec & $F) + 1) + hex;
            dec = dec >> 4;
        }
        
        return "#" + hex;
    }
    
    /// @function colorRGB([gamutMapping])
    /// @self OKColor
    /// @pure
    /// @param {Enum.OKColorMapping} [gamutMapping] Gamut mapping type, default is OKLCH chroma reduction.
    /// @description With this method you can get color values valid for rendering in RGB format.
    static colorRGB = function(gamutMapping/*:int<OKColorMapping>*/ = _gamutMappingDefault)/*->RGBStruct*/ {
        /// @hint OKColor:colorRGB(?gamutMapping:int<OKColorMapping>)->RGBStruct Get color values valid for rendering in RGB format.
        
        _updateMapped(gamutMapping);
        var mappedRGB = (_gamutMappedColorCache /*#as OKColor*/).getRGB();
        
        return {
            r : mappedRGB.r,
            g : mappedRGB.g,
            b : mappedRGB.b
        }
    }
    
    /// @function colorHSV([gamutMapping])
    /// @self OKColor
    /// @pure
    /// @param {Enum.OKColorMapping} [gamutMapping] Gamut mapping type, default is OKLCH chroma reduction.
    /// @description With this method you can get color values valid for rendering in HSV format.
    static colorHSV = function(gamutMapping/*:int<OKColorMapping>*/ = _gamutMappingDefault)/*->HSVStruct*/ {
        /// @hint OKColor:colorHSV(?gamutMapping:int<OKColorMapping>)->HSVStruct Get color values valid for rendering in HSV format.
        
        _updateMapped(gamutMapping);
        var mappedHSV = (_gamutMappedColorCache /*#as OKColor*/).getHSV();
        
        return {
            h : mappedHSV.h,
            s : mappedHSV.s,
            v : mappedHSV.v
        }
    }
    
    /// @function colorGMHSV([gamutMapping])
    /// @self OKColor
    /// @pure
    /// @param {Enum.OKColorMapping} [gamutMapping] Gamut mapping type, default is OKLCH chroma reduction.
    /// @description With this method you can get color values valid for rendering in GameMaker HSV format with 0-255 range.
    static colorGMHSV = function(gamutMapping/*:int<OKColorMapping>*/ = _gamutMappingDefault)/*->HSVStruct*/ {
        /// @hint OKColor:colorGMHSV(?gamutMapping:int<OKColorMapping>)->HSVStruct Get color values valid for rendering in GameMaker HSV format with 0-255 range.
        
        _updateMapped(gamutMapping);
        var mappedHSV = (_gamutMappedColorCache /*#as OKColor*/).getHSV();
        
        return {
            h : mappedHSV.h / 360 * 255,
            s : mappedHSV.s * 255,
            v : mappedHSV.v * 255
        }
    }
    
    /// @function colorHSL([gamutMapping])
    /// @self OKColor
    /// @pure
    /// @param {Enum.OKColorMapping} [gamutMapping] Gamut mapping type, default is OKLCH chroma reduction.
    /// @description With this method you can get color values valid for rendering in HSL format.
    static colorHSL = function(gamutMapping/*:int<OKColorMapping>*/ = _gamutMappingDefault)/*->HSLStruct*/ {
        /// @hint OKColor:colorHSL(?gamutMapping:int<OKColorMapping>)->HSLStruct Get color values valid for rendering in HSL format.
        
        _updateMapped(gamutMapping);
        var mappedHSL = (_gamutMappedColorCache /*#as OKColor*/).getHSL();
        
        return {
            h : mappedHSL.h,
            s : mappedHSL.s,
            l : mappedHSL.l
        }
    }
    
    #endregion
    
    #region Utility
    
    /// @function clone()
    /// @self OKColor
    /// @pure
    /// @returns {Struct.OKColor} New OKColor instance.
    /// @description With this method you can get a new copy of OKColor struct with the same color.
    static clone = function()/*->OKColor*/ {
        /// @hint OKColor:clone(mixColor:OKColor, amount:number, ?colorMixing:int<OKColorMixing>?, ?gamutMapping:int<OKColorMapping>?)->OKColor Get a new copy of OKColor struct with the same color.
        return variable_clone(self);
    }
    
    /// @function cloneMapped([gamutMapping])
    /// @self OKColor
    /// @pure
    /// @param {Enum.OKColorMapping} [gamutMapping] Gamut mapping type, default is OKLCH chroma reduction.
    /// @returns {Struct.OKColor}
    /// @description With this method you can get a new copy of OKColor struct with the same color mapped for rendering.
    static cloneMapped = function(gamutMapping/*:int<OKColorMapping>*/ = _gamutMappingDefault)/*->OKColor*/ {
        /// @hint OKColor:cloneMapped(?gamutMapping:int<OKColorMapping>)->OKColor Get a new copy of OKColor struct with the same color mapped for rendering.
        
        _updateMapped(gamutMapping);
        
        return variable_clone((_gamutMappedColorCache /*#as OKColor*/));
    }
    
    /// @function mix(mixColor, amount, [colorMixing], [gamutMapping])
    /// @self OKColor
    /// @param {Struct.OKColor} mixColor Additional color to mix with.
    /// @param {Real} amount How much to mix a color in 0-1 range.
    /// @param {Enum.OKColorMixing} [colorMixing] Color mixing type, default is OKLab interpolation.
    /// @param {Enum.OKColorMapping} [gamutMapping] Gamut mapping type, default is OKLCH chroma reduction.
    /// @returns {Struct.OKColor} The same OKColor instance that the method was called on, for method chaining.
    /// @description With this method you can mix additional color to the current one with a specified amount.
    static mix = function(mixColor/*:OKColor*/, amount/*:number*/, colorMixing/*:int<OKColorMixing>*/ = _colorMixingDefault, gamutMapping/*:int<OKColorMapping>*/ = _gamutMappingDefault)/*->OKColor*/ {
        /// @hint OKColor:mix(mixColor:OKColor, amount:number, ?colorMixing:int<OKColorMixing>?, ?gamutMapping:int<OKColorMapping>?)->OKColor Mix additional color to the current one with specified amount. Returns the same OKColor instance that the method was called on, for method chaining.
        
        // pre-mapping gives generally better results than after-mapping, with no "flat" colors
        _updateMapped(gamutMapping);
        mixColor._updateMapped(gamutMapping);
        
        method(self, _colorMixing[colorMixing] /*#as function<OKColor, number, void>*/)(mixColor, amount);
        
        return self;
    }
    
    /// @function cloneMixed(mixColor, amount, [colorMixing], [gamutMapping])
    /// @self OKColor
    /// @pure
    /// @param {Struct.OKColor} mixColor Additional color to mix with.
    /// @param {Real} amount How much to mix a color in 0-1 range.
    /// @param {Enum.OKColorMixing} [colorMixing] Color mixing type, default is OKLab interpolation.
    /// @param {Enum.OKColorMapping} [gamutMapping] Gamut mapping type, default is OKLCH chroma reduction.
    /// @returns {Struct.OKColor} New OKColor instance.
    /// @description  With this method you can get a new copy of OKColor struct with the additional color mixed.
    static cloneMixed = function(mixColor/*:OKColor*/, amount/*:number*/, colorMixing/*:int<OKColorMixing>*/ = _colorMixingDefault, gamutMapping/*:int<OKColorMapping>*/ = _gamutMappingDefault)/*->OKColor*/ {
        /// @hint OKColor:cloneMixed(mixColor:OKColor, amount:number, ?colorMixing:int<OKColorMixing>?, ?gamutMapping:int<OKColorMapping>?)->OKColor Get a new copy of OKColor struct with the additional color mixed.
        
        var newColor = variable_clone(self) /*#as OKColor*/;
        
        // pre-mapping gives generally better results than after-mapping, with no "flat" colors
        newColor._updateMapped(gamutMapping);
        mixColor._updateMapped(gamutMapping);
        
        method(newColor, _colorMixing[colorMixing] /*#as function<OKColor, number, void>*/)(mixColor, amount);
        
        return newColor;
    }
    
    #endregion
}

/// @hint {number} XYZStruct:x
/// @hint {number} XYZStruct:y
/// @hint {number} XYZStruct:z

/// @hint {bool} IColorCachedStruct:cached

/// @hint {number} RGBStruct:r
/// @hint {number} RGBStruct:g
/// @hint {number} RGBStruct:b

/// @hint RGBCachedStruct extends RGBStruct
/// @hint RGBCachedStruct implements IColorCachedStruct

/// @hint {number} HSVStruct:h
/// @hint {number} HSVStruct:s
/// @hint {number} HSVStruct:v

/// @hint HSVCachedStruct extends HSVStruct
/// @hint HSVCachedStruct implements IColorCachedStruct

/// @hint {number} HSLStruct:h
/// @hint {number} HSLStruct:s
/// @hint {number} HSLStruct:l

/// @hint HSLCachedStruct extends HSLStruct
/// @hint HSLCachedStruct implements IColorCachedStruct

/// @hint {number} LMSStruct:l
/// @hint {number} LMSStruct:m
/// @hint {number} LMSStruct:s

/// @hint LMSCachedStruct extends LMSStruct
/// @hint LMSCachedStruct implements IColorCachedStruct

/// @hint {number} LabStruct:l
/// @hint {number} LabStruct:a
/// @hint {number} LabStruct:b

/// @hint LabCachedStruct extends LabStruct
/// @hint LabCachedStruct implements IColorCachedStruct

/// @hint {number} LCHStruct:l
/// @hint {number} LCHStruct:c
/// @hint {number} LCHStruct:h

/// @hint LCHCachedStruct extends LCHStruct
/// @hint LCHCachedStruct implements IColorCachedStruct

/// @hint {number} Vector2Struct:x
/// @hint {number} Vector2Struct:y