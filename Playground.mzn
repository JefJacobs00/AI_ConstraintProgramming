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
array [1..N] of var int: beginposition;
array [1..N, 1..C] of var 0..1: assignedcranes;
array [1..N] of var int: begintimes;
array [1..N] of var int: endtimes;

%Constraints

  % Crane cannot exceed baseposition + length (range: [pc, pc + r]
  % Vessels can only be at the port terminal between arrival & departure times with shift tolerance
  constraint forall(v in 1..N)(begintimes[v] <= (arrivaltimes[v] + s));
  constraint forall(v in 1..N)(begintimes[v] >= (arrivaltimes[v] - s));
  constraint forall(v in 1..N)(endtimes[v] <= (departuretimes[v] + s));
  constraint forall(v in 1..N)(endtimes[v] >= (departuretimes[v] - s));
  % Vessels cannot overlap (safety distance) during stay
  % Time has to go from 167 (Sunday 11PM to Monday 12AM)
  % Only one crane at a time can be assigned to a vessel
  % Minimum number of cranes that need to serve a vessel
  constraint
    forall(v in 1..N)
      (sum(c in 1..C)(assignedcranes[v, c]) >= minimumnumqcs[v]);
  % base position <= current position < current position + vessel length <= base position + crane length (compatibility vessel)
 
 solve satisfy;
 %Output
 
 output [
 %PRINT ID
 show(v) ++ ":" ++
 show(beginposition[v])++"-"++show(beginposition[v]+lengths[v]) ++ ";"++
 show(begintimes[v])++".."++show(endtimes[v])++";"
 |v in 1..N
 ]