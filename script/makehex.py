

from sys import argv

binfile = argv[1]
hexfile = argv[2]

with open(binfile, "rb") as f, open(hexfile, "w") as fout:
  cnt = 3
  s = ["00"]*4
  while True:
    data = f.read(1)
    if not data:
      fout.write(''.join(s)+'\n')
      exit(0)
    s[cnt] = "{:02X}".format(data[0])
    if cnt == 0:
      fout.write(''.join(s)+'\n')
      s = ["00"]*4
      cnt = 4
    cnt -= 1