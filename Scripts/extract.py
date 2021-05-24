from gridlink import *
from gridlink import knot_dict

A = GridlinkApp()
for s in sorted(knot_dict.keys()):
  K = Knot(A, s)
  K.simplify()
  XO = K.get_XOlists()
  print("\"%s\": {\"X\": %s, \"O\": %s}," % (s, XO[0], XO[1]))
  K.exit()
