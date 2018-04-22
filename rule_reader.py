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
	if (len(sys.argv) < 2) or (len(sys.argv) > 3):
		print("Usage :\n\tpython rule_reader.py <dat_file> <rule number> for a specif\n\tpython rule_reader.py <dat_file> for all the rules")
		sys.exit(1)


	dat_path = str(sys.argv[1])

	f = open(dat_path, "r")
	n_state = int(f.read(1))
	n_vois = int(f.read(1))
	nb_config = n_state ** n_vois
	n_rules = 0
	rules = []

	brule = f.read(nb_config)
	while brule != "":
		rule = []

		for i in range(0, nb_config):
			rule.append(int(brule[i]))

		rules.append(rule)
		n_rules = n_rules + 1
		brule = f.read(nb_config)

	print("{} states and {} neighbours".format(n_state, n_vois))
	print("{} reversible rules".format(n_rules))

	configs = [format(int2base(x, n_state)).rjust(n_vois, '0') for x in range(0, nb_config)]

	if(len(sys.argv) == 3):
		rule_number = int(sys.argv[2]) - 1

		if rule_number >= n_rules:
			print('we only have {} rules'.format(n_rules))
			exit(2)

		print(rules[rule_number])
		print(list(zip(configs, rules[rule_number])))

	if(len(sys.argv) == 2):
		for i in range(0, n_rules):
			print(int("".join(map(lambda x : str(x), rules[i][::-1])), 2))
			#print(list(zip(configs, reversible_rules[4][i])))