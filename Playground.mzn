%---------- Input variables ----------
int: N;
int: L;
int: s;
int: d;
int: C;
int: r;
array [1..C] of int: qcbasepositions;
array [1..N] of int: lengths;
array [1..N] of int: arrivaltimes;
array [1..N] of int: departuretimes;
array [1..N] of int: minimumnumqcs;

%---------- Decision variables ----------
array [1..N] of var int: position;
array [1..N, 1..C] of var 0..1: assignedcranes;
array [1..N] of var int: begintimes;
array [1..N] of var int: endtimes;
array [1..N] of var 0..1: crossover;

%Constraints
  constraint forall (v in 1..N) (position[v] >= 0 /\ position[v] < L);
  constraint forall (v in 1..N) (begintimes[v] >= 0 /\ begintimes[v] < 168);
  constraint forall (v in 1..N) (endtimes[v] >= 0 /\ endtimes[v] < 168);
  % base position <= current position < current position + vessel length <= base position + crane length (compatibility vessel)
  constraint forall (v in 1..N, c in 1..C) (
      if assignedcranes[v, c] = 1 then qcbasepositions[c] <= position[v] /\ position[v] + lengths[v] <= qcbasepositions[c] + r endif
  );
  
  % Vessels can only be at the port terminal between arrival & departure times with shift tolerance
  constraint forall(v in 1..N)(begintimes[v] mod 168 <= (arrivaltimes[v] + s) mod 168);
  constraint forall(v in 1..N)(begintimes[v] mod 168 >= (arrivaltimes[v] - s) mod 168 );
  constraint forall(v in 1..N)(endtimes[v] mod 168 <= (departuretimes[v] + s) mod 168 );
  constraint forall(v in 1..N)(endtimes[v] mod 168  >= (departuretimes[v] - s) mod 168 );

  constraint forall(v in 1..N)(endtimes[v] - begintimes[v] = departuretimes[v] - arrivaltimes[v]);

  % Vessels cannot overlap (safety distance) during stay
  constraint forall (v1, v2 in 1..N where v1 < v2) (
    not
    % Both v1 and v2 cross week
    (((endtimes[v1] < begintimes[v1] /\ endtimes[v2] < begintimes[v2])) \/
    % v1 crosses week
    ((endtimes[v1] < begintimes[v1] /\ endtimes[v2] > begintimes[v2]) /\ endtimes[v1] + 168 > begintimes[v2] /\ begintimes[v1] < endtimes[v2]) \/
    % v2 crosses week
    ((endtimes[v1] > begintimes[v1] /\ endtimes[v2] < begintimes[v2]) /\ endtimes[v1] > begintimes[v2] /\ begintimes[v1] < endtimes[v2] + 168) \/
    % no vessel crosses week
    ((endtimes[v1] > begintimes[v1] /\ endtimes[v2] > begintimes[v2]) /\ endtimes[v1] > begintimes[v2] /\ begintimes[v1] < endtimes[v2]))  \/
    (position[v1] + lengths[v1] + d <= position[v2]) \/
    (position[v2] + lengths[v2] + d <= position[v1])
  );

  % Time has to go from 167 (Sunday 11PM to Monday 12AM)
  constraint forall (v in 1..N) (if endtimes[v] < begintimes[v] then crossover[v] = 1 else crossover[v] = 0 endif);

  % Only one crane at a time can be assigned to a vessel
  constraint forall(c in 1..C, v1, v2 in 1..N where v1 < v2)(
    if(assignedcranes[v1, c] = 1) then 
      assignedcranes[v2, c] = 0 \/ 
          not
    % Both v1 and v2 cross week
    (((endtimes[v1] < begintimes[v1] /\ endtimes[v2] < begintimes[v2])) \/
    % v1 crosses week
    ((endtimes[v1] < begintimes[v1] /\ endtimes[v2] > begintimes[v2]) /\ endtimes[v1] + 168 > begintimes[v2] /\ begintimes[v1] < endtimes[v2]) \/
    % v2 crosses week
    ((endtimes[v1] > begintimes[v1] /\ endtimes[v2] < begintimes[v2]) /\ endtimes[v1] > begintimes[v2] /\ begintimes[v1] < endtimes[v2] + 168) \/
    % no vessel crosses week
    ((endtimes[v1] > begintimes[v1] /\ endtimes[v2] > begintimes[v2]) /\ endtimes[v1] > begintimes[v2] /\ begintimes[v1] < endtimes[v2]))
    endif
  );
  % Minimum number of cranes that need to serve a vessel
  constraint
    forall(v in 1..N)
      (sum(c in 1..C)(assignedcranes[v, c]) >= minimumnumqcs[v]);
      

 
 solve satisfy;
 %Output
 
 output [
 %PRINT ID
 show(v) ++ ":" ++
 show(position[v])++"-"++show(position[v]+lengths[v]) ++ ";"++
 show(begintimes[v])++".."++show(endtimes[v])++";" ++
 join(",", [show(c) | c in 1..C where fix(assignedcranes[v, c] = 1)]) ++ ";" ++
  if fix(crossover[v] = 1) then "crossover" else "no" endif ++
 "\n"
 |v in 1..N
 ]