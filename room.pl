% ===== DYNAMIC DECLARATIONS (must come first) =====
:- dynamic position/4.
:- dynamic occupies/4.
:- dynamic at/4.

% ===== ROOMS =====
room(sleeping).
room(kitchen).
connected(sleeping, kitchen).

% ===== THE ROBOT (agent that moves) =====
at(robot, kitchen, 3, 6).

    furniture(table).
    furniture(dining_table).
    furniture(chair1). furniture(chair2). furniture(chair3).
    furniture(chair4). furniture(chair5).
    furniture(plant1). furniture(plant2).
    furniture(television).
    furniture(bed).
    furniture(wardrobe).
    furniture(fridge).
    furniture(oven).
    furniture(dishwasher).
    furniture(sink).
    furniture(shelves).
    furniture(dog_plate).

    accessory(amplifier).
    accessory(electric_guitar).

    pet(dog).

    structure(wall).
    structure(door).

    % positioning all of those things now:

    position(plant1,         sleeping, 1, 1).
    position(table,          sleeping, 3, 1).   % also covers (4,1)
    position(shelves,        sleeping, 6, 1).
    position(bed,            sleeping, 1, 2).   % also covers (1,3)
    position(chair1,         sleeping, 4, 2).
    position(amplifier,      sleeping, 6, 2).
    position(electric_guitar,sleeping, 6, 3).

    % --- Doors in the dividing wall (Y5) ---
    position(door,           sleeping, 4, 5).
    position(door,           sleeping, 5, 5).

    % --- Kitchen / living (bottom, Y6–Y11) ---
    position(chair2,         kitchen, 1, 6).
    position(wardrobe,       kitchen, 6, 6).
    position(dining_table,   kitchen, 1, 7).
    position(chair3,         kitchen, 2, 7).
    position(chair4,         kitchen, 2, 8).
    position(television,     kitchen, 6, 8).
    position(chair5,         kitchen, 1, 9).
    position(dog_plate,      kitchen, 1, 10).
    position(dog,            kitchen, 2, 10).
    position(fridge,         kitchen, 1, 11).
    position(sink,           kitchen, 2, 11).
    position(oven,           kitchen, 3, 11).
    position(dishwasher,     kitchen, 4, 11).
    position(plant2,         kitchen, 6, 11).
    position(door,           kitchen, 5, 11).

    % occupies = every cell the item physically fills
    occupies(table, sleeping, 3, 1).
    occupies(table, sleeping, 4, 1).

    occupies(bed, sleeping, 1, 2).
    occupies(bed, sleeping, 1, 3).

    occupies(wardrobe, kitchen, 6, 6).
    occupies(wardrobe, kitchen, 6, 7).

    occupies(television, kitchen, 6, 8).
    occupies(television, kitchen, 6, 9).
    occupies(television, kitchen, 6, 10).

% ===== SPATIAL CONCEPTS (rules — written once, then queried) =====

same_room(A, B) :-
    position(A, Room, _, _),
    position(B, Room, _, _),
    A \= B.

next_to(A, B) :-
    position(A, _, X1, Y1),
    position(B, _, X2, Y2),
    A \= B,
    DX is abs(X1 - X2),
    DY is abs(Y1 - Y2),
    DX + DY =:= 1.

distance(A, B, D) :-
    position(A, _, X1, Y1),
    position(B, _, X2, Y2),
    D is abs(X1 - X2) + abs(Y1 - Y2).

near(A, B) :-
    distance(A, B, D),
    A \= B,
    D =< 2.

is_between(B, A, C) :-
    position(A, _, X1, Y1),
    position(B, _, X2, Y2),
    position(C, _, X3, Y3),
    A \= B, B \= C, A \= C,
    ( Y1 =:= Y2, Y2 =:= Y3, num_between(X1, X2, X3)
    ; X1 =:= X2, X2 =:= X3, num_between(Y1, Y2, Y3) ).

num_between(Lo, Mid, Hi) :-
    ( Lo =< Mid, Mid =< Hi
    ; Hi =< Mid, Mid =< Lo ).

on(book,   shelves).
on(remote, dining_table).
on(cup,    dining_table).


% Add, remove, move operations:

% add a new item to the map
add_furniture(Item, Room, X, Y) :-
    assertz(position(Item, Room, X, Y)),
    assertz(occupies(Item, Room, X, Y)),
    format("Added ~w to ~w at (~w,~w)~n", [Item, Room, X, Y]).

% remove an item completely
remove_furniture(Item) :-
    retractall(position(Item, _, _, _)),
    retractall(occupies(Item, _, _, _)),
    format("Removed ~w~n", [Item]).

% move an item to a new cell (keeps its room)
move_item(Item, NewX, NewY) :-
    retract(position(Item, Room, _, _)),
    assertz(position(Item, Room, NewX, NewY)),
    format("Moved ~w to (~w,~w)~n", [Item, NewX, NewY]).


% Lists and Numeric counting

% LIST of all items in a room (findall builds a list)
items_in_room(Room, Items) :-
    findall(Item, position(Item, Room, _, _), Items).

% NUMERIC: how many items in a room
count_items(Room, N) :-
    items_in_room(Room, Items),
    length(Items, N).

% LIST + RECURSION: my own sum of a list of numbers
sum_list_rec([], 0).
sum_list_rec([H|T], Sum) :-
    sum_list_rec(T, Rest),
    Sum is H + Rest.

% everything NEAR an item, as a list
things_near(Item, List) :-
    findall(Other, near(Item, Other), List).



% Navigation:


% rooms are connected both ways
adjacent_room(A, B) :- connected(A, B).
adjacent_room(A, B) :- connected(B, A).

% RECURSION: find a route between rooms, avoiding loops (Visited list)
route(From, To, Path) :-
    travel(From, To, [From], Path).

travel(To, To, Visited, Path) :-
    reverse(Visited, Path).
travel(From, To, Visited, Path) :-
    adjacent_room(From, Next),
    \+ member(Next, Visited),          % don't revisit (LIST op + cut-like guard)
    travel(Next, To, [Next|Visited], Path).





% RECURSION + NUMERIC: walk the grid one cell at a time toward a target,


% building the list of cells visited
step_toward(C, T, N) :- C < T, !, N is C + 1.
step_toward(C, T, N) :- C > T, !, N is C - 1.
step_toward(C, _, C).                  % already aligned

walk(X, Y, X, Y, Acc, Path) :- !,      % base case: arrived (CUT)
    reverse([X-Y | Acc], Path).
walk(X, Y, TX, TY, Acc, Path) :-
    step_toward(X, TX, NX),
    step_toward(Y, TY, NY),
    walk(NX, NY, TX, TY, [X-Y | Acc], Path).



% ============================================================
%  THE NAVIGATION TASK: move the robot near the television
% ============================================================

go_near(Item) :-
    at(robot, _, RX, RY),
    position(Item, Room, IX, IY),
    TargetY is IY - 1,                 % stand one cell above the item
    walk(RX, RY, IX, TargetY, [], Path),
    length(Path, Cells),
    Steps is Cells - 1,
    retract(at(robot, _, _, _)),
    assertz(at(robot, Room, IX, TargetY)),
    format("Robot walked ~w~n", [Path]),
    format("Reached cell (~w,~w) next to ~w in ~w steps~n",
           [IX, TargetY, Item, Steps]).

% the specific required task
go_near_television :- go_near(television).