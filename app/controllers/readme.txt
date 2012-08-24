
SHAPE DEFINITION
- Define each line individually 
- A closed shape is defined by an array of line definitions 
- An item can be a line or a curve
	- A circle can be defined as a curve with the following definiton:

NAMING CONVENTION
 - Anchors are named in order of the definition of lines starting at 'A'
 	- A group of lines will be named
 	- Single lines have two anchors (one at either end) these follow the incrementing naming convention
 	- 

VISIBILITY
  This indicates the point at which the line will be visible.
  It is defined by an integer indicating the number of clicks after which the line is shown.

DEFINITION
  This indicates the point at which an anchor will be defined.
  It is defined by an integer indicating the click number which will define the position of the anchor.


 EXAMPLE

     (boxShape: {
      lines    : [
                  [												# CLOSED SHAPE
                    {type:'line', def: 1, visibility: 2},		# A
                    {type:'line', def: 2, visibility: 2},		# B
                    {type:'line', visibility: 2}				# C
                  ],
                  {type:'line', def: 3, visibility: 3},			# D,E
                  {type:'line', def: 4, visibility: 4},			# F,G
                ]
      joins     :  [['A','D'],['B','F']]
    }),