import string

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
	'''
	We check all the numbers from 0 to 2^(nsize) - 1 and
	if the number has a hamming weight of 2^(nsize - 1), then
	it is a splitting of the edges of the graph in two groups
	of same size
	'''

	nsize = 4
	nrules = 1 << (1 << nsize)
	nedgestoselect = (1 << (nsize - 1))

	result_file = open("splittings_{}.csv".format(nsize), "w")


	print("n of edges to select {}".format(nedgestoselect))

	for i in range(0, nrules):
		hamming_weight = 0
		tmp = i
		for bit in range(0, nrules):
			if tmp & 1:
				hamming_weight = hamming_weight + 1

			tmp = tmp >> 1

		# print("hamming weight of {}".format(hamming_weight))
		if hamming_weight == nedgestoselect:
			# print(format(int2base(i, 2)).rjust(1 << nsize, '0'))
			result_file.write(str(i) + "\n")
			print(i)