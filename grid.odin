package grid

Grid_Dims :: struct
{
    width,height: int,
}

Pathfinding_Vtable :: struct(T: typeid)
{
    neighbors:      proc(g: ^Grid(T), x,y: int) -> []struct{idx: int, cost: f32},
    path_distance:  proc(g: ^Grid(T), x1,y1,x2,y2: int) -> f32,
}

Visibility_Vtable :: struct(T: typeid)
{
    is_opaque:      proc(g: ^Grid(T), x,y: int) -> bool,
}

Grid :: struct(T: typeid)
{
    using dims:             Grid_Dims,
    using pf_interface:     Pathfinding_Vtable(T),
    using vis_interface:    Visibility_Vtable(T),
    data:                   []T,
}

/*
    Takes a pointer to a new structure to initialize, allocating its array.

    width, height   : The width and height of the grid.
*/
init :: proc(g: ^Grid($T), width,height: int)
{
    g.dims = {width, height}
    g.data = make([]T, width * height) 
}

/*
    Initializes the grid and sets up a virtual interface for pathfinding functions.

    neighbors       : Function pointer to your function which returns an point's neighbors as an array of array indices with associated floating-point costs.
    path_distance   : Function pointer to your function which returns the distance cost between two points as a float.
*/
init_with_pathfinding :: proc(
    g: ^Grid($T), 
    width,height: int, 
    neighbors: proc(g: ^Grid(T), x,y: int) -> []struct{idx: int, cost: f32}, 
    path_distance: proc(g: ^Grid(T), x1,y1,x2,y2: int) -> f32)
{ 
    init(g, width, height)
    g.pf_interface = {neighbors, path_distance}
}

/*
    Initializes the grid and sets up a virtual interface for visibility functions.

    is_opaque       : Function pointer to your function which returns if a point should block visibility.
*/
init_with_visibility :: proc(
    g: ^Grid($T),
    width,height: int, 
    is_opaque: proc(g: ^Grid(T), x,y: int) -> bool)
{
    init(g, width, height)
    g.vis_interface = {is_opaque}
}

/*
    Initializes the grid with both pathfinding and visibility interfaces.
*/
init_all_interfaces :: proc(
    g: ^Grid($T), 
    width,height: int, 
    neighbors: proc(g: ^Grid(T), x,y: int) -> []struct{idx: int, cost: f32}, 
    path_distance: proc(g: ^Grid(T), x1,y1,x2,y2: int) -> f32,
    is_opaque: proc(g: ^Grid(T), x,y: int) -> bool)
{
    init(g, width, height)
    g.pf_interface = {neighbors, path_distance}
    g.vis_interface = {is_opaque}
}

/*
    Unloads a grid, deleting its associated data array.
*/
unload :: proc(g: ^Grid($T))
{ delete(g.data) }

/*
    Gets an array index in the grid from X,Y coordinates.
*/
index :: proc(g: Grid_Dims, x,y: int) -> int
{ return (y * g.width) + x }

/*
    Gets X,Y coordinates from an array index.
*/
reverse_index :: proc(g: Grid_Dims, idx: int) -> (x,y: int)
{  x = idx % g.width; y = idx / g.width; return }

/*
    Checks if X,Y coordinates are within the grid's dimensions.
*/
in_bounds :: proc(g: Grid_Dims, x,y: int) -> bool
{ return x > 0 && x < g.width && y > 0 && y < g.height }

/*
    Gets the value of the grid node at X,Y.
*/
get :: proc(g: ^Grid($T), x,y: int) -> T
{ return g.data[index(g,x,y)] }

/*
    Sets the value a grid node at X,Y.
*/
set :: proc(g: ^Grid($T), x,y: int, val: T)
{ g.data[index(g,x,y)] = val }



Grid_Iterator :: struct(T: typeid)
{
    grid:   ^Grid(T),
    idx:    int,
}

/*
    Creates an iterator for the grid.
*/
iterator :: proc(g: ^Grid($T)) -> Grid_Iterator(T)
{ return {g, 0} }

/*
    Iterates over each node in an iterator, returning the node value and a 2D X,Y Point.
*/
iter_nodes :: proc(g: ^Grid_Iterator($T)) -> (val: T, pt: Point2D, ok: bool)
{
    if g.idx == len(g.grid.data) { g.idx = 0; return }
    x,y := reverse_index(g.grid, g.idx)
    pt = {x,y}
    val = g.grid.data[g.idx]
    ok = true
    g.idx += 1
    return
}