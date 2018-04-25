import sys
import string
import array

digs = string.digits + string.ascii_letters

def int2base(x, base):
    if x < 0:
        sign = -1
    elif x == 0:
        return digs[0]
    else:
        sign = 1

    x *= sign
    digits = []

    while x:
        digits.append(digs[int(x % base)])
        x = int(x / base)

    if sign < 0:
        digits.append('-')

    digits.reverse()

    return ''.join(digits)

if __name__ == "__main__":
	if len(sys.argv) != 3:
		print("usage : python split_printer_dot.py <neighbourhood size> <rule number>")

	nsize = int(sys.argv[1])
	rule = int(sys.argv[2])
	nedges = 1 << nsize

	result_file = open("split_dot_{}.dot".format(rule), "w")

	result_file.write("digraph split {\n")

	for i in range(0, nedges):
		source = i >> 1
		dest = i & ((1 << (nsize - 1)) - 1)

		fsource = format(int2base(source, 2)).rjust(nsize, '0')
		fdest = format(int2base(dest, 2)).rjust(nsize, '0')

		if (rule & (1 << i)) >> i:
			result_file.write("{} -> {} [color=blue]\n".format(fsource, fdest))
		else:
			result_file.write("{} -> {} [color=red]\n".format(fsource, fdest))

	result_file.write("}") 