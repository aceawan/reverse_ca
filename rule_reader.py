import sys
import msgpack
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
	if len(sys.argv) != 3:
		print("Usage : python rule_reader.py <dat_file> <rule number>")
		sys.exit(1)

	dat_path = str(sys.argv[1])
	rule_number = int(sys.argv[2])

	f = open(dat_path, "rb")
	raw_data = f.read()

	reversible_rules = msgpack.unpackb(raw_data)

	n_state = reversible_rules[0]
	n_vois = reversible_rules[1]
	n_rules = reversible_rules[2]

	print("{} states and {} neighbours".format(n_state, n_vois))
	print("{} reversible rules".format(n_rules))

	if rule_number >= n_rules:
		print('You want the rule {} but we only have {} rules'.format(rule_number, n_rules))
		exit(2)

	nb_config = n_state ** n_vois

	configs = [format(int2base(x, n_state)).rjust(n_vois, '0') for x in range(0, nb_config)]

	print(reversible_rules[3][rule_number])
	print(list(zip(configs, reversible_rules[3][rule_number])))