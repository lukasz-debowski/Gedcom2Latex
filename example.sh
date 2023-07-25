#!/bin/sh


# ./gedcom2latex.pl find name "Alice" data_bases/GeorgeWashingtonFamilyBig.ged 

./gedcom2latex.pl both 4-3 short id "I1" data_bases/EnglishTudorHouse.ged > input_files/Henry_Tudor.tex

./gedcom2latex.pl down 4 long name "Peter de LUXEMBOURG" data_bases/EnglishTudorHouse.ged > input_files/Peter_de_Luxembourg.tex

./gedcom2latex.pl up 4 short id "I1" data_bases/GeorgeWashingtonFamilyBig.ged > input_files/George_Washington.tex
