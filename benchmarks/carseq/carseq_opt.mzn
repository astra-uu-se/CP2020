% Reformulation of car sequencing into an optimisation problem

include "globals.mzn";

%-------------------------------------------------
% Model parameters
%-------------------------------------------------
int: n_cars;      % The number of cars
int: n_options;   % The number of options to install, e.g "sun roof", "air-conditioning".
int: n_confs;     % The number of configurations. A configuration specifies a variant on the basic model.
                  % e.g. a configuration may include the basic model, sun roof and air-conditioning.

int: n_dummy = n_cars*2;

set of int: cars             = 1..n_cars + n_dummy; % plus dummy cars
set of int: options          = 1..n_options;
set of int: configurations   = 1..n_confs;

set of int: configurations_dummy   = 1..n_confs+1;

int: dummy = n_confs + 1;



array [options] of int: k;
array [options] of int: min_caps;       % min_caps[j] --   the minimum capacity of the jth station (the jth station installs jth option).  
array [options] of int: max_caps;       % max_caps[j] --   the maximum capacity of the jth station 

array [configurations]  of int: n_cars_by_confs;        % n_cars_by_confs[j] -- the required number of cars of jth configuration. 
array [configurations, options]  of int: confs;         % if confs[i,j] == 1 then ith option has to be installed for jth configuration

% add a bunch of dummy cars
array [configurations_dummy]  of int: n_cars_by_confs_dummy = [if c != dummy then n_cars_by_confs[c] else n_dummy endif| c in configurations_dummy];   
array [configurations_dummy, options]  of int: confs_dummy = 
  array2d(configurations_dummy, 
          options, 
          [if c != dummy then confs[c,o] else 0 endif| c in configurations_dummy, o in options]);

array [options] of int: options_ordering;               % An options ordering: options for which demand is closer to capacity are assigned first. [1]

%----------------------------------------------------
% Variables
%----------------------------------------------------

array [cars]    of var configurations_dummy:         seq_confs;
array [options, cars]  of var 0..1:            b_seq_confs;

constraint forall(o in options, c in cars)(
b_seq_confs[o,c] = confs_dummy[seq_confs[c],o]
);

constraint global_cardinality_low_up(seq_confs, configurations_dummy, n_cars_by_confs++[n_dummy], n_cars_by_confs++[n_dummy]);

constraint forall(o in options, j in 1 .. n_cars+n_dummy-k[o])(
 (sum(i in j..j+k[o]-1)(b_seq_confs[o, i]) <= max_caps[o]) ::soften
);

% include "gecode.mzn";

var 0..n_cars+n_dummy: obj;

constraint obj = sum(c in cars where c  <= n_cars)((seq_confs[c]==dummy));

solve 
::relax_and_reconstruct(seq_confs, 80)
::int_search(seq_confs, dom_w_deg, indomain_min, complete)
minimize obj;


output ["obj = ", show(obj),"\n seq = ",show(seq_confs)];

