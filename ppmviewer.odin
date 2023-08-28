package main
import "core:fmt"
import "core:image"
import "core:image/netpbm"
import "core:strconv"
import "core:strings"
import "core:os"

import "vendor:sdl2"

MINIMUM_WINDOW_WIDTH :: 200
MINIMUM_WINDOW_HEIGHT :: 100

SDL_CONTEXT :: struct
{
	window: ^sdl2.Window,
	surface: ^sdl2.Surface,
	renderer: ^sdl2.Renderer
}

sdl_context := SDL_CONTEXT{}

usage :: proc()
{
	fmt.println("ppmviewer - a basic PPM image viewer using SDL2")
	fmt.printf("\nUsage:\n")
	fmt.println("\tppmviewer.exe <.ppm file to view> [<render width override> <render height override>]")

	os.exit(1)
}

init_sdl :: proc(width, height: int) -> (bool)
{
	if init_result := sdl2.Init(sdl2.INIT_VIDEO); init_result < 0
	{
		fmt.eprintln("ERROR cannot initialize SDL")
		return false
	}

	// Shadow the variables to allow override if image is smaller than minimum window size.
	// Switch to i32 type since this is expected by SDL2.
	width := i32(width)
	height := i32(height)
	
	if len(os.args) >= 4
	{
		width_int, okw := strconv.parse_int(os.args[2])
		if !okw
		{
			fmt.eprintln("Invalid width argument.")
			os.exit(1)
		}
		width = i32(width_int)
		fmt.printf("Overriding image width with %d\n", width)

		height_int, okh := strconv.parse_int(os.args[3])
		if !okh
		{
			fmt.eprintln("Invalid height argument.")
			os.exit(1)
		}
		height = i32(height_int)
		fmt.printf("Overriding image height with %d\n", height)
	}

	if width < MINIMUM_WINDOW_WIDTH || height < MINIMUM_WINDOW_HEIGHT
	{
		width = MINIMUM_WINDOW_WIDTH
		height = MINIMUM_WINDOW_HEIGHT
	}

	bounds := sdl2.Rect{}
	if e := sdl2.GetDisplayBounds(0, &bounds); e != 0
	{
		fmt.eprintln("ERROR unable to get desktop bounds.")
		return false
	}

	window_xpos := ((bounds.w - bounds.x) / 2) - (width / 2) + bounds.x
	window_ypos := ((bounds.h - bounds.y) / 2) - (height / 2) + bounds.y

	sdl_context.window = sdl2.CreateWindow("PPM Viewer", window_xpos, window_ypos, width, height, sdl2.WindowFlags{.SHOWN})
	if sdl_context.window == nil
	{
		fmt.eprintln("ERROR create window failed")
		return false
	}

	sdl_context.renderer = sdl2.CreateRenderer(sdl_context.window, -1, {.ACCELERATED, .PRESENTVSYNC})
	if sdl_context.renderer == nil
	{
		fmt.eprintln("ERROR renderer creation failed")
		return false
	}

	return true
}

create_surface_from_ppm_image :: proc(ppm_image: ^image.Image, width: int, height: int) -> (^sdl2.Surface)
{
	rmask : u32 = 0x000000ff
	gmask : u32 = 0x0000ff00
	bmask : u32 = 0x00ff0000
	amask : u32 = 0
		
	return sdl2.CreateRGBSurfaceFrom(raw_data(ppm_image.pixels.buf), i32(width), i32(height), 24, i32(width * 3), rmask, gmask, bmask, amask)
}

draw :: proc(texture: ^sdl2.Texture, width: int, height: int)
{
	sdl2.SetRenderDrawColor(sdl_context.renderer, 0, 0, 0, 0xff)
	sdl2.RenderClear(sdl_context.renderer)

	sdl2.RenderCopy(sdl_context.renderer, texture, nil, nil)
	sdl2.RenderPresent(sdl_context.renderer)
}

shouldQuit :: proc() -> (bool)
{
	e : sdl2.Event

	for sdl2.PollEvent(&e)
	{
		if e.type == .QUIT || (e.type == .KEYDOWN && e.key.keysym.sym == .ESCAPE)
		{
			return true;
		}
	}

	return false
}

main :: proc()
{
	if len(os.args) < 2
	{
		usage()
	}

	filename : string = os.args[1]
	fmt.printf("Loading %s...\n", filename)

	ppm_image, error := netpbm.load_from_file(filename)
	if error != nil
	{
		fmt.eprintf("ERROR loading PPM file: %v\n", error)
	}

	width : int = ppm_image.width
	height : int = ppm_image.height
	fmt.printf("Width: %d, Height: %d\n", width, height)

	init_sdl(width, height)
	surface := create_surface_from_ppm_image(ppm_image, width, height)
	if surface == nil
	{
		fmt.eprintln("ERROR Could not create surface from image.")
		fmt.eprintf("%s", sdl2.GetError())
		os.exit(2)
	}

	texture := sdl2.CreateTextureFromSurface(sdl_context.renderer, surface)
	if texture == nil
	{
		fmt.eprintln("Could not convert surface to texture.")
		os.exit(2)
	}

	for !shouldQuit()
	{
		draw(texture, width, height)
	}
}
