package grid

import "core:math"

distance2d_pythagoras :: proc(start_x, start_y, end_x, end_y: int) -> f32
{
    dx := f32(math.max(start_x, end_x) - math.min(start_x, end_x))
    dy := f32(math.max(start_y, end_y) - math.min(start_y, end_y))
    return math.sqrt((dx * dx) + (dy * dy))
}

distance2d_manhattan :: proc(start_x, start_y, end_x, end_y: int) -> f32
{
    dx := f32(math.max(start_x, end_x) - math.min(start_x, end_x))
    dy := f32(math.max(start_y, end_y) - math.min(start_y, end_y))
    return dx + dy
}