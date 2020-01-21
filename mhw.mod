COMMENT
Measures peak depol
and calculates spike half width from the times at which v crosses a (depolarized) threshold.
Threshold may be specified by the user, or determined in the previous run.

USAGE EXAMPLES

//////////////////////////
// User-specified threshold
forall insert mhw
forall for (x,0) vhalf_mhw(x) = THRESH // must assign value everywhere
mode_mhw = 0 // determine half width from fixed threshold
run()
printf(" base \t peak \t vhalf \thalf width\n")
printf("%6.2f \t%6.2f \t%6.2f \t%6.2f\n", \
       vinit_mhw(0.5), vmax_mhw(0.5), vhalf_mhw(0.5), hw_mhw(0.5))
//////////////////////////

//////////////////////////
// Dynamically-determined threshold
// run two simulations, first time with parameter mode_meas = 1
//   and second time with mode_meas = 2
// at end of first run, tmax and vmax will equal time and value of peak depol
// at end of second run, vhalf will be threshold for measurement of spike half width,
//   t0 and t1 will be threshold crossing times, and hw will be spike half width
forall insert mhw
mode_mhw = 1
run() // find local vmax and tmax
mode_mhw = 2
run() // find spike hw
printf(" base \t peak \t vhalf \thalf width\n")
printf("%6.2f \t%6.2f \t%6.2f \t%6.2f\n", \
       vinit_mhw(0.5), vmax_mhw(0.5), vhalf_mhw(0.5), hw_mhw(0.5))
//////////////////////////

hw will be -1 if there is no max, or if simulation ends before v falls below vhalf

Be cautious when using with adaptive integration--if the integrator uses long dt, 
t0 or t1 may be missed by a wide margin.
ENDCOMMENT

NEURON {
  SUFFIX mhw
  : mode values--
  : fixed threshold--0 use user-specified vhalf
  : dynamic threshold--1 measure vmax, 2 calc vhalf and measure halfwidth
  GLOBAL mode
  RANGE vinit, vmax, tmax
  RANGE vhalf, t0, t1, hw
}

UNITS {
  (mA) = (milliamp)
  (mV) = (millivolt)
  (mM) = (milli/liter)
}

PARAMETER {
  : mode values--
  : fixed threshold--0 use user-specified vhalf
  : dynamic threshold--1 measure vmax, 2 calc vhalf and measure halfwidth
  mode = 0 (1) : default is fixed (user-specified) threshold
}

ASSIGNED {
  v (mV)     : local v
  vinit (mV) : initial local v
  vmax (mV)  : max local v during previous run
  tmax (ms)  : time at which vmax occurred
  vhalf (mV) : (vinit + vmax)/2
  t0 (ms)    : time in rising phase of spike when v first > vhalf
  t1 (ms)    : time in falling phase of spike when v first < vhalf
  hw (ms)    : t1-t0
  findwhich (1) : 0 to find t0, 1 to find t1, 2 to find neither
}

INITIAL {
  if (mode==1) { : measure peak v then calc vhalf
: printf("Finding vmax\n")
    vinit = v
    vmax = v
    tmax = -1 (ms) : nonsense values for tmax, t0, t1, hw
    vhalf = v
    t0 = -1 (ms)
    t1 = -1 (ms)
    hw = -1 (ms)
  } else if (mode==2) { : calc vhalf from vinit and vmax in order to determine halfwidth
: printf("Determining depolarization halfwidth\n")
    vhalf = (vinit + vmax)/2
    findwhich = 0 : 0 to find t0, 1 to find t1
  } else if (mode==0) {
    vinit = v
    vmax = v
    tmax = -1 (ms) : nonsense values for tmax, t0, t1, hw
    t0 = -1 (ms)
    t1 = -1 (ms)
    hw = -1 (ms)
    findwhich = 0 : 0 to find t0, 1 to find t1
  }
}

PROCEDURE findmax() {
  if (v>vmax) {
    vmax = v
    tmax = t
  }
}

: find threshold crossings
PROCEDURE findx() {
  if (findwhich==0) {
    if (v > vhalf) {
      t0 = t
      findwhich = 1
    }
  } else if (findwhich==1) {
    if (v < vhalf) { 
      t1 = t
      hw = t1-t0
      findwhich = 2 : stop looking already
    }
  }
}

: BREAKPOINT {
AFTER SOLVE { : works as well, executed half as many times
  if (mode==1) { : measure peak v
    findmax()
  } else if (mode==2) {
    findx()
  } else if (mode==0) {
    findmax() : might as well, even if we don't use it to find threshold
    findx()
  }
}