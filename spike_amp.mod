NEURON {
        SUFFIX ftx
        RANGE vx, t1, t2, tw
}
ASSIGNED {
        v (millivolt)
        vx (millivolt) : "threshold" for time measurements
        t1 (ms) : when v rises above vx
        t2 (ms) : when v falls back below vx
        tw (ms) : spike width
        prespike (1) : 1 if spike hasn't started
        postspike (1) : 1 if spike has finished
}
INITIAL {
        prespike = 1
        postspike = 0
        t1 = -1
        t2 = -2 : so tx > 0 only if a spike has finished
}
BREAKPOINT {
VERBATIM
  if (prespike==1) {
    if (v>vx) {
      t1 = t;
      prespike = 0;
    }
  } else {
    if (postspike==0) {
      if (v<vx) {
        t2 = t;
        postspike = 1;
      }
    }
  }
ENDVERBATIM
  tw = t2 - t1 : < 0 means spike hasn't finished
}