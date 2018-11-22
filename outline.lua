--[[
==Pixel Outline v1.00 (LUA)==
Outlines current layer with 1px of fg colour

By Rik Nicol / @hot_pengu / https://github.com/rikfuzz/aseprite-scripts

Requirements
Aseprite (Currently requires Aseprite v1.2.10-beta2)
Click "Open Scripts Folder" in File > Scripts and drag the script into the folder.
]]--


local newImage = Image(app.activeImage.width+20,app.activeImage.height+2)
newImage:putImage(app.activeImage,1,1)

local function clrpx(color)
    return app.pixelColor.rgba(color.red, color.green, color.blue, color.alpha)
end

local outlineColor = app.fgColor;
outlineColor = clrpx(outlineColor);

local function isTransparent(a)
    return app.pixelColor.rgbaA(a) == 0
end

local function getPixel(x,y)
    if(x>=newImage.width) then
        return app.pixelColor.rgba(0, 0, 0, 0) 
    end
    if(y>=newImage.height) then
        return app.pixelColor.rgba(0, 0, 0, 0) 
    end
    if(x<0) then
        return app.pixelColor.rgba(0, 0, 0, 0) 
    end
    if(y<0) then
        return app.pixelColor.rgba(0, 0, 0, 0) 
    end
    return newImage:getPixel(x, y)
end

local function putPixel(color,x,y)
    return newImage:putPixel(x, y, color)
end


local outlinePlacesX = {};
local outlinePlacesY = {};
local function pushOutline(x,y)
    table.insert(outlinePlacesX,x)
    table.insert(outlinePlacesY,y)
end

local function ol()
    local testGrid = {};
    local imageGrid = {};

    for y=0,newImage.height do
        for x=0,newImage.width do

            if isTransparent(getPixel(x,y)) and
            (not isTransparent(getPixel(x-1,y)) or
            not isTransparent(getPixel(x+1,y)) or
            not isTransparent(getPixel(x,y+1)) or
            not isTransparent(getPixel(x,y-1))) then
                pushOutline(x,y)
            end

        end
    end

    for i=1,#outlinePlacesX do
        putPixel(outlineColor,outlinePlacesX[i],outlinePlacesY[i])
    end
end

ol()
app.activeCel.position = {x=app.activeCel.position.x-1,y=app.activeCel.position.y-1}

app.activeCel.image = newImage;
