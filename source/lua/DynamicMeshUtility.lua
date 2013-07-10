// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\DynamicMeshUtility.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com) 
//    
//    Some utility functions to create most common shapes (double sided lines, triangles, rectangles etc.)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function DynamicMesh_Create()
    return Client.CreateRenderDynamicMesh(RenderScene.Zone_Default)
end

function DynamicMesh_Destroy(mesh)
    Client.DestroyRenderDynamicMesh(mesh)
end

function DynamicMesh_SetRectangle(mesh, point1, point2, normal, width)
    // TODO:
end

local kLineWidth = 0.88
local kSquareTexCoords = { 1,1, 0,1, 0,0, 1,0 }
local kSquareIndices = { 3, 0, 1, 1, 2, 3 }
local kSquareColors = { 1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1, }
function UpdateOrderLine(startPoint, endPoint, line)

    startPoint = startPoint + Vector(0, kZFightingConstant, 0)
    endPoint = endPoint + Vector(0, kZFightingConstant, 0)

    local pathVector = endPoint - startPoint
    pathVector.y = 0
    local sideVector = pathVector:CrossProduct(Vector(0, 1, 0))

    sideVector:Normalize()
    sideVector:Scale(kLineWidth)

    local meshVertices = {
    
        endPoint.x + sideVector.x, endPoint.y, endPoint.z + sideVector.z,
    
        endPoint.x - sideVector.x, endPoint.y, endPoint.z - sideVector.z,
        
        startPoint.x - sideVector.x, startPoint.y, startPoint.z - sideVector.z,
        
        startPoint.x + sideVector.x, startPoint.y, startPoint.z + sideVector.z,
        
    }

    
    line:SetIndices(kSquareIndices, #kSquareIndices)
    line:SetTexCoords(kSquareTexCoords, #kSquareTexCoords)
    line:SetVertices(meshVertices, #meshVertices)
    line:SetColors(kSquareColors, #kSquareColors)

end

function DynamicMesh_SetLine(mesh, coords, width, length, startColor, endColor)

    if not startColor then
        startColor = Color(1,1,1,1)
    end

    if not endColor then
        endColor = Color(1,1,1,1)
    end    

    local startPoint = Vector(0,0,0)
    local endPoint = Vector(0,0,length)
    local sideVector = Vector(width, 0, 0)
    
    local meshVertices = {
    
        endPoint.x + sideVector.x, endPoint.y, endPoint.z + sideVector.z,
    
        endPoint.x - sideVector.x, endPoint.y, endPoint.z - sideVector.z,
        
        startPoint.x - sideVector.x, startPoint.y, startPoint.z - sideVector.z,
        
        startPoint.x + sideVector.x, startPoint.y, startPoint.z + sideVector.z,
        
    }
    
    local colors = {
        endColor.r, endColor.g, endColor.b, endColor.a,
        endColor.r, endColor.g, endColor.b, endColor.a,    
        startColor.r, startColor.g, startColor.b, startColor.a,
        startColor.r, startColor.g, startColor.b, startColor.a,
    }

    mesh:SetIndices(kSquareIndices, #kSquareIndices)
    mesh:SetTexCoords(kSquareTexCoords, #kSquareTexCoords)
    mesh:SetVertices(meshVertices, #meshVertices)
    mesh:SetColors(colors, #colors)
    mesh:SetCoords(coords)
    
end

function DynamicMesh_SetPathMesh(mesh, pathPoints, lineWidth, defaultColor)

    local indices = { }
    local indexArrayIndex = 1
    local currentIndex = 0
    local texCoords = { }
    local texIndex = 1
    local vertices = { }
    local vertIndex = 1
    local colors = { }
    local colorIndex = 1
    local previousPoint = nil
    local rightPrevPoint = nil
    local leftPrevPoint = nil
    local totalPathDistance = 0
    
    for i, point in ipairs(pathPoints) do
        
        local sideVector = Vector(0, 0, 0)
        if previousPoint then
        
            local pathPartVector = previousPoint - point
            sideVector = pathPartVector:CrossProduct(Vector(0, 1, 0)) * lineWidth
            totalPathDistance = totalPathDistance + pathPartVector:GetLength()
            
        end
        local leftPoint = point - sideVector + Vector(0, -0.75, 0)
        local rightPoint = point + sideVector + Vector(0, -0.75, 0)
        
        if rightPrevPoint and leftPrevPoint then
            
            local rightPrevPointIndex = currentIndex
            currentIndex = currentIndex + 1
            
            vertices[vertIndex] = rightPrevPoint.x
            vertices[vertIndex + 1] = rightPrevPoint.y
            vertices[vertIndex + 2] = rightPrevPoint.z
            vertIndex = vertIndex + 3
            
            texCoords[texIndex] = 1
            texCoords[texIndex + 1] = 1
            texIndex = texIndex + 2
            
            colors[colorIndex] = defaultColor.r
            colors[colorIndex + 1] = defaultColor.g
            colors[colorIndex + 2] = defaultColor.b
            colors[colorIndex + 3] = defaultColor.a
            colorIndex = colorIndex + 4
            
            local leftPrevPointIndex = currentIndex
            currentIndex = currentIndex + 1
            
            vertices[vertIndex] = leftPrevPoint.x
            vertices[vertIndex + 1] = leftPrevPoint.y
            vertices[vertIndex + 2] = leftPrevPoint.z
            vertIndex = vertIndex + 3
            
            texCoords[texIndex] = 0
            texCoords[texIndex + 1] = 1
            texIndex = texIndex + 2
            
            colors[colorIndex] = defaultColor.r
            colors[colorIndex + 1] = defaultColor.g
            colors[colorIndex + 2] = defaultColor.b
            colors[colorIndex + 3] = defaultColor.a
            colorIndex = colorIndex + 4
            
            local leftPointIndex = currentIndex
            currentIndex = currentIndex + 1
            
            vertices[vertIndex] = leftPoint.x
            vertices[vertIndex + 1] = leftPoint.y
            vertices[vertIndex + 2] = leftPoint.z
            vertIndex = vertIndex + 3
            
            texCoords[texIndex] = 0
            texCoords[texIndex + 1] = 0
            texIndex = texIndex + 2
            
            colors[colorIndex] = defaultColor.r
            colors[colorIndex + 1] = defaultColor.g
            colors[colorIndex + 2] = defaultColor.b
            colors[colorIndex + 3] = defaultColor.a
            colorIndex = colorIndex + 4
            
            local rightPointIndex = currentIndex
            currentIndex = currentIndex + 1
            
            vertices[vertIndex] = rightPoint.x
            vertices[vertIndex + 1] = rightPoint.y
            vertices[vertIndex + 2] = rightPoint.z
            vertIndex = vertIndex + 3
            
            texCoords[texIndex] = 1
            texCoords[texIndex + 1] = 0
            texIndex = texIndex + 2
            
            colors[colorIndex] = defaultColor.r
            colors[colorIndex + 1] = defaultColor.g
            colors[colorIndex + 2] = defaultColor.b
            colors[colorIndex + 3] = defaultColor.a
            colorIndex = colorIndex + 4
            
            indices[indexArrayIndex] = rightPointIndex
            indices[indexArrayIndex + 1] = rightPrevPointIndex
            indices[indexArrayIndex + 2] = leftPrevPointIndex
            
            indices[indexArrayIndex + 3] = leftPrevPointIndex
            indices[indexArrayIndex + 4] = leftPointIndex
            indices[indexArrayIndex + 5] = rightPointIndex
            indexArrayIndex = indexArrayIndex + 6
            
        end
        
        previousPoint = point
        rightPrevPoint = rightPoint
        leftPrevPoint = leftPoint
        
    end
    
    mesh:SetIndices(indices, #indices)
    mesh:SetTexCoords(texCoords, #texCoords)
    mesh:SetVertices(vertices, #vertices)
    mesh:SetColors(colors, #colors)
    
    return indices, texCoords, vertices, colors, totalPathDistance

end

local kTwoSidedSquareTexCoords = { 1,1, 0,1, 0,0, 1,0,  1,0,  0,0,  0,1,  1,1}
local kTwoSidedSquareIndices = { 3, 0, 1, 1, 2, 3, 1, 0, 3, 3, 2, 1, }
function DynamicMesh_SetTwoSidedLine(mesh, coords, width, length, startColor, endColor)

    if not startColor then
        startColor = Color(1,1,1,1)
    end

    if not endColor then
        endColor = Color(1,1,1,1)
    end    

    local startPoint = Vector(0,0,0)
    local endPoint = Vector(0,0,length)
    local sideVector = Vector(width, 0, 0)
    
    local meshVertices = {
    
        endPoint.x + sideVector.x, endPoint.y, endPoint.z + sideVector.z,
    
        endPoint.x - sideVector.x, endPoint.y, endPoint.z - sideVector.z,
        
        startPoint.x - sideVector.x, startPoint.y, startPoint.z - sideVector.z,
        
        startPoint.x + sideVector.x, startPoint.y, startPoint.z + sideVector.z,
        
    }
    
    local colors = {
        endColor.r, endColor.g, endColor.b, endColor.a,
        endColor.r, endColor.g, endColor.b, endColor.a,    
        startColor.r, startColor.g, startColor.b, startColor.a,
        startColor.r, startColor.g, startColor.b, startColor.a,
        startColor.r, startColor.g, startColor.b, startColor.a,
        endColor.r, endColor.g, endColor.b, endColor.a,
        endColor.r, endColor.g, endColor.b, endColor.a,
    }

    mesh:SetIndices(kTwoSidedSquareIndices, #kTwoSidedSquareIndices)
    mesh:SetTexCoords(kTwoSidedSquareTexCoords, #kTwoSidedSquareTexCoords)
    mesh:SetVertices(meshVertices, #meshVertices)
    mesh:SetColors(colors, #colors)
    mesh:SetCoords(coords)
    
end