# ppmviewer
A simple PPM image file viewer using SDL2 and written in Odin.

## Usage
```
ppmviewer.exe <.ppm file to view> [<render width override> <render height override>]
```
The programs has one mandatory argument which is the path to the PPM file to display.
Optionally you can specify a width and height override parameters. This allow you to see a image scaled in a smaller/bigger window. If using the override parameters, both are required.

All arguments are positional.

## Dependencies
Make sure that SDL2.dll is in the program's directory.

## Description
This is an extremely basic PPM image viewer and was created both as a first step in learning the Odin programming language and also to be used along side the raytracer created in the book "Ray Tracing in One Weekend" by Peter Shirley.

The program uses a minimum width and height (200x100) in order to be able to see the window, its controls and also be able to visualize extremely small images (e.g. 4x3) on a modern monitor.

## How to Build
In the source code folder:
```
odin build .
```