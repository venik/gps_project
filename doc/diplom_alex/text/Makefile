TEX = texi2dvi

TEX_FLAGS = --dvipdf

main:	main.tex
	${TEX} ${TEX_FLAGS} main.tex

special: main_special.tex special.tex
	${TEX} ${TEX_FLAGS} main_special.tex

clean:
	rm *.log main.aux main.toc main.pdf main.dvi
