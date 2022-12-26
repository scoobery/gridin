package grid

Point2D :: [2]int

UP_LEFT     :: Point2D{-1, -1}
UP          :: Point2D{0, -1}
UP_RIGHT    :: Point2D{1, -1}
LEFT        :: Point2D{-1, 0}
CENTER      :: Point2D{0, 0}
RIGHT       :: Point2D{1, 0}
DOWN_LEFT   :: Point2D{-1, 1}
DOWN        :: Point2D{0, 1}
DOWN_RIGHT  :: Point2D{1, 1}

cardinal_directions :: proc() -> [4]Point2D
{ return {UP, LEFT, RIGHT, DOWN} }

eight_directions :: proc() -> [8]Point2D 
{ return {UP_LEFT, UP, UP_RIGHT, LEFT, RIGHT, DOWN_LEFT, DOWN, DOWN_RIGHT} }