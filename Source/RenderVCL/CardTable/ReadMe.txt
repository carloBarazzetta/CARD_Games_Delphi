CardTable v3.3.
Copyright 2004/05/06/07/08 David Mayne.

This is FreeWare. You may use this code in your own programs freely with no restrictions.   
 
TCardTable unit displays TCards. It encapsulates 1 deck of cards and displays them on any user form. TCardTable can also display other external decks & cards on the table. Public methods that use decks take a parameter to specify the deck. If no value is given the internal deck is used.

TCard class represents a playing card.

TCardDeck class maintains a deck of cards (TCard).

TCardTable    Represents a card Table.
              With a deck of cards upon it.

Web: www.davidmayne.co.uk.
Email: david@davidmayne.co.uk.

CardTable was originally written with Delphi 7. Currently Turbo Explorer 2006 is used. As a consequence, as components cannot be added to the ide, the ide functionality is untested and may not work at all! The help doc has not been updated for a long time. It does though offer a basic understanding of CardTable . See the comments at the top of CardTable.pas file for brief notes about the changes. Also see Rotation demo and Two Table demo.

[Compilation of code written with v2.x. Should compile mostly unchanged. Compilation of code written with v1.x. The types of a very few parameters have changed, easy to fix. BufferFix published property has been removed as buffer can no longer be corrupted. You may get warnings, ignore them.]

CardTable features smooth card movement with cards being able to be selected, picked up and moved from above and below other cards on the table. The limitations that existed with movement in version 1.x have been removed with v.2. Cards can also be dragged & dropped by the mouse. See the end of this file for details of the movement system. Any number of cards, limited by MaxCards constant, can be on the table at one time. The more cards that either directly or indirectly cover a card then the more cards have to be picked up and put down again to the buffer when the card is moved. This is not normally noticeable unless there is a very large (> 30) number of covering cards.

NB: Components with a windows handle will display correctly on the table eg TStaticText. Lightweight components eg TLabel will display transparency fine but cardtable sometimes completely obscures them. If you have lightweight controls on the cardtable set RepaintLabels property to True & cardtable will automatically repaint controls as required. Note that if you allow a dragged card to pass over them they will disappear until the card is dropped again. CardTable also doesnt work well with some types of controls placed on it, for example scroll bars.

Originally written in Delphi7. Changes will be needed to get it to work with different versions. Depending on the version significant changes may be required.

Multiple cardsets are used. Before the component can be used it needs to know the location of the cardsets directory. It is by default looked for in directory Cardsets in the program directory. Alternatively another location can be specified for the cardsets by the first line in a file named Config.txt in the program directory. This must be a fully qualified filename Eg C:\Cardsets note no trailing \. CardTable will also look for the cardsets directory within all of the directories listed within the path environment variable. At design time it is best to put the cardsets directory within one of these directories, perhaps Delphi\bin\ or Delphi\projects\bpl\ or add a new directory entry to the path variable as if you open files outside the current directory at design time and the cardsets are not within the path then you may have problems. If cardsets directory cannot be found then (runtime only) the component will ask for the full path and write its own Config.txt. Nb there MUST always be a cardset named Standard. The cardsets can be of different sizes and must have the same names and format as the included sets which are mostly modified Pysol cardsets. Pysol is a nice solitaire program written in Python (which is not nearly as nice). Pysol has many different sets. I have converted five of the better ones. New set in v1.85 is unique high colour glossy shaded set C_2. (Actual light effect is merely a form of bevel boss done with Eye Candy and Fireworks.)

Note there is no help file but CardTable.doc details all public properties and methods and Example.pas in project1 demonstrates basic usage of a CardTable created at runtime. Example2 in project2 is a more complex demonstration that is a fully working Patience/Solitaire game. Example2 needs the component to have been installed. Read Installing.txt for details of how to install the component.

v3.3. Numerous fixes to get it working right in Turbo Explorer. New shadow mode - soft shadows enabled by default. New shaded card drag shades enabled by default. New events and properties surfaced. New movement properties.

v3.00. Quite a few bug small fixes and additions which include changes to align, card movement and colour depth. Major addition of 2d rotation and scaling and simple sprite class. See Rotation demo, Two CardTable demo and comments at top of CardTable.pas. As of now CardTable.doc has NOT been updated. New card shadow mode enabled by default. New modified cardsets were needed to aid with rotation and v2.x cardsets are not compatiable with this.

v2.10. Minor additions. Constants MaxOutlines, MaxMarks and MaxSuits now determine the limit on the number of cardmarks of each type. Two new CardTable properties affecting card movement both default false. LiftOffset if set True lifts cards off the table offset the width of the shadow. SlowMoveRegion if set True and cardspeed > 1 then cardspeed is slowed to 1 at the end point of all movement.

