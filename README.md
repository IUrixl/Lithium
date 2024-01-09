# Lithium
Lithium is a 3D rendering engine fully coded in Batch.

## How does it works
It reads a model, makes the points and then connect the points using the Bresenham's algorithm to connect them in any octant. For the third dimension a weak perspective is rendered.

Since batch display model i use its kinda slow dont expect it to be fast! Its still on work and im trying to find a way to optimize it.

Also, it makes a register to change the font to a bitmap 8x8, so the pixels are squares and not rectangles.

## Creating a model
To create a model make a file and name it "mymodel.lith". Then u can define the vertex writing in a new line their coords.
Example :
```
10 0 1
X  Y Z
```

## Joining vertex
As easy as writing #number, number being the vertex index u want to connect.
Example :
```
10 0 1 #1
30 0 1
```

## Model settings
U can set the X/Y Offset of a model by writing ? and then x|number and y|number
Example : 
```
? x|5 y|5
```

## Simple 3d cube
```
? x|1 y|10

10 0 1 #2 #5
65 0 1 #3 #6
65 55 1 #4 #7
10 55 1 #1 #8
10 0 2 #6
65 0 2 #7
65 55 2 #8
10 55 2 #5
```
