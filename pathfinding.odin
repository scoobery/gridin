package grid

import "core:slice"
import pq "core:container/priority_queue"
import q "core:container/queue"

Neighbor :: struct 
{
    idx:    int,
    cost:   f32,       
}

/*
    Gets the array indices of the points between two X and Y coordinates, ending in the destination coordinate.

    *NOTE* : All allocations in this algorithm use the `context.temp_allocator` to stack-allocate values, so it is advisable to `free_all(context.temp_allocator)` 
    periodically when you no longer need the results of an A* search.
*/
astar :: proc(g: ^Grid($T), from_x,from_y: int, to_x,to_y: int) -> (path: []int)
{
    if !in_bounds(g, from_x, from_y) { return }
    if !in_bounds(g, to_x, to_y) { return } 
    if !g->admissible(to_x, to_y) { return }

    start := index(g, from_x, from_y)
    end := index(g, to_x, to_y)

    Queue_Point :: struct {
        point: int,
        prio:  f32,
    }
    less :: proc(a,b: Queue_Point) -> bool { return a.prio < b.prio }

     // Priority queue to store points with costs attached to them.
    area : pq.Priority_Queue(Queue_Point)
    pq.init(&area, less, pq.default_swap_proc(Queue_Point), pq.DEFAULT_CAPACITY, context.temp_allocator)
    pq.push(&area, Queue_Point{start, 0})

    // Visitor map to track where each point was entered from.
    visitors := make_map(map[int]int, 1, context.temp_allocator)
    visitors[start] = start

    // Cost map to track grid point costs.
    current_cost := make_map(map[int]f32, 1, context.temp_allocator)
    current_cost[start] = 0

    for pq.len(area) > 0 {
        current := pq.pop(&area).point                              // Get the next point in the queue.
        if current == end do break                                  // Exit if we're at the goal.
        current_x, current_y := reverse_index(g, current)

        for n in g->neighbors(current_x, current_y) {               // Check each of this point's neighbors.
            next_x,next_y := reverse_index(g, n.idx)
            if !in_bounds(g, next_x, next_y) { continue }           // Don't touch this neighbor if it's OOB.
            new_cost := current_cost[current] + n.cost              // Insert to the cost map. Get the results.
            this_cost, next_exists := current_cost[n.idx]
            if !next_exists || new_cost < this_cost {               // Check that the cost didn't exist, or if the new one is less than the existing one.
                current_cost[n.idx] = new_cost                      // Set the cost for this point.
                calc_cost := new_cost +                             // The point we're adding to the queue will be enqueued with a priority of its cost,
                    g->path_distance(next_x, next_y, to_x, to_y) +  //    Plus a distance heuristic,
                    g->cost_modifier(next_x, next_y)                //    Plus the cell's cost modifier.
                pq.push(&area, Queue_Point{n.idx, calc_cost})       // Enqueue this point with its calculated cost.
                visitors[n.idx] = current                           // We visited this neighbor from the central point.
            }
        }
    }

    // Defines a dynamic array of points to represent the path.
    path_dyn := make([dynamic]int, context.temp_allocator)

    current := end                      // Work backwards from the goal point.
    for current != start {              // Until we hit the start point:
        append(&path_dyn, current)      // Add the current point to the path.
        current = visitors[current]     // Go to the next visitor in the path.
    }

    path = slice.clone(path_dyn[:], context.temp_allocator)     // Get the path slice.
    slice.reverse(path)                                         // Reverse the slice (so that it comes back start to finish).

    return
}

/*
    Gets the array indices of all points within a flood fill to the specified distance from one point.
*/
flood_fill :: proc(g: ^Grid($T), from_x,from_y: int, dist: f32, include_costs := false) -> []int
{
    if !in_bounds(g, from_x, from_y) { return {} }

    start := index(g, from_x, from_y)

    area: q.Queue(int)
    q.init(&area, q.DEFAULT_CAPACITY, context.temp_allocator)
    q.push_front(&area, start)

    dfill := make_map(map[int]int, 1, context.temp_allocator)
    dists := make_map(map[int]f32, 1, context.temp_allocator)
    dists[start] = 0

    for q.len(area) > 0 {
        current := q.pop_front(&area)
        cx,cy := reverse_index(g, current)
        for n in g->neighbors(cx,cy) {
            if n.idx in dfill { continue }
            nx,ny := reverse_index(g, n.idx)
            if !g->admissible(nx,ny) { continue }
            nd := g->path_distance(cx,cy,nx,ny) + dists[current]
            if include_costs {
                nd += g->cost_modifier(nx,ny)
            }
            dists[n.idx] = nd
            switch {
            case nd < dist:
                dfill[n.idx] = n.idx
                q.push_back(&area, n.idx)
            case nd == dist:
                dfill[n.idx] = n.idx
            }
        }
    }

    fill, err := slice.map_values(dfill, context.temp_allocator)
    return fill
}