package grid

import "core:slice"
import pq "core:container/priority_queue"

astar :: proc(g: ^Grid($T), from_x,from_y: int, to_x,to_y: int) -> (path: []int)
{
    if !in_bounds(g, from_x, from_y) { return }
    if !in_bounds(g, to_x, to_y) { return }

    start := index(g, from_x, from_y)
    end := index(g, to_x, to_y)
    found := false

    Queue_Point :: struct 
    {
        point: int,
        prio:  f32,
    }
    less :: proc(a,b: Queue_Point) -> (res: bool)
    { return a.prio < b.prio }

     // Priority queue to store points with costs attached to them.
    area : pq.Priority_Queue(Queue_Point)
    defer pq.destroy(&area)
    pq.init(&area, less, pq.default_swap_proc(Queue_Point))
    pq.push(&area, Queue_Point{start, 0})

    // Visitor map to track where each point was entered from.
    visitors := make_map(map[int]int)
    defer delete_map(visitors)
    visitors[start] = start

    // Cost map to track grid point costs.
    current_cost := make_map(map[int]f32)
    defer delete_map(current_cost)
    current_cost[start] = 0

    for pq.len(area) > 0 {
        current := pq.pop(&area).point                                      // Get the next point in the queue.
        if current == end { found = true; break }                           // Exit if we're at the goal.
        current_x, current_y := reverse_index(g, current)
        for n in g->neighbors(current_x, current_y) {                       // Check each of this point's neighbors.
            next_x,next_y := reverse_index(g, n.idx)
            if !in_bounds(g, next_x, next_y) { continue }                   // Don't touch this neighbor if it's OOB.
            new_cost := current_cost[current] + n.cost                      // Insert to the cost map. Get the results.
            this_cost, next_exists := current_cost[n.idx]
            if !next_exists || new_cost < this_cost {                       // Check that the cost didn't exist, or if the new one is less that the exi
                current_cost[n.idx] = new_cost                              // Set the cost for this point.
                // Enqueue this point with its cost plus a heuristic. 
                //(In this case the raw distance.)
                pq.push(&area, Queue_Point{n.idx, new_cost + g->path_distance(next_x, next_y, to_x, to_y)})
                visitors[n.idx] = current                                    // We visited this neighbor from the central point.
            }
        }
    }

    // Defines a dynamic array of points to represent the path.
    path_dyn := make([dynamic]int)
    defer delete_dynamic_array(path_dyn)

    current := end                      // Work backwards from the goal point.
    for current != start {              // Until we hit the start point:
        append(&path_dyn, current)      // Add the current point to the path.
        current = visitors[current]     // Go to the next visitor in the path.
    }

    path = slice.clone(path_dyn[:])     // Get the path slice.
    slice.reverse(path)                 // Reverse the slice (so that it comes back start to finish).
    return
}