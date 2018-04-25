# This script is _very_ ugly
# You can use it only with rules of neighbourhood size of 4

import sys

if __name__ == "__main__":
	if len(sys.argv) != 2:
		print("usage : python split_printer_latex.py <rulenumber>")

	rule = int(sys.argv[1])
	latex_start = r'''\documentclass{article}
\usepackage[utf8]{inputenc}
\usepackage[francais]{babel}
\usepackage{tkz-graph}
\usepackage[T1]{fontenc}
\usepackage{geometry}
\geometry{left=4cm, right=4cm, top=2.7cm, bottom=2.7cm}

\begin{document}

\begin{figure}[h!]
	\centering
	\begin{tikzpicture}[scale=1.75]
		\GraphInit[vstyle=Normal]
		\Vertex[x=0, y=1.5]{000}
		\Vertex[x=1.5, y=3]{001}
		\Vertex[x=1.5, y=0]{100}
		\Vertex[x=3, y=1.5]{010}
		\Vertex[x=4.5, y=1.5]{101}
		\Vertex[x=6, y=3]{011}
		\Vertex[x=6, y=0]{110}
		\Vertex[x=7.5, y=1.5]{111}
		
		\tikzset{EdgeStyle/.style = {->}}'''

	latex_end = r'''\end{tikzpicture}
	\caption{Découpage d'un graphe de De Bruijn v4s2}
\end{figure}

\end{document}'''

	result_file = open("split_text_{}.tex".format(rule), "w")

	result_file.write(latex_start)

	if (rule & (1 << 0)) >> 0:
		result_file.write("\Loop[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=blue, dist=0.8cm](000)")
	else:
		result_file.write("\Loop[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=red, dist=0.8cm](000)")

	if (rule & (1 << 15)) >> 15:
		result_file.write("\Loop[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=blue, dist=0.8cm, dir=EA](111)")
	else:
		result_file.write("\Loop[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=red, dist=0.8cm, dir=EA](111)")

	if (rule & (1 << 1)) >> 1:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=blue](000)(001)")
	else:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=red](000)(001)")

	if (rule & (1 << 2)) >> 2:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=blue](001)(010)")
	else:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=red](001)(010)")
	
	if (rule & (1 << 3)) >> 3:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=blue](001)(011)")
	else:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=red](001)(011)")
	
	if (rule & (1 << 4)) >> 4:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=blue](010)(100)")
	else:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=red](010)(100)")
	
	if (rule & (1 << 6)) >> 6:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=blue](011)(110)")
	else:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=red](011)(110)")
	
	if (rule & (1 << 7)) >> 7:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=blue](011)(111)")
	else:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=red](011)(111)")
	
	if (rule & (1 << 8)) >> 8:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=blue](100)(000)")
	else:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=red](100)(000)")
	
	if (rule & (1 << 9)) >> 9:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=blue](100)(001)")
	else:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=red](100)(001)")
	
	if (rule & (1 << 11)) >> 11:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=blue](101)(011)")
	else:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=red](101)(011)")
	
	if (rule & (1 << 12)) >> 12:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=blue](110)(100)")
	else:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=red](110)(100)")
	
	if (rule & (1 << 13)) >> 13:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=blue](110)(101)")
	else:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=red](110)(101)")
	
	if (rule & (1 << 14)) >> 14:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=blue](111)(110)")
	else:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=red](111)(110)")
	
	result_file.write(r'\tikzset{EdgeStyle/.style = {->, bend right=-20}}')

	if (rule & (1 << 5)) >> 5:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=blue](010)(101)")
	else:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=red](010)(101)")

	if (rule & (1 << 10)) >> 10:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=blue](101)(010)")
	else:
		result_file.write("\Edge[labelstyle = {auto=left, fill=none, outer sep = 0.1ex}, color=red](101)(010)")

	result_file.write(latex_end)