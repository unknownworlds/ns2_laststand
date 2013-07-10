// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
//
// lua\RingBuffer.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// Implementation of a ring buffer.
//
// ========= For more information, visit us at http://www.unknownworlds.com =======================

local function Insert(self, insertElement)

    self.currentPos = self.currentPos + 1
    if self.numElements == self.size then
    
        if self.currentPos > self.size then
            self.currentPos = 1
        end
        self.buffer[self.currentPos] = insertElement
        
    else
    
        table.insert(self.buffer, insertElement)
        self.numElements = self.numElements + 1
        
    end
    
end

local function GetNumElements(self)
    return self.numElements
end

local function ToTable(self)

    local numElements = self:GetNumElements()
    local array = table.array(numElements)
    
    local currentIndex = self.currentPos + 1
    currentIndex = currentIndex <= numElements and currentIndex or 1
    
    local numIterated = 0
    while numIterated < numElements do
    
        table.insert(array, self.buffer[currentIndex])
        
        currentIndex = currentIndex + 1
        currentIndex = currentIndex <= self.size and currentIndex or 1
        
        numIterated = numIterated + 1
        
    end
    
    return array
    
end

function CreateRingBuffer(setSize)

    assert(type(setSize) == "number")
    assert(setSize > 0)
    
    return { buffer = table.array(setSize), size = setSize, currentPos = 0, numElements = 0,
             Insert = Insert, GetNumElements = GetNumElements, ToTable = ToTable }
    
end

------ TESTS ------

local testRingBuffer = CreateRingBuffer(3)

assert(testRingBuffer:GetNumElements() == 0)
assert(#testRingBuffer:ToTable() == 0)

testRingBuffer:Insert("one")

assert(testRingBuffer:GetNumElements() == 1)
assert(#testRingBuffer:ToTable() == 1)

testRingBuffer:Insert("two")
testRingBuffer:Insert("three")

assert(testRingBuffer:GetNumElements() == 3)
assert(testRingBuffer:ToTable()[1] == "one")
assert(testRingBuffer:ToTable()[2] == "two")
assert(testRingBuffer:ToTable()[3] == "three")

testRingBuffer:Insert("four")
assert(testRingBuffer:GetNumElements() == 3)
assert(testRingBuffer:ToTable()[1] == "two")
assert(testRingBuffer:ToTable()[2] == "three")
assert(testRingBuffer:ToTable()[3] == "four")

testRingBuffer:Insert("five")
testRingBuffer:Insert("six")
testRingBuffer:Insert("seven")

assert(testRingBuffer:GetNumElements() == 3)
assert(testRingBuffer:ToTable()[1] == "five")
assert(testRingBuffer:ToTable()[2] == "six")
assert(testRingBuffer:ToTable()[3] == "seven")