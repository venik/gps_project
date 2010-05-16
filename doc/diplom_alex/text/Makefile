TEX = texi2dvi

TEX_FLAGS = --dvipdf

main:	main.tex
	${TEX} ${TEX_FLAGS} main.tex

spec: main_special.tex special.tex
	${TEX} ${TEX_FLAGS} main_special.tex

bjd: main_bjd.tex bjd.tex
	${TEX} ${TEX_FLAGS} main_bjd.tex

eco: main_economic.tex economic.tex
	${TEX} ${TEX_FLAGS} main_economic.tex

tech: main_tech.tex tech.tex
	${TEX} ${TEX_FLAGS} main_tech.tex

clean:
	rm *.log main.aux main.toc main.pdf main.dvi
