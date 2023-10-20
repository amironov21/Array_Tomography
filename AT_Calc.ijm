/*This small macro was created to reduce the annoyance of mental arithmetic 
 for estimation sections/ribbons numbers that will fit on a conductive support slide
 for Array Tomography. Just fill in the parameters of your slide and dimensions of your
 sections into relative fields and you will get estimates. These estimates reflect only 
 ideal situations when ribbons are straight and not broken. Usualy, this is not
 the case. Take these numbers with a pinch of salt.

Version: 1.0
Date: 20/10/2023
Author: Aleksandr Mironov amj-box@mail.ru
*/ 

requires("1.54f");

//help
html = "<html>"
	+"<h1><font color=navy>Array Tomography Calculator, v1.0</h1>"
	+"This small macro was created to reduce the annoyance of mental arithmetic<br>"
	+"for estimation sections/ribbons numbers that will fit on a conductive support slide <br>"
	+"for Array Tomography. Just fill in the parameters of your slide and dimensions of your <br>"
	+"sections into relative fields and you will get estimates. These estimates reflect only <br>"
	+"ideal situations when ribbons are straight and not broken. Usualy, this is not <br>"
	+"the case. Take these numbers with a pinch of salt."
	
//Creating dialog box
Dialog.create("Array Tomography Calculator, ver. 1.0");
Dialog.addMessage("To estimate maximal number of ribbons \nand sections you can put on a certain support, \nplease, fill in the required fields below", 24, "blue");
Dialog.addImage("https://github.com/amironov21/Array_Tomography/blob/main/AT_ribbons_marked_a.jpg?raw=true"); 
Dialog.addMessage("Slide dimensions", 16, "blue");
Dialog.addNumber("Slide width, W =", 25,0,2,"mm"); //value 1
Dialog.addNumber("Slide length, L =", 25,0,2,"mm"); //value 2
Dialog.addNumber("Edge offset zone, Z =", 5,0,2,"mm"); //value 3
Dialog.addMessage("Section/ribbon dimensions", 16, "blue");
Dialog.addNumber("Section width, SW =", 500,0,2,"um"); //value 4
Dialog.addNumber("Section height, SH =", 500,0,2,"um"); //value 5
Dialog.addNumber("Ribbons separation, D =", 500,0,2,"um"); //value 6
Dialog.addNumber("Section thickness, ST =", 80,0,2,"nm");  //value 7
Dialog.addMessage("When you are ready press [OK]", 16, "blue");
Dialog.addHelp(html); 
Dialog.show(); 

//Getting calculation inputs
W = Dialog.getNumber();//value 1
L = Dialog.getNumber();//value 2
Z = Dialog.getNumber();//value 3
SW=Dialog.getNumber();//value 4
SH=Dialog.getNumber();//value 5
D=Dialog.getNumber();//value 6
ST=Dialog.getNumber();//value 7


//Getting results
print(
ns=1000*(L-2*Z)/SH;//number of sections in a ribbon
NS = floor(ns);
print("Max sections in a ribbon ="+NS);
nr=1000*(W-2*Z)/(SW+(D-1));//number of ribbons
NR = floor(nr);
print("Max ribbons on a slide ="+NR);
TS=NS*NR;//Total number of sections
print("Max number of sections ="+TS);
Depth=TS*ST/1000;
print("Dataset depth = "+Depth+"um");
