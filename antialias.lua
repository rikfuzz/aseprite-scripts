--[[
==Pixel Antialias v1.00 (LUA)==
Antialiases inside the foreground colour anywhere it touches the background colour (automatically picks a colour inbetween the two).
(Swap fg/bg colours before running to reverse)
This is a pixel-art style antialias, only adding 1 new colour with a max length of 2 on the antialis pixels per side.

By Rik Nicol / @hot_pengu / https://github.com/rikfuzz/aseprite-scripts

Requirements
Aseprite (Currently requires Aseprite v1.2.10-beta2)
Click "Open Scripts Folder" in File > Scripts and drag the script into the folder.
]]--



local anycolor = false; -- set true to antialises the edge of the foreground colour no matterwhat colour is bordering it
local extraSmooth = false; --set true to run an extra process over the outside of the forground colour, usually only makes a minor addition and is quite SLOW  

local canvas; 
if app.activeSprite.selection.bounds.width>0 then 
    canvas = {
        x = app.activeSprite.selection.bounds.x,
        y = app.activeSprite.selection.bounds.y,
        width = app.activeSprite.selection.bounds.width,
        height = app.activeSprite.selection.bounds.height
    };
else 
    canvas = {
        x = 0,
        y = 0,
        width = app.activeImage.width,
        height = app.activeImage.height
    };
end

local newImage = app.activeImage:clone()

local function clrpx(color)
    return app.pixelColor.rgba(color.red, color.green, color.blue, color.alpha)
end

local bodyColor = app.fgColor;
local outerColor = app.bgColor;
local antiAliasColor = Color{
    r=math.floor((bodyColor.red + outerColor.red)/2), 
    g=math.floor((bodyColor.green + outerColor.green)/2),
    b=math.floor((bodyColor.blue + outerColor.blue)/2),
    a=255};

antiAliasColor.hsvSaturation = (bodyColor.hsvSaturation + outerColor.hsvSaturation)/2;

bodyColor = clrpx(bodyColor);
outerColor = clrpx(outerColor);
antiAliasColor = clrpx(antiAliasColor);

local function clreq(a, b)
    --if a==false then return false end
    --if b==false then return false end

    return app.pixelColor.rgbaR(a) == app.pixelColor.rgbaR(b) and
        app.pixelColor.rgbaG(a) == app.pixelColor.rgbaG(b) and
        app.pixelColor.rgbaB(a) == app.pixelColor.rgbaB(b) 
end

local function getPixel(x,y)
    return newImage:getPixel(x, y)
end

local function putPixel(color,x,y)
    return newImage:putPixel(x, y, color)
end

local function getGrid(cx,cy)
    local grid = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
    for y=0, 4 do
        for x=0, 4 do
            local clr = getPixel(cx + x-2,cy + y-2);
            local cell = 0;

            if (clreq(clr,bodyColor)) then
                cell = 1;
            elseif(not anycolor and clreq(clr,outerColor)) then
                cell = 5;
            elseif(clreq(clr,antiAliasColor)) then
                cell = 4;
            end      

            grid[y*5+x+1] = cell;
        end
    end
    return grid;
end

local function rotateGrid(testGrid)
    local newGrid = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
    local i = 1
    for x=0, 4 do
        for y=4, 0,-1 do
            local gridPos = y*5+x;
            newGrid[i] = testGrid[gridPos+1];
            i = i + 1
        end
    end
    return newGrid;
end
local function flipGrid(testGrid)
    local newGrid = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
    local i =1
    for y=0, 4 do
        for x=4,0,-1 do
            local gridPos = y*5+x;
            newGrid[i] = testGrid[gridPos+1];
            i = i + 1
        end
    end
    return newGrid;
end