v2.00. Major rewrite. Now in practical use movement under and over cards should be easy, cause no problems and require nothing more than a simple call to MoveTo. On average a speed increase of over 200% will allow much faster response and games with a higher number of cards on the table. Alterations include: removal of property BufferFix, new parameter in DropCard & DropCardOnShade methods - Move allows dragged cards to be moved to a drop position, Sort method generalised allowing horizontal and vertical hands, overlapping and non overlapping cards and flat and 2 plane movement within sorts - TMode removed. New method in CardDeck Return which allows you to return a card to the top of the deck. Now CardTable PlaceDeck also allows you to redraw a displayed deck after cards have been added to it either with Return or AddCardsToDeck. Now jokers [1..4] of two designs [01joker.bmp 02joker.bmp] can easily be used. (Joker pictures are from artwork 'borrowed' from some sites on the internet. I long ago forgot where from! You might like to replace them although this may be problematic with set C-2.) Simply add the no of jokers to the size of the deck and assign to NoOfCards. Jokers have a suit value of csJoker and values cvAce thru cvFour. Decks can now be of any size subject to setting MaxCardsInDeck constant thus 52,104,156 cards etc. Decks can now also be stripped of specific cards to form a partial sub deck, simply call StripDeck with a TCardList of cards to be removed before dealing; call again with nil as a parameter or set NoOfCards again to reset. You can get the references to the cards by dealing thru the deck; assigning the right cards to the CardList and then reseting the deck; or by reading new property PeekDeck[Index] which lets you peek at an undealt deck. New method in carddeck DrawN draws card number N from the deck (1..NoOfCardsInDeck 1 is top). Corresponding method in cardtable DrawCardNFromDeck for dealing with displayed decks.

v1.86. Added new published property CardTable.TurnOverAnimationLift default false that if set to true displays a pseudo animated shadow when a card with no covering cards is turned over and works with all 3 turnover modes (Vertical, horizontal and flip - when TurnOverAnimationSpeed is set to 0). This only needed 1 new bitmap in cardset c_2. Fixed some pixel format errors that sometimes caused banding in gradient background.

v1.85. Numerous small fixes and additions including horizontal card flip option and carddeck ordering allowing replicateable deals. Also added new high colour glossy cardset.

v1.83. Small fix in CardDeck.Shuffle.

v1.82. Small but significant changes. Now when StretchBackground property is false any background picture is tiled to fill the table as opposed to previously when the table was resized to the picture which was pretty silly. Some flicker when resizing eliminated. Patience example tidied up a little. 

v1.8. New addition is the introduction of multiple cardmarkers. New parameter No in PlaceCardMarker and PickUpMarker methods. See cardtable.doc and example2.pas.

v1.71. Changes from v1.7. New method introduced in CardTable RestoreCardByMove. Slight change in CardBackForm.pas makes it easier to compile in versions other than Delphi 7.

v1.7 Changes from v1.6.
Major addition is AutoShade mode which makes controlling drag and drop and the drawing of shades much easier. New properties in CardTable: DragCards a TCardList dynamic array of cards that can be dragged with the mouse. DropPoints a TDropPoints dynamic array of top & left positions where a shade is drawn. By assigning to these properties autoshade is enabled. AutoShadeMode there are 2 different methods used to decide when to switch shade positions. Mode 1 uses card bounds to draw shades and mode 2 the mouse position which makes control easier when the cards are close together. Change to TCardDropEvent new parameter Index which details the index in DropPoints array the point that the card was dropped on. If this is -1 then it was not dropped on a point within the array. New property in CardDeck: NoOfCards default 52 which can be also set to 104 allowing 2 combined decks to be easily used. Some new backs added to the cardsets.

v1.6 Changes from v1.51.
New property for TCardDeck: FaceUp default false. Are the cards in the deck face up?
New property for TCardTable: TurnOverAnimationSpeed default 3. If >0 displays an animation when a card is turned over.

Bugs fixed:
Inapropriate use of Application.ProcessMessages in CardTable sometimes caused problems - fixed.
Slight fix in example.pas. Works better now when the forms scaled property is set to false.




UNDERSTANDING THE MOVEMENT SYSTEM.
----------------------------------

CardTable is easy to use and for the most part no knowledge of the underlying system is required. However for more complex operations such as reordering an overlaped hand (as in SortHand method) an understanding of the methods used is helpfull.

The basic principle of the movement is that cards are dropped and moved over others and never slid under cards on the table (cards can however easily be moved out from under covering cards placed above them). Cards on the table are stored in a kind of stack FCardsOnTable. A card dealt and moved is placed at the top of this stack. As such it is easy to see that cards have a potential to be covered only by cards higher up in the stack. A card that is moved with MoveTo will rise to the top of the stack IF and only if it completely moves clear of covering cards. A card picked up and put down again will always move to the top of the stack and thus top of all cards on the table.

Examine the CardTable.SortHand method to understand how to arrange a hand within the z dimension. It should be clear that you move from the lowest card in a hand to the highest in order that cards will be at the correct position in the stack and displayed correctly. As in the sorthand method cards that do not move will often have to be picked up and put down again in order for them to be ordered correctly on the stack and thus displayed as intended. It probably sounds more complex than it really is.
