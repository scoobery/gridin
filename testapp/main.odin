package main

import grid "shared:gridin"
import rl "vendor:raylib"
import "core:fmt"
import "core:slice"

valid_exit :: proc(g: ^grid.Grid(int), x1,y1,x2,y2: int) -> Maybe(int)
{
    dest := grid.Point2D{x1 + x2, y1 + y2}
    if grid.in_bounds(g, dest.x, dest.y) && g->admissible(dest.x, dest.y) {
        return grid.index(g, dest.x, dest.y)
    }
    return nil
}

map_neighbors :: proc(g: ^grid.Grid(int), x,y: int) -> []grid.Neighbor
{
    exits_dyn := make([dynamic]grid.Neighbor, context.temp_allocator)
    for p in grid.eight_directions() {
        idx, ok := valid_exit(g, x, y, p.x, p.y).?
        if ok { 
            result := grid.Neighbor{idx, (p.x != 0 && p.y != 0) ? 1.45 : 1.0}
            append(&exits_dyn, result)
        }
    }
    exits := slice.clone(exits_dyn[:], context.temp_allocator)
    return exits
}

map_path_distance :: proc(g: ^grid.Grid(int), x1, y1, x2, y2: int) -> f32
{
    return grid.distance2d_pythagoras(x1, y1, x2, y2)
}

map_cost_mod :: proc(g: ^grid.Grid(int), x,y: int) -> f32
{
    return f32(grid.get(g,x,y))
}

map_admissible :: proc(g: ^grid.Grid(int), x,y: int) -> bool 
{
    return grid.get(g,x,y) >= 0
}

main :: proc()
{
    GRID_SIZE :: 96

    tiles:  grid.Grid(int)
    currentTile: grid.Point2D
    hoveredTile: grid.Point2D

    rl.SetConfigFlags(rl.ConfigFlags{.WINDOW_RESIZABLE})
    rl.InitWindow(800, 450, "Pathfinding Test")
    defer rl.CloseWindow()

    grid.init_with_pathfinding(&tiles, 10, 10, map_neighbors, map_path_distance, map_admissible, map_cost_mod)
    grid.set(&tiles, 4, 4, -1)
    grid.set(&tiles, 4, 5, -1)
    grid.set(&tiles, 5, 4, -1)
    grid.set(&tiles, 5, 5, -1)

    for !rl.WindowShouldClose() {
        grid_pos := rl.GetMousePosition()
        grid_pos.x = grid_pos.x / GRID_SIZE
        grid_pos.y = grid_pos.y / GRID_SIZE

        if grid.in_bounds(&tiles, int(grid_pos.x), int(grid_pos.y)) {
            hoveredTile = {int(grid_pos.x), int(grid_pos.y)}
        }
        if rl.IsMouseButtonPressed(.LEFT) {
            currentTile = hoveredTile
        }

        astar_path := grid.astar(&tiles, currentTile.x, currentTile.y, hoveredTile.x, hoveredTile.y)

        rl.BeginDrawing()
            rl.ClearBackground(rl.DARKGRAY)
            for y in 0..<tiles.dims.height {
                for x in 0..<tiles.dims.height {
                    pos := grid.Point2D{x,y}
                    box_color := pos == currentTile ? rl.YELLOW : rl.BLACK
                    line_color := pos == hoveredTile ? rl.RED : rl.RAYWHITE
                    rl.DrawRectangle(i32(x * GRID_SIZE), i32(y * GRID_SIZE), GRID_SIZE, GRID_SIZE, box_color)
                    rl.DrawRectangleLines(i32(x * GRID_SIZE), i32(y * GRID_SIZE), GRID_SIZE, GRID_SIZE, line_color)
                    rl.DrawText(rl.TextFormat("%d", grid.get(&tiles,x,y)), i32(x * GRID_SIZE) + 2, i32(y * GRID_SIZE) + 2, 20, rl.RAYWHITE)
                }
            }

            if len(astar_path) > 0 {
                for idx in astar_path {
                    x,y := grid.reverse_index(&tiles, idx)
                    rl.DrawCircle(i32(x * GRID_SIZE) + (GRID_SIZE / 2), i32(y * GRID_SIZE) + (GRID_SIZE / 2), 24, rl.RED)       
                }
            }

           rl.DrawFPS(2, 2)
        rl.EndDrawing()

        free_all(context.temp_allocator)
    }
}