local function testPixels(testGrid,imageGrid)
    for i=1,#testGrid do

        if testGrid[i] == 0 then
            --nothing
        else
            if ((testGrid[i] == 1 or testGrid[i] == 3) and testGrid[i] ~= imageGrid[i])then
                return false;
            elseif (testGrid[i]==2 and ((anycolor and (imageGrid[i]==1 or imageGrid[i]==3))or(not(anycolor) and imageGrid[i]~=5)))then               
                return false;
            elseif (testGrid[i]==4 and imageGrid[i]==3) then
                return false;
            end
        end

    end
    return true
end

local function testPixelsAnyRotation(testGrid,imageGrid)
    local grids = {};
    local grid1 = testGrid;
    local grid2 = rotateGrid(grid1);
    local grid3 = rotateGrid(grid2);
    local grid4 = rotateGrid(grid3);
    local grid5 = flipGrid(grid1);
    local grid6 = flipGrid(grid2);
    local grid7 = flipGrid(grid3);
    local grid8 = flipGrid(grid4);
    grids = {grid1,grid2,grid3,grid4,grid5,grid6,grid7,grid8};
    for i=1,8 do
        if testPixels(grids[i],imageGrid) then
            return true
        end
    end
    return false 
end

local aliasPlacesX = {};
local aliasPlacesY = {};
local bodyPlacesX = {};
local bodyPlacesY = {};
local function pushAA(x,y)
    table.insert(aliasPlacesX,x)
    table.insert(aliasPlacesY,y)
end
local function pushB(x,y)
    table.insert(bodyPlacesX,x)
    table.insert(bodyPlacesY,y)
end

local function aa()
    local testGrid = {};
    local imageGrid = {};

    for y=1+canvas.y,canvas.y+canvas.height-2 do
        for x=1+canvas.x,canvas.x+canvas.width-2 do

            if (clreq(getPixel(x,y),bodyColor) and 
            not(clreq(getPixel(x-1,y),bodyColor) and 
            clreq(getPixel(x+1,y),bodyColor) and
            clreq(getPixel(x,y-1),bodyColor) and
            clreq(getPixel(x,y+1),bodyColor))) then
                imageGrid = getGrid(x,y);
                testGrid = {
                    0,0,0,0,0,
                    0,0,2,2,0,
                    0,2,0,1,0,
                    0,0,1,0,0,
                    0,0,0,0,0
                }; 
                if testPixelsAnyRotation(testGrid,imageGrid) then
                    pushAA(x,y);
                else
                    testGrid = {
                        0,0,0,0,0,
                        0,2,2,2,0,
                        2,1,0,0,0,
                        0,0,0,0,0,
                        0,0,0,0,0
                    };
                    if testPixelsAnyRotation(testGrid,imageGrid) then
                        pushAA(x,y);
                    else
                        testGrid = {
                            0,0,0,0,0,
                            0,2,2,2,2,
                            0,0,0,2,0,
                            0,0,0,0,0,
                            0,0,0,0,0
                        };
                        if testPixelsAnyRotation(testGrid,imageGrid) then
                            pushAA(x,y);
                        end
                    end                    
                end
            end
        end
    end

    for i=1,#aliasPlacesX do
        putPixel(antiAliasColor,aliasPlacesX[i],aliasPlacesY[i])
    end

    if(extraSmooth)then
        aliasPlacesX={}
        aliasPlacesY={}
        for y=1+canvas.y,canvas.y+canvas.height-2 do
            for x=1+canvas.x,canvas.x+canvas.width-2 do
                if not clreq(getPixel(x,y),bodyColor) then
                    imageGrid = getGrid(x,y);
                    testGrid = {
                        0,0,0,0,0,
                        0,0,2,2,1,
                        0,2,0,1,0,
                        0,1,1,0,0,
                        0,0,0,0,0
                    }; 
                    if testPixelsAnyRotation(testGrid,imageGrid) then
                        pushAA(x,y);
                    end
                end
            end
        end
        for i=1,#aliasPlacesX do
            putPixel(antiAliasColor,aliasPlacesX[i],aliasPlacesY[i])
        end
    end
end

aa()
app.activeImage:putImage(newImage)

