TEX = texi2dvi

TEX_FLAGS = --dvipdf

main:	main.tex
	${TEX} ${TEX_FLAGS} main.tex

main.tex: main.tex title.tex

clean:
	rm *.log main.aux main.toc main.pdf main.dvi
