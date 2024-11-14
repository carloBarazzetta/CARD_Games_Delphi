{
CardTable
Copyright © 2024 Ethea S.r.l.
Author: Carlo Barazzetta
Contributors: Lorenzo Barazzetta

Original code is Copyright © 2004/05/06/07/08 by David Mayne.

DESCRIPTION:

CardTable + 2d transformations + misc changes.

Card:
  Rotation in radians property single. Uses FFaceR and FAngle.
  Meaningful only if displayed on table.
  Generally use cardtable methods to set, could be used to pre-rotate a card.
  New: FFace bitmap surfaced to face.
  New param for AltDeckDirectory (see CardDeck) in LoadCardFace.

CardDeck:
  Scale     property single. 0.2 thru 2+ some values better than others.
  ScaleDeck property integer. -2 thru 3 sets scale to acceptable values.
  CardBacks are rotated as needed for each card unlike faces which are stored
    and thus slower than faces.
  New Angle parameters in PlaceCard, DropCard.
  New: FCardMask & FBack surfaced to CardMask & BackBitmap.
  Minor change to LoadCardBack.
  BaseDeck property surfaces point where deck was placed.
  FCardMarks array surfaced via CardMarks property.
  AltDeckDirectory property allows use of an additional alternative location for
    cardsets as for instance in My Documents.
  Bug in large scaled shadows fixed - simple change to SetDeck.
  New inverted CardMask surfaced to CardMaskInv.

CardTable:
  RotateCard method takes radian parameter.
  Radian parameters in DropCard, PlaceCard & PlaceCardMarker.
  DropAngles assigned property of TDropAngles of single radians.
  DropAngles property for use with AutoShades must be assigned to or be nul and
    MUST be same length as DropPoints.
  TurnAnimations property can be set to false to disable all turn over
    animations when using rotated & non rotated cards as rotated cards never
    display animations.
  Additional params add speed when dealing with rotated cards as rotated cards
  can have added speed problems because of their effective larger footprint.
  Additional param in PickUpCard, TopCard - set true when it is known to be top.
  Additional param in TurnOverCard as above.
  Minor change to CardBackForm.
  FBitMap surfaced to TableBitMap property.
  ADDED new shadow mode property - smOriginal & smDarken.
  ADDED new SlowMoveRegion wait mode. Property SMR_WaitMode if enabled slows
    down the final few pixels of movement within the slow move region.
  ADDED new gradient backdrop method see backdrop unit.
  CardMarkIndex changed to a public method.
  Added default Path parameter to SaveStatus, LoadStatus, SaveTable, LoadTable.
  Added property DragCardCursor.
  Protected Wait method now public.
  FCopyToScreen field surfaced to CopyToScreen property. Enables/disables
    copying of cardtable buffer to form.
  FOnCardRestored event now triggered by RestoreCardByMove method.
  FastMovementMode property. Default false. If true movement is much faster but
    may result in apparent screen tear.
  Modified shadow drawing - additional parameters required by MyGrphx.Darken.
    Soft - true is soft graduated shadow, False is hard flat shadow.
    TopDown - true if gradient is vertical else horizontal.
  New property for cardtable to reflect the above Darken change - SoftShadow.
  New property HQDragShade. If true new high quality shaded drag shade is used
    else a simple bitmap is overlaid. Uses new CardDeck.FCardMaskInv field.
  New property used with HQDragShade - HQDragShadeColour. Has values from
    MyGrphx.Darken. Colour 0 is grey. 1 red 2 green 3 blue 4 yellow 5 pink
    6 turquoise.
  Setting above property HQDragShadeColour to 7 cause NO drop shade drawing.
  New TTableArea class describing a section of the table & MaxAreas constant.
    TableAreas created/destroyed by CardTable. All can be drawn with
    CardTable.DrawTableAreas/UnDrawTableAreas. Property TableAreas surfaces the
    array. TableAreas have enabled, position, width, height, draw, image
    properties & OnAreaClickEvent.
  New TTableImage class draws bitmap on the table.
  Now external decks assigned to CardTable.External Deck raise their own
    OnExternalCardClickEvent.

  Movement Recap:
  SlowMoveRegion   - slows down pixel movement for last few pixels.
  SMR_WaitMode     - slight pause at end of SlowMoveRegion.
  FastMovementMode - faster but apparent visual tearing at high card speeds.

Sprite:
  CardTable sprite class. Draw & UnDraw. Lift, Rotate, Shrink and Grow.
  Add graphic with Sprite.BitMap.Assign.
  Properties include X,Y, Angle, Scale, and Displayed.
  SaveToFile method saves a transformed bitmap to a file.
  One instance is maintained & redrawn by cardtable.
}
unit CardGames.Vcl.CardTable;

interface

uses
  System.Types
  , System.IniFiles
  , System.Classes
  , System.SysUtils
  , WinApi.Windows
  , WinApi.Messages
  , Vcl.Graphics
  , Vcl.Controls
  , Vcl.ExtCtrls
  , Vcl.Imaging.Jpeg
  , CardGames.Vcl.BackDrop
  , CardGames.WinApi.ImageArray
  ;

const
//Change these constants to reflect your game requirements. If you get runtime
//error EAccessViolation it is possible MaxCards is too small.
  MaxCards = 109;//Set to max no of cards that can be displayed on the table.
  MaxCardsInDeck = 108;//Max no of cards including jokers that can be in 1 deck.
//CardMark constants determine no of outlines of each type 1..n. For suits the
//value is the no of marks of each suit type ie 2 means there are 2 marks of
//spade, heart etc. There can only be 1 of dragshade type.
  MaxOutlines = 20;
  MaxMarks = 13;
  MaxSuits = 1;
  MaxAreas = 1;//Minimum of one.

type
  TDeckName = type string;
  TCardBack = type Integer;
  //Enumerated types.
  //Now Jokers are used with decks.
  TCardSuit = (csClub, csDiamond, csHeart, csSpade, csJoker);
  //Jokers have values cvAce thru cvFour. Two designs are drawn.
  TCardValue = (cvAce, cvTwo, cvThree, cvFour, cvFive, cvSix, cvSeven,
    cvEight, cvNine, cvTen, cvJack, cvQueen, cvKing);//Nb aces are low.
  //Used in drawing outlines & marks on table and shades and marks on cards.
  TCardMarker = (cmOutline, cmMark, cmClub, cmDiamond, cmHeart, cmSpade,
    cmDragShade);
  //NEW alternative shadow modes. Original is quick but flickers.
  //Darken uses ScanLine is slower but smooth.
  TShadowMode = (smOriginal, smDarken);

  //Forward declarations.
  TCard = class;
  TCardDeck = class;
  TCardTable = class;
  TSprite = class;

  //Types used to pass arrays to CardTable detailing specific list of cards that
  //can be dragged and points they can be dragged to.
  TCardList = Array of TCard;
  TDropPoints = Array of TPoint;
  TDropAngles = Array of Single;

  //Exceptions and Events.
  ECardTableError = class(Exception);
  TCardClickEvent = procedure(ACard: TCard; Button: TMouseButton) of object;
  TCardDropEvent = procedure(ACard: TCard; X, Y, RelX, RelY, Index: Integer) of
    object;//New in v1.7 Index parameter into the DropPoints array if used.
  TCardRestoredEvent = procedure of object;//RestoreCardByMove has finished.
  TAreaClickEvent = procedure(X, Y: Integer; Button: TMouseButton) of object;

  //Records.
  TCardMarkRecord = record//Used to draw a card outline or shade on the table.
    Mark: TBitMap;//Just used as a pointer to the mark bitmap.
    Under: TBitMap;
    Displayed: Boolean;
    Position: TPoint;
    //Rotation fields.
    Angle: Single;
    MarkR: TBitMap;
    NA: TPoint;//New axis of rotated bitmap.
    NXY: TPoint;//New x,y of rotated bitmap.
    NW: Integer;//New width/height for rotated mark.
    NH: Integer;
  end;
  PCardMark = ^TCardMarkRecord;

  THQDragShadeRecord = record//Additional data used with CardDeck HQ DragShade.
    ShadedMark: TBitMap;
    RotatedMark: TBitMap;
    RotatedMarkInv: TBitMap;
    X, Y: Integer;
    InstanceFlag: Boolean;
  end;

  //Classes.
  TTableImage = class(TObject)
  private
    FDisplayed: Boolean;
    FBitMap: TBitmap;
    FUnder: TBitMap;
    FOwner: TCardTable;
    FX, FY: Integer;
    procedure SetDisplayed(D: Boolean);
  public
    constructor Create(AOwner: TCardTable);
    destructor Destroy; override;
    procedure Draw(const X,Y: Integer);
    procedure UnDraw;
    procedure LoadPicture(const F: TFileName);
    property Displayed: Boolean read FDisplayed write SetDisplayed;
    property BitMap: TBitMap read FBitMap write FBitMap;
    property Owner: TCardTable read FOwner;
  end;

  TTableArea = class(TObject)
  private
    FEnabled: Boolean;
    FX, FY: Integer;
    FWidth, FHeight: Integer;
    FOnAreaClickEvent: TAreaClickEvent;
    FAreaType: Integer;
    FImage: TTableImage;
    FOwner: TCardTable;
    FUnder: TBitMap;
    procedure SetEnabled(E: Boolean);
  public
    constructor Create(AOwner: TCardTable);
    destructor Destroy; override;
    procedure Draw;
    procedure UnDraw;
    property Enabled: boolean read FEnabled write SetEnabled;
    property X: Integer read FX write FX;
    property Y: Integer read FY write FY;
    property Width: Integer read FWidth write FWidth;
    property Height: Integer read FHeight write FHeight;
    property OnAreaClickEvent: TAreaClickEvent read FOnAreaClickEvent
      write FOnAreaClickEvent;
    property AreaType: Integer read FAreaType write FAreaType;
    property Image: TTableImage read FImage write FImage;
    property Owner: TCardTable read FOwner;
  end;

  TCard = class(TObject)
  private
    FFaceUp: Boolean;
    FSuit: TCardSuit;
    FValue: TCardValue;
    FUnder: TBitMap;//A copy of whats below the card.
    Fx: Integer;//X,Y pos of card on table.
    Fy: Integer;
    FStatus: Integer;//0 in deck, 1 in play, -1 discarded, -2 stripped out.
    FDisplayed: Boolean;//Is the card on the table?
    FFace: TBitMap;
    FFaceR: TBitMap;//Rotated face.
    FAngle: Single;//If <> 0 then FFaceR is used for dropping.
    FNA: TPoint;//New axis of rotated bitmap.
    FNXY: TPoint;//New x,y of rotated bitmap.
    FNW: Integer;//New width/height for rotated card.
    FNH: Integer;
    FOwner: TCardDeck;
    procedure LoadCardFace(const Path, DeckName: string; const ASuit: TCardSuit;
      const AValue: TCardValue; const APath: string);
    procedure SetStatus(const Status: Integer);
    procedure SetRotation(const Angle: Single);
  public
    constructor Create(AOwner: TCardDeck);
    destructor Destroy; override;
    function NumericValue: Integer;
    procedure Assign(Source: TCard); virtual;
    property Owner: TCardDeck read FOwner;
    property Suit: TCardSuit read FSuit write FSuit;
    property Value: TCardValue read FValue write FValue;
    //If on table use CardTable.TurnOverCard NOT this property.
    property FaceUp: Boolean read FFaceUp write FFaceUp;
    property Status: Integer read FStatus write SetStatus;
    property Displayed: Boolean read FDisplayed write FDisplayed;
    property X: Integer read Fx write Fx;
    property Y: Integer read Fy write Fy;
    property Rotation: Single read FAngle write SetRotation;
    property Face: TBitMap read FFace;
  end;

  TCardDeck = class(TPersistent)
  private
    FCardArray: Array[1..MaxCardsInDeck] of TCard;//Now includes jokers.
    FTop: Integer;//Cards dealt 0 - MaxCardsInDeck
    FCardDeckName: TDeckName;
    FNoOfStripped: Integer;
    FNoOfCardBacks: Integer;
    FCardBack: TCardBack;
    FBack: TBitMap;
    FBackR: TBitMap;//Rotated back bitmap.
    FCardMask: TBitMap;
    FCardHeight: Integer;
    FCardWidth: Integer;
    FOwner: TCardTable;
    FCardMarks: Array[1..MaxOutLines+MaxMarks+MaxSuits*4+1] of TCardMarkRecord;
    FMarkBitMaps: Array[cmOutline..cmDragShade] of TBitMap;//Mark bitmaps.
    FDeckDirectory: string;
    FAltDeckDirectory: string;//Additional alternative cardset location.
    FShadow00: TBitMap;//Now various fields used for the decks shadow.
    FShadow01: TBitMap;
    FShadow02: TBitMap;//Shadow used with TurnOverAnimationLift property.
    FShadow00Under: TBitMap;
    FShadow01Under: TBitMap;
    FShadow00Point: TPoint;
    FShadow01Point: TPoint;
    FShadow00D: TBitMap;//Now 3 new bitmaps used by new Shadowmode.
    FShadow01D: TBitMap;
    FShadow02D: TBitMap;
    FShadow00M: TBitMap;//Masks for 0 & 1.
    FShadow00IM: TBitMap;//Inverted masks for 0 & 1.
    FShadow01M: TBitMap;
    FShadow01IM: TBitMap;
    FCardMaskInv: TBitMap;//Inverted mask used for new hq drag shade.
    FFaceUp: Boolean;//Is the deck displayed face up or down.
    FNoOfCards: Integer;
    FScale: Single;
    FScaleDeck: Integer;//Indirectly sets scale.
    FBaseDeck: TPoint;//Holds where deck was placed.
    FHQDragShade: THQDragShadeRecord;//Added data for HQ DragShade.
    procedure LoadBitMap(var BitMap: TBitMap; const FileName: string);
    procedure LoadCardBack(Back: TCardBack);
    procedure LoadDeck;
    procedure SetDeckName(const ADeckName: TDeckName);
    procedure SetNewBitmap(var BitMap, NewBitMap: TBitMap);
    procedure SetFaceUp(const Mode: Boolean);
    procedure SetNoOfCards(const Size: Integer);
    function  PeekAtDeck(I: Integer): TCard;
    procedure SetScale(const S: Single);
    procedure SetScaleDeck(const SetScale: Integer);//Sets a good scale type.
    function TestedScale(const SetScale: Integer): Single;
    procedure RotateBack(const Angle: Single);
    function GetCardMark(I: Integer): PCardMark;
    procedure SetAltDeckDirectory(const s: string);
    function GetNoOfBacks: Integer;
  public
    //2nd Overloaded constructor should be used when you know the CardSets dir.
    constructor Create(AOwner: TCardTable); overload;
    constructor Create(AOwner: TCardTable; const DeckDirectory: string);
      overload;
    destructor Destroy; override;
    //The no of cards in deck. Index set True only used with a stripped deck and
    //PeekDeck property to index the array.
    function NoOfCardsInDeck(const Index: Boolean = false): Integer;
    procedure Shuffle;
    function Draw: TCard;
    function DrawN(const N: Integer): TCard;//Draws card at N from deck.
    procedure Return(const ACard: TCard);
    procedure SelectBack;//Select back graphic via a form.
    procedure SelectDeck;//Select deck used via a form.
    procedure Assign(Source: TPersistent); override;
    procedure ResetDeck;//Resets card & deck fields to initial full deck state.
    procedure AddCardsToDeck(var Cards: Array of TCard);
    procedure OrderDeck;
    procedure StripDeck(const C: TCardList);
    function NoOfJokers: Integer;
    property Owner: TCardTable read FOwner;
    property CardHeight: Integer read FCardHeight;
    property CardWidth: Integer read FCardWidth;
    property NoOfCardBacks: Integer read FNoOfCardBacks;
    property DeckDirectory: string read FDeckDirectory;
    //New property allows alternative additional location for cardsets.
    property AltDeckDirectory: string read FAltDeckDirectory
      write SetAltDeckDirectory;
    property FaceUp: Boolean read FFaceUp write SetFaceUp;
    //NoOfCards now implicitly uses jokers. Thus 52-54 or 104-108 are valid.
    property NoOfCards: Integer read FNoOfCards write SetNoOfCards;
    //Perhaps useful in some circumstances to peek at the deck.
    property PeekDeck[I: Integer]: TCard read PeekAtDeck;
    property NoOfStripped: Integer read FNoOfStripped;
    property Scale: Single read FScale write SetScale;
    property ScaleDeck: Integer read FScaleDeck write SetScaleDeck;
    property CardMask: TBitMap read FCardMask;//Surface the mask.
    property CardMaskInv: TBitMap read FCardMaskInv;
    property BackBitMap: TBitMap read FBack;//Surface deck back.
    property BaseDeck: TPoint read FBaseDeck write FBaseDeck;
    property CardMarks[I: Integer]: PCardMark read GetCardMark;
  published
    property DeckName: TDeckName read FCardDeckName write SetDeckName;
    property CardBack: TCardBack read FCardBack write LoadCardBack;
  end;

  TCardTable = class(TGraphicControl)
  private
    FBitMap: TBitMap;//Table buffer.
    FDirectory: string;//Program Startup Directory;
    FJpeg: TJpegImage;//Holds jpeg picture if used.
    FJpegPerformance: TJPEGPerformance;//Display speed of the Jpeg.
    FCardDeck: TCardDeck;//Owned & freed by this object.
    FExternalDeck: TCardDeck;//Pointer to an external deck that can be clicked.
    FDiscardsAt: TPoint;//A pile of unusable discards.
    FNoOfDiscards: Integer;
    FDiscardArray: Array[1..MaxCards] of TCard;
    FOnCardClickEvent: TCardClickEvent;
    FOnExternalCardClickEvent: TCardClickEvent;
    FOnCardDropEvent: TCardDropEvent;
    FColor: TColor;//If no background bitmap then this is table color.
    FFileName: TFileName;//Name of background bitmap if used or 'None' if not.
    FStretchBackground: Boolean;//Is pic stretched to fit the table or tiled.
    FCardSpeed: Integer;
    FCardsOnTable: Array[1..MaxCards] of TCard;//A stack of the cards on table.
    FNoOfCardsOnTable: Integer;//The no of cards on the table.
    FCopyToScreen: Boolean;//Set to false during resizing to reduce flicker.
    FPlaceDeckOffset: Integer;//Allows a pseudo 3d look to the deck.
    FDragAndDrop: Boolean;//Is drag & drop enabled.
    FDragFromDeck: Boolean;//If DragAndDrop can we drag a card from the deck.
    FCardDraggedFromDeck : Boolean;//Has card been dragged from the deck.
    FDragFaceDown: Boolean;//Can we drag face down cards.
    FCardDragging: Boolean;//Is a card currently being dragged.
    FDraggingCard: TCard;//The dragged card.
    FDraggedAngle: Single;//The dragged cards original rotation.
    FDragOrigin: TPoint;//The Dragged cards original position on screen.
    FCOTPosition: Integer;//Drag card pos in CardsOnTable array, 0 if in deck.
    FDragCards: TCardList;//User defined list of cards that can be dragged.
    FDropPoints: TDropPoints;//User list of points that can be dropped on to.
    FDropAngles: TDropAngles;//And the angle in radians dropped.
    FMouseRelX: Integer;//Mouse x pos relative to dragged card.
    FMouseRelY: Integer;//Mouse y pos relative to dragged card.
    FPreDragCursor: TCursor;//Cursor used prior to the drag.
    FShadePlaced: Boolean;//Has a shade been placed whilst card is dragged.
    FSaveTable: Boolean;//Flags to DefineProperties to save cards as well.
    FRefreshLabels: Boolean;//Should we repaint any labels on the table.
    FAutoResize: Boolean;//Default False Auto resizes table to size of form.
    FMinWidth: Integer;//Min width of owner form.
    FMinHeight: Integer;//Min height of owner form.
    FBackDrop: TBackDrop;//Gradiant backdrop.
    FTOAS: Integer;//If >0 then turn overs of cards displayed are animated.
    FTOAV: Boolean;//Default true vertical card flips.
    FTOAL: Boolean;//If true card shadow displayed during turn over.
    FStack:array[0..9] of Integer;//Used by auto shade system.
    FStackTop: Integer;
    FShadeSetByPoint: Integer;//The shade was set by this point in points array.
    FAutoShadeMode: Integer;//There are 2 different shade switching methods.
    FLiftOffset: Boolean;//Is there an offset whilst dragging?
    FSlowMoveRegion: Boolean;//1 pixel move region around move/drop point.
    FSMR_WaitMode: Boolean;//SlowMoveRegion wait mode slows down movement.
    FSprite: TSprite;//One sprite defined for table.
    FTurnAnimations: Boolean;//Easy way to disable all turn over animations.
    FShadowMode: TShadowMode;
    FDragCardCursor: TCursor;
    FOnCardRestoredEvent: TCardRestoredEvent;
    FFastMovementMode: Boolean;//Default false. See comments at top of file.
    FSoftShadow: Boolean;//Default true. This is a soft shadow else hard.
    FHQDragShade: Boolean;//Default true. Is High quality shaded dragshade used.
    FHQDragShadeColour: Integer;//Colour of HQ drag shade.
    FTableAreas: Array[1..MaxAreas] of TTableArea;
  protected
    procedure BackDropRefresh;
    procedure FormIsResizing(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure WMEraseBkgnd(var Msg: TMessage); message WM_ERASEBKGND;
    procedure PutDown(const ACard: TCard; const X, Y: Integer;
      const Deck: TCardDeck; const SaveBack: boolean = true;
      const Angle: Single = 0);//To buffer.
    procedure PutDownShadow(const X, Y: Integer; const Deck: TCardDeck);
    procedure PickUp(const ACard: TCard; const Deck: TCardDeck);//From buffer.
    procedure PickUpShadow(const Deck: TCardDeck);
    procedure CopyImage(const X, Y, Width, Height: Integer);
    procedure SetColor(const Color: TColor);
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);
      override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
      override;
    function MouseButtonPressed(const X, Y: Integer): TCard;
    procedure LoadTableTop(const FileName: TFileName);
    procedure SetSpeed(const Speed: Integer);
    function GetCanvas: TCanvas;
    procedure PickUpCoveringCards2(const ACard: TCard; const Deck: TCardDeck;
      var Rect: TRect; var Covering: TCardList; var Result: Integer;
      const BeginingMove: Boolean = True; const TopCard: Boolean = False);
    procedure ReplaceCoveringCards(var Covering: TCardList);
    function GetCardOnTable(I: Integer): TCard;
    procedure SetDeckOffset(const Offset: Integer);
    procedure SetDragAndDrop(const Mode: Boolean);
    procedure SetDragFromDeck(const Mode: Boolean);
    procedure SetDragFaceDown(const Mode: Boolean);
    procedure SetCardDeck(const Deck: TCardDeck);
    procedure SetJpegPerformance(const Performance: TJPEGPerformance);
    procedure RedrawBuffer;
    procedure PlaceCardMarkers;
    procedure Resize; override;
    procedure SetTOAS(const Speed: Integer);//Turn Over Animation Speed.
    procedure SetTOAV(const Mode: Boolean);//Turn Over Animation Vertical.
    procedure SetTOAL(const Mode: Boolean);//Turn Over Animation Lift.
    procedure StretchPutDown(const ACard: TCard; const Deck: TCardDeck;
      const AnimateValue: Integer);
    procedure SetDragCards(const P: TCardList);
    procedure SetDropPoints(const P: TDropPoints);
    procedure SetDropAngles(const P: TDropAngles);
    procedure SetAutoShadeMode(const Mode: Integer);
    procedure SetStretchBackground(const Mode: Boolean);
    function LiftTurnOverCard(const ACard: TCard): Boolean;
    procedure SetLiftOffset(const Mode: Boolean);
    procedure SetShadeColour(const C: Integer);
    //Methods to save/load table + cards via streaming system.
    procedure DefineProperties(Filer: TFiler); override;
    procedure WriteNoOfCards(Writer: TWriter);
    procedure ReadNoOfCards(Reader: TReader);
    procedure WriteDeckFaceUp(Writer: TWriter);
    procedure ReadDeckFaceUp(Reader: TReader);
    procedure WriteCardValue(Writer: TWriter);
    procedure ReadCardValue(Reader: TReader);
    procedure WriteCardSuit(Writer: TWriter);
    procedure ReadCardSuit(Reader: TReader);
    procedure WriteFaceUp(Writer: TWriter);
    procedure ReadFaceUp(Reader: TReader);
    procedure ReadStatus(Reader: TReader);
    procedure WriteStatus(Writer: TWriter);
    procedure WriteDisplayed(Writer: TWriter);
    procedure ReadDisplayed(Reader: TReader);
    procedure ReadX(Reader: TReader);
    procedure WriteX(Writer: TWriter);
    procedure ReadY(Reader: TReader);
    procedure WriteY(Writer: TWriter);
    procedure ReadFT(Reader: TReader);
    procedure WriteFT(Writer: TWriter);
    procedure ReadNoOfCOT(Reader: TReader);
    procedure WriteNoOfCOT(Writer: TWriter);
    procedure ReadCOT(Reader: TReader);
    procedure WriteCOT(Writer: TWriter);
    procedure ReadCardMarks(Reader: TReader);
    procedure WriteCardMarks(Writer: TWriter);
    procedure ReadD2Name(Reader: TReader);
    procedure WriteD2Name(Writer: TWriter);
    procedure ReadD2Back(Reader: TReader);
    procedure WriteD2Back(Writer: TWriter);
    procedure WriteScale(Writer: TWriter);
    procedure ReadScale(Reader: TReader);
    procedure ReadScaleD(Reader: TReader);
    procedure WriteScaleD(Writer: TWriter);
    procedure ReadRotation(Reader: TReader);
    procedure WriteRotation(Writer: TWriter);
    function GetArea(I: Integer): TTableArea;
    procedure SetArea(I: Integer; Value: TTableArea);
  public
    procedure Wait(n: Integer);
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure PlaceDeck(const X, Y: Integer; Deck: TCardDeck = nil);
    procedure SetDrawnCard(const ACard: TCard);//Sets the drawn card.
    //DrawCardFromDeck is quick way to draw from a displayed deck.
    function DrawCardFromDeck(Deck: TCardDeck = nil): TCard;
    procedure PlaceCard(const ACard: TCard; const X, Y: Integer;
      const Angle: Single = 0);
    procedure PickUpCard(const ACard: TCard; const TopCard: Boolean = False);
    procedure MoveTo(const ACard: TCard; const X, Y: Integer);
    procedure TurnOverCard(const ACard: TCard; const TopCard: Boolean = False);
    procedure Discard(const ACard: TCard);
    procedure PickUpDeck(Deck: TCardDeck = nil);
    procedure PickUpDiscards;
    procedure PickUpCardsOnTable;
    procedure PickUpAllCardsAndReset(Deck: TCardDeck = nil);
    procedure Paint; override;
    procedure Show;
    procedure SortHand(var Hand: array of TCard; const AcesLow: Boolean;
      const SuitSort: Boolean; const Planes: Integer = 1);
    procedure DropCard(X, Y: Integer; const Move: Boolean = False;
      const Angle: Single = 0);
    procedure RestoreCard;//Restore dragged card to its origin.
    //As RestoreCard but moves onscreen the card. Yes some methods use a Move
    //parameter instead of a new method & yes it is inconsistant.
    procedure RestoreCardByMove;
    procedure PlaceCardMarker(const CardMarker: TCardMarker; const X, Y:
      Integer; const No: Integer = 1; Deck: TCardDeck = nil;
      const Angle: Single = 0; const Copy: Boolean = True);
    procedure PickUpMarker(const CardMarker: TCardMarker; const No: Integer = 1;
      Deck: TCardDeck = nil; const Copy: Boolean = True);
    procedure PickUpAllMarkers(Deck: TCardDeck = nil);
    procedure DropCardOnShade(const CardMarker: TCardMarker;
      const No: Integer = 1; Deck: TCardDeck = nil;const Move: Boolean = False);
    procedure ClearTable;//Clears the table.
    procedure SelectBackgroundPicture(const Dir: TFileName = '');
    procedure SaveStatus(Path: TFileName = '');
    procedure LoadStatus(Path: TFileName = '');
    function DragCardWithinBounds(const Bounds: TRect): Boolean;
    procedure ResizeTable(const Left, Top, Width, Height: integer);
    procedure DeckOrBackChanged;//Redraws table after deck/back change.
    procedure SaveTable(const FileName: TFileName; Path: TFileName = '');
    procedure LoadTable(const FileName: TFileName; Path: TFileName = '');
    procedure RefreshLabels;
    function DrawCardNFromDeck(const N, X, Y: Integer; Deck: TCardDeck = nil)
      : TCard;
    procedure RotateCard(const ACard: TCard; const ToRad: Single);
    function CardMarkIndex(const CardMarker: TCardMarker): Integer;
    procedure DrawTableAreas(const NotType: Integer = -1);
    procedure DrawTableArea(const AType: Integer);
    procedure UnDrawTableAreas(const NotType: Integer = -1);
    property TableCanvas: TCanvas read GetCanvas;//Surfacing the buffer.
    property TableBitMap: TBitMap read FBitMap;//Sometimes need the bitmap.
    property CardDragging: Boolean read FCardDragging;
    property DraggingCard: TCard read FDraggingCard;
    property CardDraggedFromDeck: Boolean read FCardDraggedFromDeck;
    property DragCards: TCardList read FDragCards write SetDragCards;
    property DropPoints: TDropPoints read FDropPoints write SetDropPoints;
    property DropAngles: TDropAngles read FDropAngles write SetDropAngles;
    //External deck can be set to point to an external deck object. This deck
    //can then be selected with the mouse & will be redrawn when necessary. This
    //means a limit of 2 visible decks that can be selected & redrawn
    //automatically when needed on the table.
    property ExternalDeck: TCardDeck read FExternalDeck write FExternalDeck;
    property ShadePlaced: Boolean read FShadePlaced;
    property NoOfCardsOnTable: Integer read FNoOfCardsOnTable;
    property CardsOnTable[I: Integer]: TCard read GetCardOnTable;
    property DiscardsPoint: TPoint read FDiscardsAt write FDiscardsAt;
    property Directory: string read FDirectory;//Program directory.
    property Sprite: TSprite read FSprite;
    property TurnAnimations: Boolean read FTurnAnimations write FTurnAnimations;
    property CopyToScreen: Boolean read FCopyToScreen write FCopyToScreen;
    property TableAreas[I: Integer]: TTableArea read GetArea write SetArea;
  published
  //Note no default values as streaming system is used by save/load status/table
  //and default values are not written to the stream. It`s possible to loop thru
  //the properties and obtain the default values at runtime. You could then set
  //the properties before loading the resource files. You could then use default
  //values and save/load status/table would still work ok. But help system is
  //not at all helpfull with regard to this and it would require a fair bit of
  //effort for not much reward so I can`t be bothered as there aren`t a great
  //many published properties anyway.
    property Align;//Give value of alClient to make the table the size of form.
    property Enabled;
    property OnClick;
    property OnMouseDown;
    property OnMouseUp;
    property OnCardClickEvent: TCardClickEvent read FOnCardClickEvent
      write FOnCardClickEvent;
    property OnExternalCardClickEvent: TCardClickEvent
      read FOnExternalCardClickEvent write FOnExternalCardClickEvent;
    property OnCardDropEvent: TCardDropEvent read FOnCardDropEvent
      write FOnCardDropEvent;
    property OnMouseMove;
    property CardDeck: TCardDeck read FCardDeck write SetCardDeck;
    property Visible;
    property StretchBackground: Boolean read FStretchBackground write
      SetStretchBackground;
    property PlaceDeckOffset: Integer read FPlaceDeckOffset write SetDeckOffset;
    property Cursor;
    property DragCardCursor: TCursor read FDragCardCursor write FDragCardCursor;
    //The color of table if no bitmap is used.
    property Color: TColor read FColor write SetColor;
    property BackDrop: TBackDrop read FBackDrop write FBackDrop;
    property JpegPerformance: TJPEGPerformance read FJpegPerformance write
      SetJpegPerformance;//Display speed + quality of Jpeg.
    //Nb for BackgroundPicture filename must be fully qualified. So if in
    //program directory use cardtable.directory + '\pic.***' not just 'pic.***'.
    property Width;//When resizing use the ResizeTable function not Width or
    property Height;//Height.
    property Left;//Left & Top are safe to use if not resizing as well.
    property Top;
    property BackgroundPicture: TFileName read FFileName write LoadTableTop;
    property CardSpeed: Integer read FCardSpeed write SetSpeed;
    property DragAndDrop: Boolean read FDragAndDrop write SetDragAndDrop;
    property DragFromDeck: Boolean read FDragFromDeck write SetDragFromDeck;
    property DragFaceDown: Boolean read FDragFaceDown write SetDragFaceDown;
    property LiftOffset: Boolean read FLiftOffset write SetLiftOffset;
    property RepaintLabels: Boolean read FRefreshLabels write FRefreshLabels;
    property AutoResize: Boolean read FAutoResize write FAutoResize;
    property MinWidth: Integer read FMinWidth write FMinWidth;
    property MinHeight: Integer read FMinHeight write FMinHeight;
    property TurnOverAnimationSpeed: Integer read FTOAS write SetTOAS;
    property TurnOverAnimationVertical: Boolean read FTOAV write SetTOAV;
    property TurnOverAnimationLift: Boolean read FTOAL write SetTOAL;
    property AutoShadeMode: Integer read FAutoShadeMode write SetAutoShadeMode;
    property SlowMoveRegion: Boolean read FSlowMoveRegion write FSlowMoveRegion;
    property ShadowMode: TShadowMode read FShadowMode write FShadowMode;
    property SoftShadow: Boolean read FSoftShadow write FSoftShadow;
    property SMR_WaitMode: Boolean read FSMR_WaitMode write FSMR_WaitMode;
    property OnCardRestoredEvent: TCardRestoredEvent read FOnCardRestoredEvent
      write FOnCardRestoredEvent;
    property FastMovementMode: Boolean read FFastMovementMode
      write FFastMovementMode;
    property HQDragShade: Boolean read FHQDragShade write FHQDragShade;
    property HQDragShadeColour: Integer read FHQDragShadeColour
      write SetShadeColour;
  end;

  TSprite = class(TObject)
  private
    FOwner: TCardTable;
    FX, FY, FNX, FNY, FWidth, FHeight: Integer;
    FNA: TPoint;
    FAngle: Single;
    FScale: Single;
    FUnder: TBitMap;
    FBitMap: TBitMap;
    FTranny: TBitMap;
    FDisplayed: Boolean;
    FRelative: Boolean;
    procedure Undo;
  public
    constructor Create(AOwner: TCardTable);
    destructor Destroy; override;
    procedure Draw;
    procedure UnDraw;
    procedure Lift(const ACard: TCard; const MilliSecs: Integer;
      const S: Single; const Reverse: boolean = false);
    procedure Shrink(const ACard: TCard; const Target: Single);
    procedure Grow(const ACard: TCard; const Target, StartScale: Single);
    procedure Rotate(const ACard: TCard; const MilliSecs: Integer;
      const R: Single);
//Saves transformed sprite pic.
    procedure SaveToFile(const FileName: TFileName; const pf: TPixelFormat);
    property X: Integer read FX write FX;
    property Y: Integer read FY write FY;
    property Scale: Single read FScale write FScale;
    property Angle: Single read FAngle write FAngle;
    property BitMap: TBitMap read FBitMap write FBitMap;
    property Displayed: Boolean read FDisplayed;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property NewX: Integer read FNX;
    property NewY: Integer read FNY;
  end;

var
  gImageArray: TImageArray;//Card image transformations done by this class.

implementation

uses
  Vcl.Forms
  , System.Math
  , System.TypInfo
  , Vcl.ExtDlgs
  , System.DateUtils
  , CardGames.Vcl.CardBackForm
  , CardGames.Vcl.CardDeckForm
  , CardGames.Vcl.DeckPathForm
  , CardGames.WinApi.MyGrphx
  ;

//............................................................................//
//............................ T C A R D .....................................//
//............................................................................//

constructor TCard.Create(AOwner: TCardDeck);
//A card is part of a deck, the deck determines its size & look.
begin
  inherited Create;
  FFaceUp := False;
  FUnder := TBitMap.Create;
  FDisplayed := false;
  FFace := TBitMap.Create;
  FOwner := AOwner;
  FFaceR := TBitMap.Create;
  FFaceR.Transparent := True;
  FFaceR.PixelFormat := pf32bit;
  FAngle := 0;
end;

destructor TCard.Destroy;
//Call free not this method.
begin
  FUnder.Free;
  FFace.Free;
  FFaceR.Free;
  inherited Destroy;
end;

function TCard.NumericValue: Integer;
//Returns a card's numeric value.
begin
  Result := Ord(FValue) + 1;
  if Result > 10 then Result := 10;
end;

procedure TCard.LoadCardFace(const Path, DeckName: string;
  const ASuit: TCardSuit; const AValue: TCardValue; const APath: string);
//Private method that loads a face bitmap.
var
  FileName: string;
begin
  if Ord(AValue) < 9 then FileName := '\0' else FileName := '\';
  if ASuit = csJoker then
//Two jokers named 01joker & 02joker are used.
    if (Ord(AValue) = 0) or (Ord(AValue) = 2) then
      FileName := FileName + IntToStr(1)
    else
      FileName := FileName + IntToStr(2)
  else
    FileName := FileName + IntToStr(Ord(AValue) + 1);
  case ASuit of
    csHeart: FileName := FileName + 'h.bmp';
    csSpade: FileName := FileName + 's.bmp';
    csClub: FileName := FileName + 'c.bmp';
    csDiamond: FileName := FileName + 'd.bmp';
    csJoker: FileName := FileName + 'joker.bmp';
  end;
  if (APath <> '') and FileExists(APath + '\' + DeckName + FileName) then
    FFace.LoadFromFile(APath + '\' + DeckName + FileName)
  else
    FFace.LoadFromFile(Path + '\' + DeckName + FileName);
  FFace.Dormant;
  FFace.FreeImage;
  FUnder.Height := FFace.Height;
  FUnder.Width := FFace.Width;
end;

procedure TCard.SetStatus(const Status: Integer);
begin
  if (Status >= -2) and (Status <= 1) then
    FStatus := Status;
end;

procedure TCard.Assign(Source: TCard);
//Copying all but FOwner.
begin
  FFaceUp := Source.FFaceUp;
  FSuit := Source.FSuit;
  FValue := Source.FValue;
  FUnder.Free;
  FUnder := TBitMap.Create;
  FUnder.Assign(Source.FUnder);
  Fx := Source.Fx;
  Fy := Source.Fy;
  FStatus := Source.FStatus;
  FDisplayed := Source.FDisplayed;
  FFace.Free;
  FFace := TBitMap.Create;
  FFace.Assign(Source.FFace);
  Rotation := Source.FAngle;
end;

procedure TCard.SetRotation(const Angle: Single);
//Creates bitmap of rotation Angle in FFaceR. Rotated back is created when
//needed in CardTable.PutDown & uses FNW/H set here.
begin
  FAngle := Angle;
  if FAngle <> 0 then
  begin
    gImageArray.AssignFromBitmap(FFace);
    gImageArray.RotateBitmap(FFaceR, Angle, Point(FFace.Width shr 1,
      FFace.Height shr 1), FNA, 1, False);
    FNW := FFaceR.Width;
    FNH := FFaceR.Height;
  end;
end;



//............................................................................//
//......................... T C A R D D E C K ................................//
//............................................................................//

constructor TCardDeck.Create(AOwner: TCardTable);
//A deck of cards. The 2nd overloaded constructor should be used when you know
//the CardSets dir as for instance when a CardTable has been instantiated:
//Property CardTable.CardDeck.DeckDirectory. Will look for the cardsets
//directory in the current directory, in any directory in the path environment
//variable or in config,txt file.
var
  Result: Integer;
  OptionList: TIniFile;
  DeckPathForm: TDeckPathForm;
  S: string;
begin
  inherited Create;
  FOwner := AOwner;
  FScale := 1;
  S := ExtractFilePath(Application.ExeName);
  if FileExists(S + '\CardSettings.ini') then
  begin
    OptionList := TIniFile.Create(S + '\CardSettings.ini');
    try
      FDeckDirectory := StringReplace(OptionList.ReadString('CardSet', 'Path', ''),
        '{app}',ExtractFilePath(Application.ExeName), []);
    finally
      OptionList.Free;
    end;
    if not DirectoryExists(FDeckDirectory+'\Standard') then
      FDeckDirectory := '';
    if FDeckDirectory = '' then
      if not (csDesigning in AOwner.ComponentState) then
      begin
        DeckPathForm := TDeckPathForm.Create(FOwner);
        try
          Result := DeckPathForm.ShowModal;
          FDeckDirectory := DeckPathForm.Edit1.Text;
        finally
          DeckPathForm.Release;
        end;
        if (Result = mrOk) and DirectoryExists(FDeckDirectory+'\Standard') then
        begin
          OptionList.WriteString('CardSet', 'Path', FDeckDirectory);
        end
        else
          raise ECardTableError.Create('Cardsets directory not found.');
      end
      else
        raise ECardTableError.Create('Cardsets directory not found.');
  end;
  FAltDeckDirectory := '';
  FCardDeckName := 'Standard';
  FNoOfCardBacks := GetNoOfBacks;
  FNoOfCards := 52;//Also sets jokers to 0.
  LoadDeck;
  FTop := 0;
  FaceUp := False;
  FNoOfStripped := 0;
  FBaseDeck := Point(0,0);
  FHQDragShade.InstanceFlag := False;
end;

constructor TCardDeck.Create(AOwner: TCardTable; const DeckDirectory: string);
//A deck of cards. Use this constructor when you know the CardSets dir.
begin
  inherited Create;
  FOwner := AOwner as TCardTable;
  FScale := 1;
  FDeckDirectory := DeckDirectory;
  FAltDeckDirectory := '';
  FCardDeckName := 'Standard';
  FNoOfCardBacks := GetNoOfBacks;
  FNoOfCards := 52;
  LoadDeck;
  FTop := 0;
  FaceUp := False;
  FNoOfStripped := 0;
  FBaseDeck := Point(0,0);
  FHQDragShade.InstanceFlag := False;
end;

destructor TCardDeck.Destroy;
//Call free not this method.
var
  i: Integer;
  j: TCardMarker;
begin
  for i := 1 to NoOfCards do
    FCardArray[i].Free;
  FBack.Free;
  FBackR.Free;
  FCardMask.Free;
  FShadow00.Free;
  FShadow01.Free;
  FShadow02.Free;
  FShadow00Under.Free;
  FShadow01Under.Free;
  FShadow00D.Free;
  FShadow01D.Free;
  FShadow02D.Free;
  FShadow00M.Free;
  FShadow00IM.Free;
  FShadow01M.Free;
  FShadow01IM.Free;
  for j := low(TCardMarker) to high(TCardMarker) do
    FMarkBitMaps[j].Free;
  for i := 1 to MaxOutLines+MaxMarks+MaxSuits*4+1 do
  begin
    FCardMarks[i].Under.Free;
    FCardMarks[i].MarkR.Free;
  end;
  FCardMaskInv.Free;
  FHQDragShade.ShadedMark.Free;
  FHQDragShade.RotatedMark.Free;
  FHQDragShade.RotatedMarkInv.Free;
  inherited Destroy;
end;

procedure TCardDeck.Shuffle;
//Shuffles the cards in the deck does not have to be a full deck. It must NOT be
//displayed at the time. Shuffles ALL cards even stripped.
var
  i, RandNum: Integer;
  RandCard: TCard;
begin
  for i := FTop + 1 to NoOfCards do
  begin
    RandNum := Random(NoOfCards - 1 - FTop) + 1 + FTop;
    RandCard := FCardArray[RandNum];//Swap next card with
    FCardArray[RandNum] := FCardArray[i];//random card in deck.
    FCardArray[i] := RandCard;
    if RandCard.FStatus <> -2 then
      RandCard.FStatus :=0;
    RandCard.FFaceUp := FaceUp;
    RandCard.FDisplayed := False;
    if FCardArray[i].FStatus <> -2 then
      FCardArray[i].FStatus := 0;
    FCardArray[i].FFaceUp := FaceUp;
    FCardArray[i].FDisplayed := False;
  end;
end;

function TCardDeck.Draw: TCard;
//Returns TCard increasing FTop. Note that if the deck is displayed on the
//table you must next call CardTable.SetDrawnCard(ACard). Nb. If deck is
//displayed drawn & set card MUST be moved away from deck before drawing others.
begin
  repeat
    inc(FTop);
    if FTop = NoOfCards+1 then
    begin
      FTop := NoOfCards;
      Result := nil;
    end else
    begin
      Result := FCardArray[FTop];
      if Result.FStatus <> -2 then
        Result.FStatus := 1;
    end;
  until (Result = nil) or (Result.FStatus = 1);
end;

function TCardDeck.DrawN(const N: Integer): TCard;
//Returns TCard increasing FTop. Allows you to draw card number N from the deck.
//1 is always the top and NoOfCardsInDeck the bottom. Note that if deck is
//displayed always use CardTable.DrawNFromDeck.
var
  i, j: Integer;
begin
  Result := nil;
  if (N < 1) or (N > NoOfCardsInDeck) then exit;
  j := FTop;
  for i := 1 to N do
  begin
    repeat
      inc(j);
    until FCardArray[j].Status <> -2;
    Result := FCardArray[j];
  end;
  Result.FStatus := 1;
  inc(FTop);
  for i := j downto FTop+1 do
    FCardArray[i] := FCardArray[i-1];
  FCardArray[FTop] := Result;
end;

procedure TCardDeck.Return(const ACard: TCard);
//Returns a drawn card to the TOP of the deck. To return cards to the bottom see
//AddCardsToDeck. The card must NOT be displayed on the table at the time. If
//the deck is displayed on the table you must next call CardTable.PlaceDeck with
//the same paramaters as before.
var
  i: Integer;
begin
  if (ACard.Owner <> self) or (ACard.Displayed) or (ACard.Status = 0) then exit;
//Swap FCardArray[Top] with position of ACard within the array.
  for i := FTop downto 1 do
    if FCardArray[i] = ACard then break;
  if FCardArray[i] = ACard then//It should always do.
  begin
    FCardArray[i] := FCardArray[FTop];
    FCardArray[FTop] := ACard;
    ACard.FStatus := 0;
    ACard.FaceUp := self.FaceUp;
    dec(FTop);
  end;
end;

function TCardDeck.NoOfCardsInDeck(const Index: Boolean = false): Integer;
//Returns the no of cards left in the deck. You probably guessed that! Index is
//set to true for use with a stripped deck and PeekDeck property and indexes the
//top of the card array as with unstripped deck. With a stripped deck we cant
//calculate the next card that is the top of the deck, we have to search thru
//array to find card with status <> -2.
var
  i, No: Integer;
begin
  if (NoOfStripped = 0) or Index then Result := NoOfCards - FTop
  else
//Return the number of cards left in the stripped deck.
  begin
    No := 0;
    for i := FTop +1 to NoOfCards do
      if FCardArray[i].FStatus = 0 then inc(No);
    Result := No;
  end;
end;

procedure TCardDeck.LoadCardBack(Back: TCardBack);
//Private method loads deck back.
var
  FileName: string;
  NA: TPoint;
begin
//New will now load non sequential back no. i.e 1,2,3 & 9.
  if Back <> FCardBack then
  begin
    if not (csDesigning in FOwner.ComponentState) then
    begin
      FileName := '';
      if FAltDeckDirectory <> '' then
        if FileExists(FAltDeckDirectory + '\' + FCardDeckName + '\Back' +
          IntToStr(Back) + '.bmp') then
//Precedence taken by alt location.
          FileName := FAltDeckDirectory + '\' + FCardDeckName + '\Back' +
            IntToStr(Back) + '.bmp';
      if FileName = '' then
        if FileExists(FDeckDirectory + '\' + FCardDeckName + '\Back' +
          IntToStr(Back) + '.bmp') then
          FileName := FDeckDirectory + '\' + FCardDeckName + '\Back' +
            IntToStr(Back) + '.bmp'
        else
        begin
          if FAltDeckDirectory <> '' then
            if FileExists(FAltDeckDirectory + '\' + FCardDeckName + '\Back' +
              IntToStr(1) + '.bmp') then
              FileName := FAltDeckDirectory + '\' + FCardDeckName + '\Back' +
              IntToStr(1) + '.bmp';
          if FileName = '' then
//This MUST be true else big bug somewhere.
            FileName := FDeckDirectory + '\' + FCardDeckName + '\Back' +
              IntToStr(1) + '.bmp';
          Back := 1;
        end;
      FBack.LoadFromFile(FileName);
      FBack.Dormant;
      FBack.FreeImage;
      if FScale <> 1 then
      begin
        gImageArray.AssignFromBitmap(FBack);
        gImageArray.RotateBitmap(FBack, 0, Point(0, 0) , NA, FScale, False);
      end;
    end;
    FCardBack := Back;
  end;
end;

procedure TCardDeck.LoadBitMap(var BitMap: TBitMap; const FileName: string);
//Private method loads a bitmap from a file to a TBitMap.
begin
  BitMap.LoadFromFile(FileName);
  BitMap.Dormant;
  BitMap.FreeImage;
end;

function TCardDeck.GetNoOfBacks: Integer;
//Private method returns the no of backs the deck has 1 - 9 consecutive only
//in both locations.
var
  i: Integer;
  FileName, FileNameDoc: string;
begin
  i := 1;
  repeat
    FileName := FDeckDirectory + '\' + FCardDeckName + '\Back' + IntToStr(i) +
      '.bmp';
    FileNameDoc := FAltDeckDirectory + '\' + FCardDeckName + '\Back' +
      IntToStr(i) + '.bmp';
    if FileExists(FileName) or FileExists(FileNameDoc) then
      Inc(i)
    else
      break;
  until (i = 10);
  Dec(i);
  if i <> 0 then Result := i
  else raise ECardTableError.Create('No CardBacks Found.');
end;

procedure TCardDeck.OrderDeck;
//Orders deck into initial state for replicatable deals.
var
  i, j: Integer;
  ASuit: TCardSuit;
  AValue: TCardValue;
  ACard: TCard;
begin
  ASuit := csClub;
  AValue := cvAce;
  for i := 1 to NoOfCards - NoOfJokers do
  begin
//Card i must have values AValue & ASuit.
    for j := i to NoOfCards do
      if (FCardArray[j].Value = AValue) and (FCardArray[j].Suit = ASuit) then
        break;
//Card j has those values.
    ACard := FCardArray[i];
    FCardArray[i] := FCardArray[j];
    FCardArray[j] := ACard;
    if (i mod 4 = 0) then
      if AValue <> cvKing then
        inc(AValue)
      else
        AValue := cvAce;
    if Ord(ASuit) <> Ord(High(TCardSuit))-1 then
      inc(ASuit)
    else
      ASuit := Low(TCardSuit);
  end;
//Now reorder the jokers.
  ASuit := csJoker;
  AValue := cvAce;
  for i := NoOfCards - NoOfJokers + 1 to NoOfCards - 1 do
  begin
    for j := i to NoOfCards do
      if (FCardArray[j].Value = AValue) and (FCardArray[j].Suit = ASuit) then
        break;
    ACard := FCardArray[i];
    FCardArray[i] := FCardArray[j];
    FCardArray[j] := ACard;
    inc(AValue);
  end;
end;
{$WARNINGS OFF}
procedure TCardDeck.LoadDeck;
//Private method that loads card bitmaps and assign values and suits if not
//already assigned.
var
  i: Integer;
  ASuit: TCardSuit;
  AValue: TCardValue;
  FileName: TFileName;
  j: TCardMarker;
  Path: string;
begin
  ASuit := csClub;
  AValue := cvAce;
  if not (csDesigning in FOwner.ComponentState) then
  begin
    for i := 1 to NoOfCards - NoOfJokers do
    begin
      if not Assigned(FCardArray[i]) then
      begin
        FCardArray[i] := TCard.Create(self);
        FCardArray[i].FValue := AValue;
        FCardArray[i].FSuit := ASuit;
      end;//Else keep already assigned suit & value.
      FCardArray[i].LoadCardFace(FDeckDirectory, FCardDeckName,
        FCardArray[i].FSuit, FCardArray[i].FValue, FAltDeckDirectory);
      if (i mod 4 = 0) then
        if AValue <> cvKing then inc(AValue) else AValue := cvAce;
      if Ord(ASuit) <> Ord(High(TCardSuit))-1 then
        inc(ASuit)
      else
        ASuit :=Low(TCardSuit);
    end;
    for i := NoOfCards - NoOfJokers +1 to NoOfCards do
//Jokers increment in value from ace to four.
    begin
      if not Assigned(FCardArray[i]) then
      begin
        FCardArray[i] := TCard.Create(self);
        FCardArray[i].FValue := TCardValue(NoOfJokers - (NoOfCards - i) - 1);
        FCardArray[i].FSuit := csJoker;
      end;//Else keep already assigned suit & value.
      FCardArray[i].LoadCardFace(FDeckDirectory, FCardDeckName,
        FCardArray[i].FSuit, FCardArray[i].FValue, FaltDeckDirectory);
    end;
    if not Assigned(FBack) then FBack := TBitMap.Create;
    if not Assigned(FBackR) then
    begin
      FBackR := TBitMap.Create;
      FBackR.Transparent := True;
      FBackR.PixelFormat := pf32bit;
    end;
    if not Assigned(FCardMask) then FCardMask := TBitMap.Create;
    if not Assigned(FCardMaskInv) then FCardMaskInv := TBitMap.Create;//New!
    if not Assigned(FShadow00) then FShadow00 := TBitMap.Create;
    if not Assigned(FShadow01) then FShadow01 := TBitMap.Create;
    if not Assigned(FShadow02) then FShadow02 := TBitMap.Create;
    if not Assigned(FShadow00D) then FShadow00D := TBitMap.Create;
    if not Assigned(FShadow01D) then FShadow01D := TBitMap.Create;
    if not Assigned(FShadow02D) then FShadow02D := TBitMap.Create;
    if not Assigned(FShadow00Under) then FShadow00Under := TBitMap.Create;
    if not Assigned(Fshadow01Under) then FShadow01Under := TBitMap.Create;
//Now masks for new shaded shadows.
    if not Assigned(FShadow00M) then FShadow00M := TBitMap.Create;
    if not Assigned(FShadow00IM) then FShadow00IM := TBitMap.Create;
    if not Assigned(FShadow01M) then FShadow01M := TBitMap.Create;
    if not Assigned(FShadow01IM) then FShadow01IM := TBitMap.Create;
    Path := FDeckDirectory;
    if FAltDeckDirectory <> '' then
//Checking for existence of 1 of the support files.
      if FileExists(FAltDeckDirectory + '\' + FCardDeckName + '\Shadow00M.bmp')
      then
        Path := FAltDeckDirectory;
    LoadBitMap(FShadow00M, Path + '\' + FCardDeckName + '\Shadow00M.bmp');
    LoadBitMap(FShadow00IM, Path + '\' + FCardDeckName + '\Shadow00IM.bmp');
    LoadBitMap(FShadow01M, Path + '\' + FCardDeckName + '\Shadow01M.bmp');
    LoadBitMap(FShadow01IM, Path + '\' + FCardDeckName + '\Shadow01IM.bmp');
//Load card mark bitmaps.
    for j := cmOutline to cmDragShade do
    begin
      if not Assigned(FMarkBitMaps[j]) then
        FMarkBitmaps[j] := TBitmap.Create;
      case j of
        cmOutline..cmMark: FileName := '/Bottom0' + IntToStr(Ord(j)+1);
        cmClub..cmSpade: FileName := '/Bottom0' + IntToStr(Ord(j)+2);
        cmDragShade: FileName := '/Shade';
      end;
      FileName := FileName + '.bmp';
      LoadBitmap(FMarkBitMaps[j], Path + '\' + FCardDeckName + FileName);
    end;
//Setup the card marks.
    for i := 1 to MaxOutLines+MaxMarks+MaxSuits*4+1 do
    begin
      if not Assigned(FCardMarks[i].Under) then
        FCardMarks[i].Under := TBitMap.Create;
      if not Assigned(FCardMarks[i].MarkR) then
      begin
        FCardMarks[i].MarkR := TBitMap.Create;
        FCardMarks[i].MarkR.Transparent := True;
        FCardMarks[i].MarkR.PixelFormat := pf32bit;
      end;
      case i of
        1..MaxOutLines: j := cmOutline;
        MaxOutLines+1..MaxOutLines+MaxMarks: j := cmMark;
        MaxOutLines+MaxMarks+1..MaxOutLines+MaxMarks+MaxSuits: j := cmClub;
        MaxOutLines+MaxMarks+MaxSuits+1..MaxOutLines+MaxMarks+MaxSuits*2:
          j := cmDiamond;
        MaxOutLines+MaxMarks+MaxSuits*2+1..MaxOutLines+MaxMarks+MaxSuits*3:
          j := cmHeart;
        MaxOutLines+MaxMarks+MaxSuits*3+1..MaxOutLines+MaxMarks+MaxSuits*4:
          j := cmSpade;
        MaxOutLines+MaxMarks+MaxSuits*4+1: j := cmDragShade;//1 drag shade.
      end;
      FCardMarks[i].Under.Width := FMarkBitMaps[j].Width;
      FCardMarks[i].Under.Height := FMarkBitMaps[j].Height;
      FCardMarks[i].Mark := FMarkBitMaps[j];
    end;
//Added data for HQ DragShade.
    if not Assigned(FHQDragShade.ShadedMark) then
      FHQDragShade.ShadedMark := TBitMap.Create;
    if not Assigned(FHQDragShade.RotatedMark) then
      FHQDragShade.RotatedMark := TBitMap.Create;
    if not Assigned(FHQDragShade.RotatedMarkInv) then
      FHQDragShade.RotatedMarkInv := TBitMap.Create;
    //LoadCardBack won`t actually load the bitmap if FCardBack is the value of
    //passed parameter. So have to set it to 0 to ensure the bitmap is loaded.
    FCardBack := 0;
    LoadCardBack(1);
    LoadBitMap(FCardMask, Path + '\' + FCardDeckName + '\CardMask.bmp');
//Invert the card mask for HQDragShade.
    FCardMaskInv.Width := FCardMask.Width;
    FCardMaskInv.Height := FCardMask.Height;
    BitBlt(FCardMaskInv.Canvas.Handle, 0, 0, FCardMask.Width, FCardMask.Height,
      FCardMask.Canvas.Handle, 0, 0, NOTSRCCOPY);
    LoadBitMap(FShadow00, Path + '\' + FCardDeckName + '\Shadow00.bmp');
    LoadBitMap(FShadow01, Path + '\' + FCardDeckName + '\Shadow01.bmp');
    //In all cases apart from decks C_1 & C_2 Shadow02.bmp is same as shade.bmp.
    if (CompareText(FCardDeckName, 'C_2') = 0) or
      (CompareText(FCardDeckName, 'C_1') = 0) then
      LoadBitMap(FShadow02, Path + '\' + FCardDeckName + '\Shadow02.bmp')
    else
      SetNewBitMap(FShadow02,
        FCardMarks[MaxOutLines+MaxMarks+MaxSuits*4+1].Mark);
    FShadow00Under.Width := FShadow00.Width;
    FShadow00Under.Height := FShadow00.Height;
    FShadow01Under.Width := FShadow01.Width;
    FShadow01Under.Height := FShadow01.Height;
    FShadow00D.Width := FShadow00.Width;
    FShadow00D.Height := FShadow00.Height;
    FShadow01D.Width := FShadow01.Width;
    FShadow01D.Height := FShadow01.Height;
    FShadow02D.Width := FShadow02.Width;
    FShadow02D.Height := FShadow02.Height;
    FCardWidth := FBack.Width;
    FCardHeight := FBack.Height;
  end
  else
    LoadCardBack(1);
end;
{$WARNINGS ON}
procedure TCardDeck.SetDeckName(const ADeckName: TDeckName);
//Property method that sets the deck to the given decktype. Scaling done here.
var
  i: Integer;
  NA: TPoint;
  j: TCardMarker;
  T: Single;

  procedure RB(Source: TBitMap);//Scaling.
  begin
    gImageArray.AssignFromBitmap(Source);
    gImageArray.RotateBitmap(Source, 0, Point(0, 0) , NA, FScale, False);
  end;

  procedure SetSize(const Source, Target: TBitMap);
  begin
    Target.Width := Source.Width;
    Target.Height := Source.Height;
  end;

begin
  if (DirectoryExists(FDeckDirectory + '\' + ADeckName) or
      DirectoryExists(FAltDeckDirectory + '\' + ADeckName)) and
    (ADeckName <> FCardDeckName) then
  begin
    FCardDeckName := ADeckName;
    FNoOfCardBacks := GetNoOfBacks;
//Fix scale for ScaleDeck and tested scales now.
    if FScaleDeck <> 1 then FScale := TestedScale(FScaleDeck);
    LoadDeck;
    if FScale <> 1 then
    begin
//Scale bitmaps & acnt for rotation of individual cards.
      for i := 1 to NoOfCards do
      begin
        RB(FCardArray[i].FFace);
        FCardArray[i].FUnder.Width := FBack.Width;
        FCardArray[i].FUnder.Height := FBack.Height;
        if FCardArray[i].FAngle <> 0 then
        begin
          T := FCardArray[i].FAngle;
          FCardArray[i].FAngle := 0;
          FCardArray[i].SetRotation(T);
        end;
      end;
      RB(FCardMask);
      FCardMaskInv.Width := FCardMask.Width;
      FCardMaskInv.Height := FCardMask.Height;
      BitBlt(FCardMaskInv.Canvas.Handle, 0, 0, FCardMask.Width,FCardMask.Height,
        FCardMask.Canvas.Handle, 0, 0, NOTSRCCOPY);
      RB(FShadow00);
      RB(FShadow01);
      RB(FShadow02);
//New shadow mode bitmaps.
      RB(FShadow00M);
      RB(FShadow00IM);
      RB(FShadow01M);
      RB(FShadow01IM);
      for j := cmOutline to cmDragShade do
        RB(FMarkBitMaps[j]);
      for i := 1 to MaxOutLines+MaxMarks+MaxSuits*4+1 do
      begin
        FCardMarks[i].Under.Width := FBack.Width;
        FCardMarks[i].Under.Height := FBack.Height;
        if FCardMarks[i].Angle <> 0 then
        begin
//Alternate DragShade used with rotations and decks C_1 & C_2.
          if (FCardMarks[i].Mark = FMarkBitmaps[cmDragShade]) and
            Assigned((Owner as TCardTable).DropAngles) and
            ((DeckName = 'C_1') or (DeckName = 'C_2')) then
            gImageArray.AssignFromBitmap(FShadow02)
         else
            gImageArray.AssignFromBitmap(FCardMarks[i].Mark);
          gImageArray.RotateBitmap(FCardMarks[i].MarkR, FCardMarks[i].Angle,
            Point(FCardMarks[i].Mark.Width shr 1,
            FCardMarks[i].Mark.Height shr 1), FCardMarks[i].NA, 1, False);
          FCardMarks[i].NW := FCardMarks[i].MarkR.Width;
          FCardMarks[i].NH := FCardMarks[i].MarkR.Height;
//Store new x,y position of already rotated marks.
          FCardMarks[i].NXY.X := FCardMarks[i].Mark.Width shr 1 +
            FCardMarks[i].Position.X - FCardMarks[i].NA.X;
          FCardMarks[i].NXY.Y := FCardMarks[i].Mark.Height shr 1 +
            FCardMarks[i].Position.Y - FCardMarks[i].NA.Y;
//May have to increase size of bitmap.
          if FCardMarks[i].Under.Width < FCardMarks[i].NW then
            FCardMarks[i].Under.Width := FCardMarks[i].NW;
          if FCardMarks[i].Under.Height < FCardMarks[i].NH then
            FCardMarks[i].Under.Height := FCardMarks[i].NH;
        end;
      end;
      FCardWidth := FBack.Width;
      FCardHeight := FBack.Height;
      FShadow00Under.Width := FShadow00.Width;
      FShadow00Under.Height := FShadow00.Height;
      FShadow01Under.Width := FShadow01.Width;
      FShadow01Under.Height := FShadow01.Height;
//Fix for large scale shadow bug in v3.
      SetSize(FShadow00, FShadow00D);
      SetSize(FShadow01, FShadow01D);
      SetSize(FShadow02, FShadow02D);
    end
    else
//Just account for rotation of individual cards & markers.
      begin
        for i := 1 to NoOfCards do
          if FCardArray[i].FAngle <> 0 then
          begin
            T := FCardArray[i].FAngle;
            FCardArray[i].FAngle := 0;
            FCardArray[i].SetRotation(T);
          end;
        for i := 1 to MaxOutLines+MaxMarks+MaxSuits*4+1 do
        begin
          if FCardMarks[i].Angle <> 0 then
          begin
//Alternate DragShade used with rotations and decks C_1 & C_2.
            if (FCardMarks[i].Mark = FMarkBitmaps[cmDragShade]) and
              Assigned((Owner as TCardTable).DropAngles) and
              ((DeckName = 'C_1') or (DeckName = 'C_2')) then
              gImageArray.AssignFromBitmap(FShadow02)
            else
              gImageArray.AssignFromBitmap(FCardMarks[i].Mark);
            gImageArray.RotateBitmap(FCardMarks[i].MarkR, FCardMarks[i].Angle,
              Point(FCardMarks[i].Mark.Width shr 1,
              FCardMarks[i].Mark.Height shr 1), FCardMarks[i].NA, 1, False);
            FCardMarks[i].NW := FCardMarks[i].MarkR.Width;
            FCardMarks[i].NH := FCardMarks[i].MarkR.Height;
            FCardMarks[i].NXY.X := FCardMarks[i].Mark.Width shr 1 +
              FCardMarks[i].Position.X - FCardMarks[i].NA.X;
            FCardMarks[i].NXY.Y := FCardMarks[i].Mark.Height shr 1 +
              FCardMarks[i].Position.Y - FCardMarks[i].NA.Y;
//May have to increase size of bitmap.
            if FCardMarks[i].Under.Width < FCardMarks[i].NW then
              FCardMarks[i].Under.Width := FCardMarks[i].NW;
            if FCardMarks[i].Under.Height < FCardMarks[i].NH then
              FCardMarks[i].Under.Height := FCardMarks[i].NH;
          end;
        end;
      end;
  end;
end;

procedure TCardDeck.SelectBack;
//Select back via a form.
var
  CardBackForm: TCardBackForm;
begin
//Only allow selection if deck directory exists.
  if (DirectoryExists(FDeckDirectory + '\' + FCardDeckName) or
    DirectoryExists(FAltDeckDirectory + '\' + FCardDeckName)) then
  begin
    CardBackForm := TCardBackForm.Create(Application, FDeckDirectory);
    try
      CardBackForm.DrawBacks(Application, FCardDeckName, FAltDeckDirectory);
      CardBack := CardBackForm.ShowModal;
    finally
      CardBackForm.Release;
    end;
  end;
end;

procedure TCardDeck.SelectDeck;
//Select deck used via a form.
var
  CardDeckForm: TCardDeckForm;
  DeckName, S, S1: string;
  i: Integer;
begin
//Creating a cardtable. We know the location of the cardsets. But there is no
//way to inform cardtable of this & we could be in any directory! But if the
//current dir is set to the dir that contains the cardsets all will be ok.
  S1 := DeckDirectory;
  for i := length(S1) downto 1 do
    if IsPathDelimiter(S1, i) then break;
  SetLength(S1, i-1);   
  SetLength(S, MAX_PATH);
  SetLength(S, GetCurrentDirectory(MAX_PATH, PChar(S)));
  if not SameText(S, S1) then
    SetCurrentDirectory(PChar(S1));
  CardDeckForm := TCardDeckForm.Create(Application, FCardDeckName, False,
    FAltDeckDirectory);
  try
    CardDeckForm.ShowModal;
    DeckName := CardDeckForm.ListBox1.Items[CardDeckForm.ListBox1.itemindex];
  finally
    CardDeckForm.Release;
//Ensure form is painted before setting the deck to fix a messy delay.
    Application.ProcessMessages;
    Self.DeckName := DeckName;
  end;
  if not SameText(S, S1) then//Switch back to original dir.
    SetCurrentDirectory(PChar(S));
end;

procedure TCardDeck.Assign(Source: TPersistent);
//Copying all but FOwner and NoOfCards. Decks must have same number of cards.
var
  i: Integer;
  j: TCardMarker;
begin
  if Source is TCardDeck then
  begin
    for i := 1 to NoOfCards do
      FCardArray[i].Assign((Source as TCardDeck).FCardArray[i]);
    FTop := (Source as TCardDeck).FTop;
    FCardDeckName := (Source as TCardDeck).FCardDeckName;
    FNoOfCardBacks := (Source as TCardDeck).FNoOfCardBacks;
    FCardBack := (Source as TCardDeck).FCardBack;
    SetNewBitMap(FBack, (Source as TCardDeck).FBack);
    SetNewBitMap(FCardMask, (Source as TCardDeck).FCardMask);
    SetNewBitMap(FCardMaskInv, (Source as TCardDeck).FCardMaskInv);
    FCardHeight := (Source as TCardDeck).FCardHeight;
    FCardWidth := (Source as TCardDeck).FCardWidth;
    FDeckDirectory := (Source as TCardDeck).FDeckDirectory;
    FFaceUp := (Source as TCardDeck).FFaceUp;
    SetNewBitMap(FShadow00, (Source as TCardDeck).FShadow00);
    SetNewBitMap(FShadow01, (Source as TCardDeck).FShadow01);
    SetNewBitMap(FShadow02, (Source as TCardDeck).FShadow02);
    SetNewBitMap(FShadow00Under, (Source as TCardDeck).FShadow00Under);
    SetNewBitMap(FShadow01Under, (Source as TCardDeck).FShadow01Under);
    FShadow00Point := (Source as TCardDeck).FShadow00Point;
    FShadow01Point := (Source as TCardDeck).FShadow01Point;
    FScale := (Source as TCardDeck).FScale;
    FScaleDeck := (Source as TCardDeck).FScaleDeck;
    FBaseDeck := (Source as TCardDeck).FBaseDeck;
    for j := cmOutline to cmDragShade do
      SetNewBitMap(FMarkBitmaps[j],
        (Source as TCardDeck).FMarkBitmaps[j]);
    for i := 1 to MaxOutLines+MaxMarks+MaxSuits*4+1 do
    begin
      FCardMarks[i].Under.Width := FBack.Width;
      FCardMarks[i].Under.Height := FBack.Height;
    end;
    SetNewBitMap(FHQDRagShade.ShadedMark,
      (Source as TCardDeck).FHQDragShade.ShadedMark);
    SetNewBitMap(FHQDRagShade.RotatedMark,
      (Source as TCardDeck).FHQDragShade.RotatedMark);
    SetNewBitMap(FHQDRagShade.RotatedMarkInv,
      (Source as TCardDeck).FHQDragShade.RotatedMarkInv);
  end
  else
    inherited Assign(Source);
end;

procedure TCardDeck.SetNewBitmap(var BitMap, NewBitMap: TBitMap);
//Private method that assigns one bitmap to another.
begin
  BitMap.Free;
  BitMap := TBitMap.Create;
  BitMap.Assign(NewBitMap);
end;

procedure TCardDeck.ResetDeck;
//Reseting all card & deck fields to full deck state.
var
  i: Integer;
  ACard: TCard;
begin
  FTop := 0;
  for i := 1 to NoOfCards do
  begin
    ACard := FCardArray[i];
    ACard.FFaceUp := FaceUp;
    if ACard.FStatus <> -2 then
      ACard.FStatus := 0;
    ACard.FDisplayed := False;
  end;
end;

procedure TCardDeck.AddCardsToDeck(var Cards: Array of TCard);
//Cards dealt are removed from the deck & moved to the table. To add to the
//bottom of the deck, some cards from the table, pass them to this method. The
//Deck MUST own the Cards. If the deck is displayed then PlaceDeck MUST be
//called again afterwards to redraw the deck. The cards must NOT be displayed.
var
  i, j, k: Integer;
begin
  for i := 0 to High(Cards) do
  begin
    if not Assigned(Cards[i]) then break;
    if Cards[i].FStatus <> 0 then
    begin
      for j := FTop downto 1 do
        if FCardArray[j] = Cards[i] then break;
      if FCardArray[j] = Cards[i] then
      begin
        for k := j to NoOfCards-1 do
          FCardArray[k] := FCardArray[K+1];
        FCardArray[NoOfCards] := Cards[i];
        Cards[i].FStatus := 0;
        Cards[i].FFaceUp := FaceUp;
        dec(FTop);
      end;
    end;
  end;
end;

procedure TCardDeck.SetFaceUp(const Mode: Boolean);
//Determines if cards in the deck are face up or not. Will have no effect on a
//deck that is already displayed on the table.
var
  i: Integer;
begin
  if FFaceUp <> Mode then
  begin
    FFaceUp := Mode;
    if not (csDesigning in FOwner.ComponentState) then
      for i := 1 to NoOfCards do
        if FCardArray[i].FStatus = 0 then
          FCardArray[i].FFaceUp := FFaceup;
  end;
end;

procedure TCardDeck.SetNoOfCards(const Size: Integer);
//No cards must be on the table. Implicitly sets the number of jokers used. Will
//reset NoOfStripped to 0.
var
  i, Back: Integer;
  DT: String;
begin
//1 to 4 jockers in single, double or larger decks.
  if (Size <> FNoOfCards) and (Size <= MaxCardsInDeck) and (Size >= 52) and
    (Size mod 52 < 5) then
    begin
      for i := 1 to FNoOfCards do//Free old cards.
      begin
        FCardArray[i].Free;
        FCardArray[i] := nil;
      end;
      FNoOfCards := Size;
      Back := FCardBack;//Store the back as we will lose it after loadDeck.
      DT := FCardDeckName;
      FCardDeckName := '';
      SetDeckName(DT);//Calling setdeck instead of loaddeck taking account of scale.
      CardBack := Back;
      if FaceUp then
        for i := 1 to FNoOfCards do
          FCardArray[i].FaceUp := True;
      FNoOfStripped := 0;
    end;
end;

function TCardDeck.NoOfJokers: Integer;
begin
  Result := NoOfCards mod 52;
end;

function  TCardDeck.PeekAtDeck(I: Integer): TCard;
//Surfaces the deck for whatever reason.
//The next card drawn is 1 + NoOfCards - NoOfCardsInDeck. With a stripped deck
//use 1 + NoOfCards - NoOfCardsInDeck(True);
begin
  if I <= NoOfCards then
    result := FCardArray[I]
  else
    result := nil;
end;

procedure TCardDeck.StripDeck(const C: TCardList);
//This is the list of cards that will be stripped from the deck. NoOfCards takes
//NO account of stripped cards. Actual deck size is (NoOfCards - NoOfStripped or
//NoOfCardsInDeck. The deck MUST not be displayed. To reset call NoOfCards with
//deck size or call SetSCards with nil.
var
  i: Integer;
  ACard: TCard;

  function InList: Boolean;
  var
    i: Integer;
  begin
    Result := False;
    for i := 0 to High(C) do
      if (C[i].FSuit = ACard.FSuit) and
        (C[i].FValue = ACard.FValue) then
      begin
        Result := True;
        break;
      end;
  end;

begin
//Find stripped cards.
  FNoOfStripped := 0;
  for i := 1 to NoOfCards do
  begin
    ACard := FCardArray[i];
    if InList then
    begin
      ACard.FStatus := -2;//Stripped.
      inc(FNoOfStripped);
    end
    else
      ACard.FStatus := 0;
  end;
end;

procedure TCardDeck.SetScale(const S: Single);
//Not all values of S result in good scaled bitmaps. Try ScaleDeck property.
var
  DT: string;
  Back: Integer;
begin
  if (S <> FScale) and (S > 0.2) then
  begin
    Back := FCardBack;
    FScale := S;
    FScaleDeck := 1;//Disables scale deck mode.
    DT := FCardDeckName;
    FCardDeckName := '';
    SetDeckName(DT);
    if Back <> 1 then CardBack := Back;
  end;
end;

procedure TCardDeck.SetScaleDeck(const SetScale: Integer);
//Indirectly sets scale to specific values with fixed scaled results.
//-2 approx  60%
//-1 approx  80%
// 1   is   100%
// 2 approx 125%
// 3   is   150%
// 4   is   175%
// 5   is   200%
begin
  if (FScaleDeck <> SetScale) and (SetScale > -3) and (SetScale < 6) then
  begin
    Scale := TestedScale(SetScale);
    FScaleDeck := SetScale;
  end;
end;

function TCardDeck.TestedScale(const SetScale: Integer): Single;
begin
  Result := 1;
  if FCardDeckName = 'Standard' then
    case SetScale of
      -2: Result := 0.599;
      -1: Result := 0.797;
       1: Result := 1.0;
       2: Result := 1.25;
       3: Result := 1.5;
       4: Result := 1.75;
       5: Result := 2.0;
    end
  else
  if (FCardDeckName = 'Gdkcard-bonded') or (FCardDeckName = 'Xpat2-nox-large')
    then
    case SetScale of
      -2: Result := 0.6139999;
      -1: Result := 0.7929;
       1: Result := 1.0;
       2: Result := 1.25;
       3: Result := 1.5;
       4: Result := 1.75;
       5: Result := 2.0;
    end
  else
  if FCardDeckName = 'Hard-a-port' then
    case SetScale of
      -2: Result := 0.65499;
      -1: Result := 0.83889;
       1: Result := 1.0;
       2: Result := 1.25;
       3: Result := 1.5;
       4: Result := 1.75;
       5: Result := 2.0;
    end
  else
  if FCardDeckName = 'Xskat-french-large' then
    case SetScale of
      -2: Result := 0.63999;
      -1: Result := 0.81789;
       1: Result := 1.0;
       2: Result := 1.251;
       3: Result := 1.5;
       4: Result := 1.75;
       5: Result := 2.0;
    end
  else
  if FCardDeckName = 'C_1_X2' then
    case SetScale of
      -2: Result := 0.59;
      -1: Result := 0.7608;
       1: Result := 1.0;
       2: Result := 1.25;
       3: Result := 1.5;
       4: Result := 1.75;
       5: Result := 2.0;
    end
  else
  if FCardDeckName = 'Bresciane' then
  begin
    var LScale := 1;
    case SetScale of
      -2: Result := 0.63999 * LScale;
      -1: Result := 0.81789 * LScale;
       1: Result := 1.0 * LScale;
       2: Result := 1.251 * LScale;
       3: Result := 1.5 * LScale;
       4: Result := 1.75 * LScale;
       5: Result := 2.0 * LScale;
    end
  end
  else
  if FCardDeckName = 'Napoletane' then
  begin
    var LScale := 1;
    case SetScale of
      -2: Result := 0.63999 * LScale;
      -1: Result := 0.81789 * LScale;
       1: Result := 1.0 * LScale;
       2: Result := 1.251 * LScale;
       3: Result := 1.5 * LScale;
       4: Result := 1.75 * LScale;
       5: Result := 2.0 * LScale;
    end
  end
  else
//If FCardDeckName = 'C_1' or 'C_2' or 'U_'.
    case SetScale of
      -2: Result := 0.59;
      -1: Result := 0.7608;
       1: Result := 1.0;
       2: Result := 1.25;
       3: Result := 1.5;
       4: Result := 1.75;
       5: Result := 2.0;
     end;
end;

procedure TCardDeck.RotateBack(const Angle: Single);
//Private method rotates back bitmap into FBackR.
var
  t: TPoint;
begin
  if Angle <> 0 then
  begin
    gImageArray.AssignFromBitmap(FBack);
    gImageArray.RotateBitmap(FBackR, Angle, Point(CardWidth shr 1,
      CardHeight shr 1), t, 1, False);
  end;
end;

function TCardDeck.GetCardMark(I: Integer): PCardMark;
//Retutrns a pointer else result cannot be modified.
begin
  Result := @FCardMarks[I];
end;

procedure TCardDeck.SetAltDeckDirectory(const s: string);
//Used to provide an additional alternative location for cardsets. Used when
//cardsets are stored in protected location and user changes to the sets are
//needed. TCardDeck will look for individual cards and entire new sets here.
//NOTE that setting Alt directory to '' could mean that the current deck used is
//no longer valid, ie it resides in Alt dir.
begin
  if s <> FAltDeckDirectory then
    FAltDeckDirectory := s;
end;



//............................................................................//
//........................ T C A R D T A B L E ...............................//
//............................................................................//



procedure TCardTable.WMEraseBkgnd(var Msg: TMessage);
begin
  Msg.Result := 1;
end;

constructor TCardTable.Create(AOwner: TComponent);
//Displaying & moving cards.
var
  i: Integer;
begin
  inherited Create(AOwner);
  Parent := AOwner as TWinControl;
  FCardDeck := TCardDeck.Create(self);//1 deck is created & freed by the table.
  FSprite := TSprite.Create(Self);//As is 1 sprite.
  FBitMap := TBitMap.Create;
  FJpeg := TJpegImage.Create;
  FBackDrop := TBackDrop.Create;
  ControlStyle := [csOpaque, csCaptureMouse, csClickEvents, csSetCaption];
  FDirectory := ExtractFilePath(ParamStr(0));
  SetLength(FDirectory, Length(FDirectory)-1);
  FSaveTable := False;
  FCopyToScreen := False;
  FColor := clInactiveCaption;
  FCardSpeed := 16;
  Height := 400;
  Width := 500;
  FJpegPerformance := jpBestQuality;
  FJpeg.Performance := jpBestQuality;
  FStretchBackground := False;//Tiles by default.
//New table areas. Must be instantiated before Background set.
  for i := 1 to MaxAreas do
    FTableAreas[i] := TTableArea.Create(self);
  BackgroundPicture := 'None';
  FNoOfCardsOnTable := 0;
  FNoOfDiscards := 0;
  FPlaceDeckOffset := 666;//7 gives a reasonable 3d look, high value none.
  FDragAndDrop := False;
  FDragFromDeck := False;
  FCardDragging := False;
  FDragFaceDown := False;
  FLiftOffset := False;
  FShadePlaced := False;
  FCopyToScreen := True;
  FRefreshLabels := False;
  FAutoShadeMode := 1;//2 methods for drawing shades.
  SendToBack;
  (AOwner as TForm).OnCanResize := FormIsResizing;
  AutoResize := False;
  MinWidth := 500;
  MinHeight := 400;
  TurnOverAnimationSpeed := 8;//Set to 0 for no animations.
  TurnOverAnimationVertical := True;
  TurnOverAnimationLift := False;
  FBackDrop.RefreshEvent := BackDropRefresh;
  FSlowMoveRegion := False;
  FSMR_WaitMode := True;//But no effect untl SlowMoveRegion is set to true.
  FTurnAnimations := True;//All turn over properties have effect.
  FShadowMode := smDarken;
  FDragCardCursor := crDrag;
  FastMovementMode := False;//Default use new slower movement mode.
  FSoftShadow := True;
  FHQDragShade := True;//Default use hq shaded drag shade.
  FHQDragShadeColour := 1;
  Color := clGreen; //Default Color
end;

destructor TCardTable.Destroy;
//Call free not this method.
var
  i: Integer;
begin
  FBitMap.Free;
  FJpeg.Free;
  FCardDeck.Free;
  FBackDrop.Free;
  FSprite.Free;
  for i := 1 to MaxAreas do
    FTableAreas[i].Free;
  inherited Destroy;
end;

procedure TCardTable.SetDrawnCard(const ACard: TCard);
//Needs to be called if Deck is displayed on the table and you draw a card.
//Because although the card is on the table it is not in the CardsOnTable array.
//Nb. Once drawn & set card MUST be moved away from deck before drawing others.
begin
  if ACard.FDisplayed then
  begin
    inc(FNoOfCardsOnTable);
    FCardsOnTable[FNoOfCardsOnTable] := ACard;
  end;
end;

function TCardTable.DrawCardFromDeck(Deck: TCardDeck = nil): TCard;
//Shortcut function - use instead of CardDeck.Draw & SetDrawnCard which you need
//to do otherwise if deck is displayed on screen. Nb. Once drawn & set card MUST
//be moved away from deck before drawing others.
var
  ACard: TCard;
begin
  if not Assigned(Deck) then Deck := FCardDeck;
  ACard := Deck.Draw;
  if ACard <> nil then
    SetDrawnCard(ACard);
  Result := ACard;
end;

function TCardTable.DrawCardNFromDeck(const N, X, Y: integer;
  Deck: TCardDeck = nil): TCard;
//Use to draw specific no card from deck. Top is 1, bottom is NoOfCardsInDeck.
//This must be used and NOT DrawX if deck is displayed. X and Y origin points of
//deck are needed as used with original PlaceDeck.
var
  ACard: TCard;
  i, j, Offset: Integer;
begin
  if not Assigned(Deck) then Deck := FCardDeck;
  for i := Deck.NoOfCards+1 - (Deck.NoOfCards - Deck.FTop) to Deck.NoOfCards do
    if Deck.FCardArray[i].FDisplayed then
    begin
      PickUp(Deck.FCardArray[i], Deck);
      Deck.FCardArray[i].FDisplayed := False;
    end;
  ACard := Deck.DrawN(N);
  Offset := 0;
  j := 0;
  for i := Deck.NoOfCards downto Deck.NoOfCards+1 - (Deck.NoOfCards - Deck.FTop)
  do
    if Deck.FCardArray[i].FStatus <> -2 then
    begin
      PutDown(Deck.FCardArray[i], X+Offset, Y+Offset, Deck, True);
      inc(j);
      Deck.FCardArray[i].FDisplayed := True;
      if (j mod FPlaceDeckOffset = 0) then dec(Offset);
    end;
  CopyImage(X+Offset, Y+Offset, Deck.FCardWidth-Offset,
    Deck.FCardHeight-Offset);
  if ACard <> nil then
  begin
    PlaceCard(ACard, ACard.X, ACard.Y);
    Result := ACard;
  end
  else
    Result := nil;
end;

procedure TCardTable.PlaceDeck(const X, Y: Integer; Deck: TCardDeck = nil);
//Places the deck on table. Shuffling MUST be done prior to this. Cards may be
//drawn before placing the deck. Does not add cards to CardsOnTable array.
//Setting PlaceDeckOffset to for example 7 will give a 3d look to the displayed
//deck & must obviously be done prior to calling this function. To draw a card
//from a placed deck either do CardDeck.Draw & CardTable.SetDrawnCard(ACard) or
//call CardTable.DrawCardFromDeck. CardDeck.FaceUp property determines if cards
//in the deck are displayed face up or not.
//
//NB.Calling this method again with the SAME parameters allows you to redraw the
//deck after card/s have been returned to deck with CardDeck.Return or
//CardDeck.AddCardsToDeck.
var
  i,j, Offset: Integer;
  CB: Boolean;
begin
  If not Assigned(Deck) then Deck := FCardDeck;
  CB := True;
  for i := Deck.NoOfCards+1 - (Deck.NoOfCards - Deck.FTop) to Deck.NoOfCards do
    if Deck.FCardArray[i].FDisplayed then
    begin
      PickUp(Deck.FCardArray[i], Deck);
      Deck.FCardArray[i].FDisplayed := False;
      CB := False;
    end;
  Offset := 0;
  j := 0;
  for i := Deck.NoOfCards downto Deck.NoOfCards+1 - (Deck.NoOfCards - Deck.FTop)
  do
    if Deck.FCardArray[i].FStatus <> -2 then
    begin
      PutDown(Deck.FCardArray[i], X+Offset, Y+Offset, Deck, True);
      inc(j);
      Deck.FCardArray[i].FDisplayed := True;
      if CB then
        CopyImage(X+Offset, Y+Offset, Deck.FCardWidth, Deck.FCardHeight);
      if (j mod FPlaceDeckOffset = 0) then dec(Offset);
    end;
  if not CB then
    CopyImage(X+Offset, Y+Offset, Deck.FCardWidth-Offset,
      Deck.FCardHeight-Offset);
  CardDeck.BaseDeck := Point(X, Y);
end;

procedure TCardTable.CopyImage(const X, Y, Width, Height: Integer);
//Protected method that copies section of FBitMap to Canvas (of owner form if
//visible) X, Y is origin position of invalidated area on FBitMap.
begin
  if Visible and FCopyToScreen then
    BitBlt(Canvas.Handle, X, Y, Width, Height,
      FBitMap.Canvas.Handle, X, Y, SRCCOPY);
end;

procedure TCardTable.PutDown(const ACard: TCard; const X, Y: Integer;
  const Deck: TCardDeck; const SaveBack: Boolean = True;
  const Angle: Single = 0);
//Protected method that puts down a card to the buffer.
begin
  if ACard.FDisplayed and SaveBack then exit;//Already on the table.
  ACard.Fx := X;
  ACard.Fy := Y;
  //First rotate card face.
  if ACard.FAngle <> Angle then ACard.SetRotation(Angle);
  if ACard.FAngle <> 0 then
  begin
  //Store actual x,y of rotated card.
    ACard.FNXY.X := ACard.FFace.Width shr 1 + X - ACard.FNA.X;
    ACard.FNXY.Y := ACard.FFace.Height shr 1 + Y - ACard.FNA.Y;
  end;
  //Now store what will be under the card.
  if SaveBack then
    if ACard.FAngle = 0 then
      BitBlt(ACard.FUnder.Canvas.Handle, 0,0, Deck.FCardWidth, Deck.FCardHeight,
        FBitMap.Canvas.Handle, X, Y, SRCCOPY)
     else
      begin
  //If FUnder is not big enough resize it. As face is rotated we get size from
  //that even if rotating the back later.
        if ACard.FUnder.Width < ACard.FNW then
          ACard.FUnder.Width := ACard.FNW;
        if ACard.FUnder.Height < ACard.FNH then
          ACard.FUnder.Height := ACard.FNH;
        BitBlt(ACard.FUnder.Canvas.Handle, 0, 0, ACard.FNW, ACard.FNH,
          FBitMap.Canvas.Handle, ACard.FNXY.X, ACard.FNXY.Y, SRCCOPY);
      end;
  if ACard.FFaceUp then
  begin
    if ACard.FAngle = 0 then
    begin
      BitBlt(FBitMap.Canvas.Handle, X, Y, Deck.FCardWidth, Deck.FCardHeight,
        Deck.FCardMask.Canvas.Handle, 0, 0, SrcAnd);
      BitBlt(FBitMap.Canvas.Handle, X, Y, Deck.FCardWidth, Deck.FCardHeight,
        ACard.FFace.Canvas.Handle, 0, 0, SrcPaint);
    end
    else
      FBitMap.Canvas.Draw(ACard.FNXY.X, ACard.FNXY.Y, ACard.FFaceR);
  end
  else//Face down.
    if ACard.FAngle = 0 then
    begin
      BitBlt(FBitMap.Canvas.Handle, X, Y, Deck.FCardWidth, Deck.FCardHeight,
        Deck.FCardMask.Canvas.Handle, 0, 0, SrcAnd);
      BitBlt(FBitMap.Canvas.Handle, X, Y, Deck.FCardWidth, Deck.FCardHeight,
        Deck.FBack.Canvas.Handle, 0, 0, SrcPaint);
    end
    else
      begin
  //Note we allways recalculate back rotations so best not to use to many.
        Deck.RotateBack(Angle);
  //As card face has been rotated we can use its x,y values.
        FBitMap.Canvas.Draw(ACard.FNXY.X, ACard.FNXY.Y, Deck.FBackR);
      end;
end;

procedure TCardTable.StretchPutDown(const ACard: TCard; const Deck: TCardDeck;
  const AnimateValue: Integer);
//Protected method used only in animating the turning over of a card.
//AnimateValue must be in range 1..CardHeight or CardWidth depending on FTOAV.
var
  InvertFlag: Boolean;
  Offset: Integer;
begin
  If (FTOAV and (AnimateValue < Deck.CardHeight/2)) or
     (not FTOAV and (AnimateValue < Deck.CardWidth/2)) then
    InvertFlag := True
  else
    InvertFlag := False;
  if InvertFlag then
    Offset := AnimateValue - 1
  else
    if FTOAV then
      Offset := Deck.CardHeight - AnimateValue
    else
      Offset := Deck.CardWidth - AnimateValue;
  if ((not InvertFlag) and ACard.FaceUp) or
    (InvertFlag and (ACard.FaceUp = False)) then
  begin
    if FTOAV then
    begin
      StretchBlt(FBitMap.Canvas.Handle, ACard.Fx, ACard.Fy + Offset,
        Deck.FCardWidth, Deck.FCardHeight - Offset shl 1,
        Deck.FCardMask.Canvas.Handle, 0, 0, Deck.FCardWidth, Deck.FCardHeight,
        SrcAnd);
      StretchBlt(FBitMap.Canvas.Handle, ACard.Fx, ACard.Fy + Offset,
        Deck.FCardWidth, Deck.FCardHeight - Offset shl 1,
        ACard.FFace.Canvas.Handle, 0, 0, Deck.FCardWidth, Deck.FCardHeight,
        SrcPaint);
    end
    else
      begin
        StretchBlt(FBitMap.Canvas.Handle, ACard.Fx + Offset, ACard.Fy,
          Deck.FCardWidth - Offset shl 1, Deck.FCardHeight,
          Deck.FCardMask.Canvas.Handle, 0, 0, Deck.FCardWidth, Deck.FCardHeight,
          SrcAnd);
        StretchBlt(FBitMap.Canvas.Handle, ACard.Fx + Offset, ACard.Fy,
          Deck.FCardWidth - Offset shl 1, Deck.FCardHeight,
          ACard.FFace.Canvas.Handle, 0, 0, Deck.FCardWidth, Deck.FCardHeight,
          SrcPaint);
      end;
  end
  else
    if FTOAV then
    begin
      StretchBlt(FBitMap.Canvas.Handle, ACard.Fx, ACard.Fy + Offset,
        Deck.FCardWidth, Deck.FCardHeight - Offset shl 1,
        Deck.FCardMask.Canvas.Handle, 0, 0, Deck.FCardWidth, Deck.FCardHeight,
        SrcAnd);
      StretchBlt(FBitMap.Canvas.Handle, ACard.Fx, ACard.Fy + Offset,
        Deck.FCardWidth, Deck.FCardHeight - Offset shl 1,
        Deck.FBack.Canvas.Handle, 0, 0, Deck.FCardWidth, Deck.FCardHeight,
        SrcPaint);
    end
    else
      begin
        StretchBlt(FBitMap.Canvas.Handle, ACard.Fx + Offset, ACard.Fy,
          Deck.FCardWidth - Offset shl 1, Deck.FCardHeight,
          Deck.FCardMask.Canvas.Handle, 0, 0, Deck.FCardWidth, Deck.FCardHeight,
          SrcAnd);
        StretchBlt(FBitMap.Canvas.Handle, ACard.Fx + Offset, ACard.Fy,
          Deck.FCardWidth - Offset shl 1, Deck.FCardHeight,
          Deck.FBack.Canvas.Handle, 0, 0, Deck.FCardWidth, Deck.FCardHeight,
          SrcPaint);
      end;
end;

procedure TCardTable.PlaceCard(const ACard: TCard; const X, Y: Integer;
  const Angle: Single = 0);
//Places card on the table.
var
  Deck: TCardDeck;
begin
  if not ACard.FDisplayed then
  begin
    Deck := ACard.FOwner;
    if Angle = 0 then
    begin
      PutDown(ACard, X, Y, Deck);
      CopyImage(X, Y, Deck.FCardWidth, Deck.FCardHeight);
    end
    else
      begin
        PutDown(ACard, X,Y, Deck, True, Angle);
        CopyImage(ACard.FNXY.X, ACard.FNXY.Y, ACard.FFaceR.Width,
          ACard.FFaceR.Height);
      end;
    ACard.FDisplayed := true;
    inc(FNoOfCardsOnTable);
    FCardsOnTable[FNoOfCardsOnTable] := ACard;
  end;
end;

procedure TCardTable.PickUp(const ACard: TCard; const Deck: TCardDeck);
//Protected method that picks up a card from the buffer.
begin
  if ACard.FAngle = 0 then
    BitBlt(FBitMap.Canvas.Handle, ACard.Fx, ACard.Fy, Deck.FCardWidth,
      Deck.FCardHeight, ACard.FUnder.Canvas.Handle, 0, 0, SRCCOPY)
  else
    BitBlt(FBitMap.Canvas.Handle,ACard.FNXY.X, ACard.FNXY.Y, ACard.FNW,
      ACard.FNH, ACard.FUnder.Canvas.Handle, 0, 0, SRCCOPY);
end;

procedure TCardTable.PickUpCard(const ACard: TCard; const TopCard: Boolean =
  False);
//Picks up card from the table.
var
  ArrayPos, i: Integer;
  Deck: TCardDeck;
  Rect: TRect;
  Covering: TCardList;
begin
  Deck := ACard.FOwner;
  if ACard.FDisplayed then
  begin
    PickUpCoveringCards2(ACard, Deck, Rect, Covering, ArrayPos, True, TopCard);
    PickUp(ACard, Deck);
    ACard.FDisplayed := False;
    if Length(Covering) <> 0 then
      ReplaceCoveringCards(Covering);
//Delete entry in CardsOnTableArray.
    if ArrayPos <> FNoOfCardsOnTable then
      for i := ArrayPos to FNoOfCardsOnTable-1 do
        FCardsOnTable[i] := FCardsOnTable[i+1];
    dec(FNoOfCardsOnTable);
    if ACard.FAngle = 0 then
      CopyImage(Acard.Fx, ACard.Fy, Deck.FCardWidth, Deck.FCardHeight)
    else
      CopyImage(Acard.FNXY.X, ACard.FNXY.Y, ACard.FNW, ACard.FNH);
  end;
end;

procedure TCardTable.PickUpCoveringCards2(const ACard: TCard;
  const Deck: TCardDeck; var Rect: TRect; var Covering: TCardList;
  var Result: Integer; const BeginingMove: Boolean = True;
  const TopCard: Boolean = False);
//Version 2. Simplified and optimised then modified for rotation and assuming
//all rotated and covering cards are from 1 deck.
//Var parameter Result is an index into FCardsOnTable array.
//If BeginingMove Covering Rect & Result initialised Else Covering and Rect
//modified as required. TopCard is NEW param & is set true if CERTAIN card is a
//top card & not covered by any others.
var
  i, MaxWidth, MaxHeight: Integer;
  Deck2: TCardDeck;
  NewList: TCardList;
begin
  if ACard.FAngle = 0 then
  begin
    Rect.Left := ACard.X;
    Rect.Right := Rect.Left + Deck.CardWidth;
    Rect.Top := ACard.Y;
    Rect.Bottom := Rect.Top + Deck.CardHeight;
  end
  else
    begin
      Rect.Left := ACard.FNXY.X;
      Rect.Right := Rect.Left + ACard.FNW;
      Rect.Top := ACard.FNXY.Y;
      Rect.Bottom := Rect.Top + ACard.FNH;
    end;
  if BeginingMove then
  begin
    Covering := nil;
//    for i := 1 to FNoOfCardsOnTable do//Probably slightly better is:
    for i := FNoOfCardsOnTable downto 1 do
      if FCardsOnTable[i] = ACard then break;
    Result := i;//FCardsOnTable[i] is being lifted.
    if not TopCard then//If card is a TopCard dont need to check for covering.
      for i := Result + 1 to FNoOfCardsOnTable do
//Does card i cover Rect, if it does add card i area to rect.
        if FCardsOnTable[i].FAngle = 0 then
        begin
          Deck2 := FCardsOnTable[i].FOwner;
          MaxWidth := Max(Rect.Right-Rect.Left, Deck2.FCardWidth);
          MaxHeight := Max(Rect.Bottom-Rect.Top, Deck2.FCardHeight);
//This card might be covering Rect
          if (abs(Rect.Left - FCardsOnTable[i].Fx) < MaxWidth) and
            (abs(Rect.Top - FCardsOnTable[i].Fy) < MaxHeight) then
          begin
//Add card to array of covering cards.
            SetLength(Covering, Length(Covering)+1);
            Covering[High(Covering)] := FCardsOnTable[i];
//Add card area to Rect.
            if FCardsOnTable[i].Fx < Rect.Left then
              Rect.Left := FCardsOnTable[i].Fx
            else
              if FCardsOnTable[i].X + Deck2.CardWidth > Rect.Right then
                Rect.Right := FCardsOnTable[i].X + Deck2.CardWidth;
            if FCardsOnTable[i].Fy < Rect.Top then
              Rect.Top := FCardsOnTable[i].Fy
            else
              if FCardsOnTable[i].Y + Deck2.CardHeight > Rect.Bottom then
                Rect.Bottom := FCardsOnTable[i].Y + Deck2.CardHeight;
          end;
        end
        else
//Else card is rotated.
          begin
            MaxWidth := Max(Rect.Right-Rect.Left, FCardsOnTable[i].FNW);
            MaxHeight := Max(Rect.Bottom-Rect.Top, FCardsOnTable[i].FNH);
//This card might be covering Rect
            if (abs(Rect.Left - FCardsOnTable[i].FNXY.X ) < MaxWidth) and
              (abs(Rect.Top - FCardsOnTable[i].FNXY.Y) < MaxHeight) then
            begin
//Add card to array of covering cards.
              SetLength(Covering, Length(Covering)+1);
              Covering[High(Covering)] := FCardsOnTable[i];
//Add card area to Rect.
              if FCardsOnTable[i].FNXY.X < Rect.Left then
                Rect.Left := FCardsOnTable[i].FNXY.X
              else
                if FCardsOnTable[i].FNXY.X + FCardsOnTable[i].FNW >
                  Rect.Right then
                  Rect.Right := FCardsOnTable[i].FNXY.X + FCardsOnTable[i].FNW;
              if FCardsOnTable[i].FNXY.Y < Rect.Top then
                Rect.Top := FCardsOnTable[i].FNXY.Y
              else
                if FCardsOnTable[i].FNXY.Y + FCardsOnTable[i].FNH >
                  Rect.Bottom then
                  Rect.Bottom := FCardsOnTable[i].FNXY.Y + FCardsOnTable[i].FNH;
            end;
          end;
  end
  else
    begin
//NOT begining move. In a move loop with Rect & Covering already initialised.
      for i := 0 to High(Covering) do
        if Covering[i].FAngle = 0 then
        begin
//Does card i cover Rect, if it does add card i area to rect.
          Deck2 := Covering[i].FOwner;
          MaxWidth := Max(Rect.Right-Rect.Left, Deck2.FCardWidth);
          MaxHeight := Max(Rect.Bottom-Rect.Top, Deck2.FCardHeight);
//This card might be covering Rect
          if (abs(Rect.Left - Covering[i].Fx) < MaxWidth) and
            (abs(Rect.Top - Covering[i].Fy) < MaxHeight) then
          begin
//Add card to new list of covering cards.
            SetLength(NewList, Length(NewList)+1);
            NewList[High(NewList)] := Covering[i];
//Add card area to Rect.
            if Covering[i].Fx < Rect.Left then
              Rect.Left := Covering[i].Fx
            else
              if Covering[i].X + Deck2.CardWidth > Rect.Right then
                Rect.Right := Covering[i].X + Deck2.CardWidth;
            if Covering[i].Fy < Rect.Top then
              Rect.Top := Covering[i].Fy
            else
              if Covering[i].Y + Deck2.CardHeight > Rect.Bottom then
                Rect.Bottom := Covering[i].Y + Deck2.CardHeight;
          end
        end
        else
//Else card is rotated.
          begin
//Does card i cover Rect, if it does add card i area to rect.
            MaxWidth := Max(Rect.Right-Rect.Left, Covering[i].FNW);
            MaxHeight := Max(Rect.Bottom-Rect.Top, Covering[i].FNH);
//This card might be covering Rect
            if (abs(Rect.Left - Covering[i].FNXY.X) < MaxWidth) and
              (abs(Rect.Top - Covering[i].FNXY.Y) < MaxHeight) then
            begin
//Add card to new list of covering cards.
              SetLength(NewList, Length(NewList)+1);
              NewList[High(NewList)] := Covering[i];
//Add card area to Rect.
              if Covering[i].FNXY.X < Rect.Left then
                Rect.Left := Covering[i].FNXY.X
              else
                if Covering[i].FNXY.X + Covering[i].FNW > Rect.Right
                  then Rect.Right := Covering[i].FNXY.X + Covering[i].FNW;
              if Covering[i].FNXY.Y < Rect.Top then
                Rect.Top := Covering[i].FNXY.Y
              else
                if Covering[i].FNXY.Y + Covering[i].FNH > Rect.Bottom
                  then Rect.Bottom := Covering[i].FNXY.Y + Covering[i].FNH;
            end
          end;
//Assign NewList to Covering.
      Covering := nil;
      Covering := NewList;
    end;
//Pick up in reverse order.
  for i := High(Covering) downto 0 do
  begin
    Deck2 := Covering[i].Owner;
    PickUp(Covering[i], Deck2);
    Covering[i].FDisplayed := False;
  end;
end;

procedure TCardTable.ReplaceCoveringCards(var Covering: TCardList);
//Version 2.
//Protected method that replaces lifted cards.
var
  i: Integer;
begin
  for i := 0 to High(Covering) do
  begin
    PutDown(Covering[i], Covering[i].Fx, Covering[i].Fy, Covering[i].FOwner,
      True, Covering[i].FAngle);
    Covering[i].FDisplayed := True;
  end;
end;

procedure TCardTable.MoveTo(const ACard: TCard; const X, Y: Integer);
//Version 2 modified for rotation.
var
  Width,Height,x1, x2, y1, y2, ArrayPos, i, Speed, Diff, DiffX, DiffY: Integer;
  BeginingMove, CardHasShadow, CoveringAffirmed: Boolean;
  Deck: TCardDeck;
  Rect: TRect;
  Covering: TCardList;
begin
  Deck := ACard.FOwner;
  BeginingMove := True;
  CardHasShadow := False;
  ArrayPos := 0;
  if ACard.FDisplayed then
  begin
    repeat
      if BeginingMove and (ACard.FAngle <> 0) then
      begin
        x1 := ACard.FNXY.X;
        y1 := ACard.FNXY.Y;
        Width := ACard.FNW;
        Height := ACard.FNH;
      end
      else
        begin
          x1 := ACard.Fx;
          y1 := ACard.Fy;
          Width := Deck.FCardWidth;
          Height := Deck.FCardHeight;
        end;
//First pick up covering cards.
      if BeginingMove or (Length(Covering) <> 0) then
      begin
        PickUpCoveringCards2(ACard, Deck, Rect, Covering, ArrayPos,
          BeginingMove);
        BeginingMove := False;
      end;
//Now pick up card.
      PickUp(ACard, Deck);
      if CardHasShadow then PickUpShadow(Deck);
      ACard.FDisplayed := False;
//Adjust speed for covering cards & slow move region.
      if Length(Covering) = 0 then
        if SlowMoveRegion then
        begin
          DiffX := abs(ACard.Fx - X);
          DiffY := abs(ACard.Fy - Y);
          if (DiffX <= Deck.CardWidth shr 1) and
            (DiffY <= Deck.CardHeight shr 1) then
          begin
            Speed := 1;
//New property effect. SMR_SleepMode slows final pixel movement.
            if FSMR_WaitMode and ((DiffX <= Deck.CardWidth shr 3) and
              (DiffY <= Deck.CardHeight shr 3))
            then
              Wait(2);
          end
          else
          begin
            Diff := Max(DiffX - Deck.CardWidth shr 1,
              DiffY - Deck.CardHeight shr 1);
            if FCardSpeed > Diff then
              Speed := Diff
            else
              Speed := FCardSpeed;
          end;
        end
        else
          Speed := FCardSpeed
      else
        Speed := FCardSpeed + Length(Covering);
      if ACard.Fx > X then
      begin
        dec(ACard.Fx, Speed);
        if ACard.Fx < X then ACard.Fx := X;
      end
      else
        if ACard.Fx < X then
        begin
          inc(ACard.Fx, Speed);
          if ACard.Fx > X then ACard.Fx := X;
        end;
      if ACard.Fy > Y then
      begin
        dec(ACard.Fy, Speed);
        if ACard.Fy < Y then ACard.Fy := Y;
      end
      else
        if ACard.Fy < Y then
        begin
          inc(ACard.Fy, Speed);
          if ACard.Fy > Y then ACard.Fy := Y;
        end;
//Put it down at new position.
      if Length(Covering) = 0 then
      begin
        PutDownShadow(ACard.Fx, ACard.Fy, Deck);
        CardHasShadow := True;
      end;
      PutDown(ACard, ACard.Fx, ACard.Fy, Deck);
//Replace the covering cards.
      if Length(Covering) > 0 then
        ReplaceCoveringCards(Covering);
//Find invalidated region.
      if x1 < ACard.Fx then
        x2 := ACard.Fx
      else
      begin
        x2 := x1;
        x1 := ACard.Fx;
      end;
      if y1 < ACard.Fy then
        y2 := ACard.Fy
      else
      begin
        y2 := y1;
        y1 := ACard.Fy;
      end;
      Width := Width + x2-x1;
      Height := Height + y2-y1;
      if CardHasShadow then
      begin
        Width := Width + Deck.FShadow01.Width;
        Height := Height + Deck.FShadow01.Width;
      end;
//Finally copying the buffer to the screen. Paint is used for slow movement.
      if FastMovementMode then
        CopyImage(x1, y1, Width, Height)
      else
      begin
        Paint;
        Sleep(5);
      end;
    until (Acard.Fx = X) and (ACard.Fy = Y);
    Acard.FDisplayed := true;
    if Length(Covering) <> 0 then
    begin
//Card has moved & has been flagged as under others. But is it really?
//Because check for covering is done BEFORE card has moved and because speed may
//be very high it may move out from under cards to target position in only one
//move. Thus we need to recheck again here to avoid any errors.
      CoveringAffirmed := False;
      for i := 0 to High(Covering) do
      begin
//Just check each card in covering list.
        if Covering[i].FAngle = 0 then
        begin
          if (abs(Covering[i].X - ACard.X) < Deck.CardWidth) and
            (abs(Covering[i].Y - ACard.Y) < Deck.CardHeight) then
          begin
//Yep its covering!
            CoveringAffirmed := True;
            break;
          end;
        end
        else
          if (abs(Covering[i].FNXY.X - ACard.X) < Covering[i].FNW) and
          (abs(Covering[i].FNXY.Y - ACard.Y) < Covering[i].FNH) then
          begin
//Yep its covering!
            CoveringAffirmed := True;
            break;
          end;
      end;
      if not CoveringAffirmed then Covering := nil;
    end;
    if Length(Covering) = 0 then
    begin
//Card has moved and is not under any others so move its position in array. Note
//has not been modified for rotation so bewary.
      if ArrayPos <> FNoOfCardsOnTable then
      begin
        for i := ArrayPos to FNoOfCardsOnTable-1 do
          FCardsOnTable[i] := FCardsOnTable[i+1];
        FCardsOnTable[FNoOfCardsOnTable] := ACard;
      end;
      if CardHasShadow then
      begin
        PickUp(ACard, Deck);
        PickUpShadow(Deck);
        ACard.FDisplayed := False;
        PutDown(ACard, ACard.Fx, ACard.Fy, Deck);
        ACard.FDisplayed := True;
        CopyImage(x1, y1, Width, Height);
      end;
    end;
  end;
end;

procedure TCardTable.TurnOverCard(const ACard: TCard; const TopCard: Boolean =
  False);
//Turn over card on the table. No animations take effect if card is rotated.
var
  ArrayPos, i: Integer;
  Deck: TCardDeck;
  Rect: TRect;
  Covering: TCardList;
begin
//FTOAL is TurnOverAnimationLift property.
//FTurnAnimations can be used to disable all turn over animations.
  if FTOAL and FTurnAnimations and (ACard.FAngle = 0) then
    if LiftTurnOverCard(ACard) then exit;
  Deck := ACard.FOwner;
  ACard.FFaceUp := not ACard.FFaceUp;
  if ACard.FDisplayed then
    if (FTOAS > 0) and FTurnAnimations and (ACard.FAngle = 0) then
    begin
      i := 0;
      repeat
        PickUpCoveringCards2(ACard, Deck, Rect, Covering, ArrayPos, True,
          TopCard);
        PickUp(ACard, Deck);
        ACard.FDisplayed := False;
        inc(i, FTOAS);
        if FTOAV then
        begin
          if i > Deck.CardHeight then i := Deck.CardHeight
        end
          else
            if i > Deck.CardWidth then i := Deck.CardWidth;
        StretchPutDown(ACard, Deck, i);
        ACard.FDisplayed := True;
        if Length(Covering) <> 0 then
          ReplaceCoveringCards(Covering);
        CopyImage(Acard.Fx, ACard.Fy, Deck.FCardWidth, Deck.FCardHeight);
        Wait(1);
      until (FTOAV and (i = Deck.CardHeight)) or
            (not FTOAV and (i = Deck.CardWidth));
    end
    else
      begin
        PickUpCoveringCards2(ACard, Deck, Rect, Covering, ArrayPos, True,
          TopCard);
        PutDown(ACard, ACard.Fx, ACard.Fy, Deck, False, ACard.FAngle);
        if Length(Covering) <> 0 then
          ReplaceCoveringCards(Covering);
        if ACard.FAngle = 0 then
          CopyImage(Acard.Fx, ACard.Fy, Deck.FCardWidth, Deck.FCardHeight)
        else
          CopyImage(ACard.FNXY.X, ACard.FNXY.Y, ACard.FFaceR.Width,
            ACard.FFaceR.Height);
      end;
end;

function TCardTable.LiftTurnOverCard(const ACard: TCard): boolean;
//Turn over a card on the table with pseudo animated shadow -
//TurnOverAnimationLift property is true. Called by TurnOverCard. This just
//approximates a 3d shadow turnover effect.
var
  ArrayPos, i, X1, Y1, q: Integer;//q is 1 quarter card size.
  MaxShadowSize, StartShadowPosition, StartFTOAS: Integer;
  Deck: TCardDeck;
  ShadowUnder: TBitMap;
  Rect: TRect;
  Covering: TCardList;

procedure DrawCardWithShadow;
begin
  ShadowUnder.Width := Deck.FShadow02.Width;
  ShadowUnder.Height := Deck.FShadow02.Height;
  Deck.FShadow02D.Width := ShadowUnder.Width;
  Deck.FShadow02D.Height := ShadowUnder.Height;
  X1 := ACard.X + Deck.FShadow01.Width;
  Y1 := ACard.Y + Deck.FShadow01.Width;
  PickUp(ACard, Deck);//First picking up the card we are lifting.
  if FShadowMode = smOriginal then
  begin
    BitBlt(ShadowUnder.Canvas.Handle, 0, 0, ShadowUnder.Width,
      ShadowUnder.Height, FBitMap.Canvas.Handle, X1, Y1, SRCCOPY);
    BitBlt(FBitMap.Canvas.Handle, X1, Y1, Deck.CardWidth, Deck.CardHeight,
      Deck.FShadow02.Canvas.Handle, 0, 0, SRCAND);
  end else
    begin
      BitBlt(ShadowUnder.Canvas.Handle, 0, 0, ShadowUnder.Width,
        ShadowUnder.Height, FBitMap.Canvas.Handle, X1, Y1, SRCCOPY);
      BitBlt(Deck.FShadow02D.Canvas.Handle, 0, 0, ShadowUnder.Width,
        ShadowUnder.Height, FBitMap.Canvas.Handle, X1, Y1, SRCCOPY);
      Darken(@Deck.FShadow02D, FSoftShadow, True);
      BitBlt(FBitMap.Canvas.Handle, X1, Y1, Deck.CardWidth, Deck.CardHeight,
        Deck.FShadow02D.Canvas.Handle, 0, 0, SRCCOPY);
    end;
  PutDown(ACard, ACard.Fx, ACard.Fy, Deck, False);
  CopyImage(Acard.Fx, ACard.Fy, Deck.FCardWidth + Deck.FShadow01.Width,
    Deck.FCardHeight + Deck.FShadow00.Height);
  Wait(200);
end;

begin
  Result := True;
  Deck := ACard.FOwner;
  PickUpCoveringCards2(ACard, Deck, Rect, Covering, ArrayPos);
//First ensure that you cant LiftTurn a card if it is covered by others.
//We return false and a standard turnover is performed instead.
  if Length(Covering) <> 0 then
  begin
    ReplaceCoveringCards(Covering);
    Result := False;
    exit;
  end;
  if ACard.FDisplayed then
  begin
    if FLiftOffset then
    begin
      PickUpCoveringCards2(ACard, Deck, Rect, Covering, ArrayPos);
      PickUp(ACard, Deck);
      ACard.FDisplayed := False;
      if ArrayPos <> FNoOfCardsOnTable then
        for i := ArrayPos to FNoOfCardsOnTable-1 do
          FCardsOnTable[i] := FCardsOnTable[i+1];
      dec(FNoOfCardsOnTable);
      PutDown(ACard, ACard.Fx-deck.FShadow01.Width,
        ACard.Fy-deck.FShadow01.Width, Deck);
      ACard.FDisplayed := true;
      inc(FNoOfCardsOnTable);
      FCardsOnTable[FNoOfCardsOnTable] := ACard;
    end;
    ShadowUnder := TBitMap.Create;
    try
      if FTOAS > 0 then//Pseudo animated turnover.
      begin
      //Now a high value of FTOAS causes the waste products to collide with the
      //air conditioning system so...
        StartFTOAS := FTOAS;
        if FTOAS > 32 then FTOAS := 32;
        DrawCardWithShadow;
      //Turnover.
        ACard.FFaceUp := not ACard.FFaceUp;
      //These variables vary according to flipping direction.
        if FTOAV then
        begin
          q := Deck.CardHeight shr 2;
          MaxShadowSize := Round(Deck.CardHeight * 1.4);
          StartShadowPosition := Y1;
        end
        else
          begin
            q := Deck.CardWidth shr 2;
            MaxShadowSize := Deck.CardWidth;
            StartShadowPosition := X1;
          end;
        i := 0;
        repeat
      //Pick up card & shadow.
          PickUp(ACard, Deck);
          BitBlt(FBitMap.Canvas.Handle, X1, Y1, ShadowUnder.Width,
            ShadowUnder.Height, ShadowUnder.Canvas.Handle, 0, 0, SRCCOPY);
          ACard.FDisplayed := False;
          inc(i, FTOAS);
      //Change shadow.
          if FTOAV then
      //Pseudo vertical flip.
          begin
            if i > Deck.CardHeight then i := Deck.CardHeight;
            if i < q then//Less then 45 degrees
            begin
              Y1 := Y1 + FTOAS;
              ShadowUnder.Height := ShadowUnder.Height - FTOAS shl 2;
            end
            else if i < q shl 1 then//<90
              begin
                Y1 := Y1 + FTOAS;
                ShadowUnder.Height := ShadowUnder.Height + FTOAS shl 2;
                if ShadowUnder.Height > MaxShadowSize then
                  ShadowUnder.Height := MaxShadowSize;
              end
              else if i < q * 3 then//<135
              begin
                Y1 := Y1 - FTOAS;
                if Y1 < StartShadowPosition then
                  Y1 := StartShadowPosition;
                ShadowUnder.Height := ShadowUnder.Height + FTOAS shl 1;
                if ShadowUnder.Height > MaxShadowSize then
                  ShadowUnder.Height := MaxShadowSize;
              end
              else//<=180
                begin
                  Y1 := Y1 - FTOAS;
                  if Y1 < StartShadowPosition then
                    Y1 := StartShadowPosition;
                  ShadowUnder.Height := ShadowUnder.Height - FTOAS shl 1;
                  if ShadowUnder.Height < Deck.CardHeight then
                    ShadowUnder.Height := Deck.CardHeight;
                end;
          end
          else
      //Pseudo horizontal flip.
            begin
              if i > Deck.CardWidth then i := Deck.CardWidth;
              if i < q then//Less then 45 degrees
              begin
                X1 := X1 + FTOAS;
                ShadowUnder.Width := ShadowUnder.Width - FTOAS shl 2;
              end
              else if i < q shl 1 then//<90
                begin
                  X1 := X1 + FTOAS;
                  ShadowUnder.Width := ShadowUnder.Width + FTOAS shl 2;
                  if ShadowUnder.Width > MaxShadowSize then
                    ShadowUnder.Width := MaxShadowSize;
                end
                else if i < q * 3 then//<135
                begin
                  X1 := X1 - FTOAS;
                  if X1 < StartShadowPosition then
                    X1 := StartShadowPosition;
                  ShadowUnder.Width := ShadowUnder.Width + FTOAS shl 1;
                  if ShadowUnder.Width > MaxShadowSize then
                    ShadowUnder.Width := MaxShadowSize;
                end
                else//<=180
                  begin
                    X1 := X1 - FTOAS;
                    if X1 < StartShadowPosition then
                      X1 := StartShadowPosition;
                    ShadowUnder.Width := ShadowUnder.Width - FTOAS shl 1;
                    if ShadowUnder.Width < Deck.CardWidth then
                      ShadowUnder.Width := Deck.CardWidth;
                  end;
            end;
          BitBlt(ShadowUnder.Canvas.Handle, 0, 0, ShadowUnder.Width,
            ShadowUnder.Height, FBitMap.Canvas.Handle, X1, Y1, SRCCOPY);
          if FShadowMode = smOriginal then
          begin
            StretchBlt(FBitMap.Canvas.Handle, X1, Y1, ShadowUnder.Width,
              ShadowUnder.Height, Deck.FShadow02.Canvas.Handle, 0, 0,
              Deck.FShadow02.Width, Deck.FShadow02.Height, SRCAND);
            StretchPutDown(ACard, Deck, i);
          end else
            begin
              Deck.FShadow02D.Width := ShadowUnder.Width;
              Deck.FShadow02D.Height := ShadowUnder.Height;
              BitBlt(Deck.FShadow02D.Canvas.Handle, 0, 0, ShadowUnder.Width,
                ShadowUnder.Height, FBitMap.Canvas.Handle, X1, Y1, SRCCOPY);
              Darken(@Deck.FShadow02D, FSoftShadow, True);
              BitBlt(FBitMap.Canvas.Handle, X1, Y1, ShadowUnder.Width,
                ShadowUnder.Height,Deck.FShadow02D.Canvas.Handle,0, 0, SRCCOPY);
              StretchPutDown(ACard, Deck, i);
            end;
          ACard.FDisplayed := True;
          if FTOAV then
            CopyImage(Acard.Fx, ACard.Fy, Deck.CardWidth+Deck.FShadow01.Width,
              MaxShadowSize + 50)
          else
            CopyImage(Acard.Fx, ACard.Fy, Deck.CardWidth + MaxShadowSize,
              Deck.CardHeight + Deck.FShadow00.Height);
          Wait(1);
        until (FTOAV and (i = Deck.CardHeight)) or
          (not FTOAV and (i = Deck.CardWidth));
        Wait(200);
      //Remove shadow.
        BitBlt(FBitMap.Canvas.Handle, X1, Y1, ShadowUnder.Width,
          ShadowUnder.Height, ShadowUnder.Canvas.Handle, 0, 0, SRCCOPY);
        PutDown(ACard, ACard.Fx, ACard.Fy, Deck, False);
        CopyImage(Acard.Fx, ACard.Fy, Deck.FCardWidth + Deck.FShadow01.Width,
          Deck.FCardHeight + Deck.FShadow00.Height);
        Wait(100);
        FTOAS := StartFTOAS;//Reset.
      end
      else//Just flip card no pseudo animation.
        begin
          DrawCardWithShadow;
     //Turnover.
          ACard.FFaceUp := not ACard.FFaceUp;
          PutDown(ACard, ACard.Fx, ACard.Fy, Deck, False);
          CopyImage(Acard.Fx, ACard.Fy, Deck.FCardWidth, Deck.FCardHeight);
          Wait(200);
     //Remove shadow.
          BitBlt(FBitMap.Canvas.Handle, X1, Y1, ShadowUnder.Width,
            ShadowUnder.Height, ShadowUnder.Canvas.Handle, 0, 0, SRCCOPY);
          PutDown(ACard, ACard.Fx, ACard.Fy, Deck, False);
          CopyImage(Acard.Fx, ACard.Fy, Deck.FCardWidth + Deck.FShadow01.Width,
            Deck.FCardHeight + Deck.FShadow00.Height);
          Wait(100);
        end;
    finally
      ShadowUnder.Free;
    end;
    if FLiftOffset then
    begin
      PickUpCoveringCards2(ACard, Deck, Rect, Covering, ArrayPos);
      PickUp(ACard, Deck);
      ACard.FDisplayed := False;
      if ArrayPos <> FNoOfCardsOnTable then
        for i := ArrayPos to FNoOfCardsOnTable-1 do
          FCardsOnTable[i] := FCardsOnTable[i+1];
      dec(FNoOfCardsOnTable);
      PutDown(ACard, ACard.Fx+deck.FShadow01.Width,
        ACard.Fy+deck.FShadow01.Width, Deck);
      ACard.FDisplayed := true;
      inc(FNoOfCardsOnTable);
      FCardsOnTable[FNoOfCardsOnTable] := ACard;
      CopyImage(Acard.Fx-Deck.FShadow01.Width, ACard.Fy-Deck.FShadow01.Width,
        Deck.FCardWidth + Deck.FShadow01.Width,
        Deck.FCardHeight + Deck.FShadow01.Width);
    end;
  end;
end;

procedure TCardTable.Discard(const ACard: TCard);
//Send card to a visible discard pile.
var
  Offset, i, j: Integer;
begin
  ACard.FStatus := -1;
  inc(FNoOfDiscards);
  FDiscardArray[FNoOfDiscards] := ACard;
  Offset := FNoOfDisCards div FPlaceDeckOffset;
  if ACard.FDisplayed then
  begin
    MoveTo(ACard, FDiscardsAt.X - Offset, FDiscardsAt.Y - Offset);
    //Remove entry from CardsOnTable array.
    if FCardsOnTable[FNoOfCardsOnTable] <> ACard then
    begin
      j := 0;
      repeat
        inc(j);
      until FCardsOnTable[j] = ACard;
      for i := j to FNoOfCardsOnTable-1 do
        FCardsOnTable[i] := FCardsOnTable[i+1];
    end;
    dec(FNoOfCardsOnTable);
  end else
  begin
    PutDown(ACard, FDiscardsAt.X - Offset, FDiscardsAt.Y - Offset,
      ACard.FOwner);
    ACard.Displayed := True;
  end;
  RefreshLabels;
end;

procedure TCardTable.PickUpDeck(Deck: TCardDeck = nil);
//Picks up deck from the table.
var
  i: integer;
begin
  if not Assigned(Deck) then Deck := FCardDeck;
  for i := Deck.FTop+1 to FCardDeck.NoOfCards do
    if Deck.FCardArray[i].FDisplayed then
    begin
      PickUp(Deck.FCardArray[i], Deck);
      Deck.FCardArray[i].FDisplayed := False;
    end;
  if FCopyToScreen then
  begin
    Invalidate;
    RefreshLabels;
  end;
end;

procedure TCardTable.PickUpDiscards;
//Picks up the discard pile not changing cards FStatus.
var
  i: Integer;
begin
  if FNoOfDiscards > 0 then
  begin
    for i := FNoOfDiscards downto 1 do
      if FDiscardArray[i].FDisplayed then
      begin
        PickUp(FDiscardArray[i], FDiscardArray[i].FOwner);
        FDiscardArray[i].FDisplayed := False;
      end;
    FNoOfDiscards := 0;
  end;
  if FCopyToScreen then
  begin
    Invalidate;
    RefreshLabels;
  end;
end;

procedure TCardTable.PickUpCardsOnTable;
//Note this method ONLY picks up the cards in the CardsOnTable array & not any
//displayed decks. It also does not change the cards status. To pick up all the
//cards on the table and reset the deck call PickUpAllCardsAndReset. You also
//must not forget to shuffle the deck before using again.
var
  i: Integer;
begin
  for i := FNoOfCardsOnTable downto 1 do
  begin
    PickUp(FCardsOnTable[i], FCardsOnTable[i].FOwner);
    FCardsOnTable[i].FDisplayed := False;
  end;
  FNoOfCardsOnTable := 0;
  if FCopyToScreen then
  begin
    Paint;
    RefreshLabels;
  end;
end;

procedure TCardTable.PickUpAllCardsAndReset(Deck: TCardDeck = nil);
//Picks up all cards on the table resetting all but card order. Fixed by a
//shuffle.
var
  Temp: Boolean;
begin
  if not Assigned(Deck) then Deck := FCardDeck;
  Temp := FCopyToScreen;
  FCopyToScreen := False;
  PickUpCardsOnTable;
  PickUpDiscards;
  PickUpDeck(Deck);
  Deck.ResetDeck;
  FCopyToScreen := Temp;
  Invalidate;
  RefreshLabels;
end;

procedure TCardTable.SetSpeed(const Speed: Integer);
//Property method that sets FCardSpeed.
begin
  if Speed >0 then FCardSpeed := Speed;
end;

function TCardTable.MouseButtonPressed(const X, Y: Integer): TCard;
//Protected method. Is there a card under these co-ordinates? Returns either a
//TCard or nil. If the card is in the deck ie ACard.Status = 0 then the deck has
//been chosen otherwise the card is on the table. If the source is the deck then
//a card will need to be drawn from the deck unless DragAndDrop and DragFromDeck
//are enabled when the card is automatically drawn. ExternalDeck property can be
//set to another deck allowing this deck also to be selected.
var
  i, j, X1, Y1: Integer;
  ACard: TCard;
  Deck: TCardDeck;
begin
  Result := nil;
  //First check the cards on the table.
  for i := FNoOfCardsOnTable downto 1 do
  begin
    ACard := FCardsOnTable[i];
    Deck := ACard.FOwner;
    X1 := ACard.Fx;
    Y1 := ACard.Fy;
    if ((X >= X1) and (X <= X1 + Deck.FCardWidth))
      and ((Y >= Y1) and (Y <= Y1 + Deck.FCardHeight)) then
      begin
        Result := ACard;
        break;
      end;
  end;
  //Now cards in the deck.
  if Result = nil then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      for i := Deck.NoOfCards downto 1 do
      begin
        ACard := Deck.FCardArray[i];
        if ACard.FDisplayed and (ACard.FStatus = 0) then
        begin
          X1 := ACard.Fx;
          Y1 := ACard.Fy;
          if ((X >= X1) and (X <= X1 + Deck.FCardWidth))
            and ((Y >= Y1) and (Y <= Y1 + Deck.FCardHeight)) then
            begin
              Result := ACard;
              break;
            end;
        end;
      end;
    end;
end;

procedure TCardTable.Paint;
//Called automatically by windows and by TCardTable to draw the table.
begin
//Copying the buffer to the form. Some methods set FCopyToScreen to false to
//stop intermediate redraws - also property CopyToScreen can be set by client.
  if FCopyToScreen then
    CopyImage(0,0,FBitMap.Width,FBitMap.Height);
end;

procedure TCardTable.DrawTableAreas(const NotType: Integer = -1);
//Draws all table areas other than ExceptType if specified.
var
  i: Integer;
begin
  for i := 1 to MaxAreas do
    if FTableAreas[i].Enabled and (FTableAreas[i].FAreaType <> NotType) then
      FTableAreas[i].Draw;
  if FCopyToScreen then
  begin
    Invalidate;
    RefreshLabels;
  end;
end;

procedure TCardTable.DrawTableArea(const AType: Integer);
var
  i: Integer;
begin
  for i := 1 to MaxAreas do
    if (FTableAreas[i].FAreaType = AType) and FTableAreas[i].Enabled then
      FTableAreas[i].Draw;
  if FCopyToScreen then
  begin
    Invalidate;
    RefreshLabels;
  end;
end;

procedure TCardTable.UnDrawTableAreas(const NotType: Integer = -1);
//Undraws all table areas apart from NotType.
var
  i: Integer;
begin
  for i := 1 to MaxAreas do
    if FTableAreas[i].Enabled and (FTableAreas[i].FAreaType <> NotType) then
      FTableAreas[i].UnDraw;
  if FCopyToScreen then
  begin
    Invalidate;
    RefreshLabels;
  end;
end;

procedure TCardTable.RedrawBuffer;
//Protected method that refreshes the buffer to be redrawn with the deck & cards
//in the correct position after the table has been resized, the card deck/back
//changed or after the tabletop picture has been changed.
var
  Temp: Boolean;
  i, j: Integer;
  Deck: TCardDeck;
begin
//Even if FCopyToScreen is true we dont need to copy individual changes made to
//the buffer to the screen.
  Temp := FCopyToScreen;
  FCopyToScreen := False;
  if not (csDesigning in ComponentState) then
  begin
//New first - draw table areas, apart from message type 9.
    DrawTableAreas(9);
//First draw any CardMarkers if used.
    PlaceCardMarkers;
//Redraw the internal deck & external deck in FExternalDeck if assigned.
    for i := 1 to 2 do
    begin
      if i = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      for j := Deck.NoOfCards downto Deck.FTop + 1 do
        if Deck.FCardArray[j].FDisplayed then
        begin
          Deck.FCardArray[j].FDisplayed := False;
          PutDown(Deck.FCardArray[j], Deck.FCardArray[j].Fx,
            Deck.FCardArray[j].Fy, Deck, True);
          Deck.FCardArray[j].FDisplayed := True;
        end;
    end;
//Redraw the discard pile if used.
    if FNoOfDiscards > 0 then
      for i := 1 to FNoOfDiscards do
        if FDiscardArray[i].FDisplayed then
        begin
          FDiscardArray[i].FDisplayed := False;//Else PutDown wont work.
          PutDown(FDiscardArray[i], FDiscardArray[i].Fx, FDiscardArray[i].Fy,
            FDiscardArray[i].FOwner, True);
          FDiscardArray[i].FDisplayed := true;
        end;
    FCopyToScreen := Temp;
    for I := 1 to FNoOfCardsOnTable do//Draw cards.
    begin
      Deck := FCardsOnTable[i].FOwner;
      FCardsOnTable[i].FDisplayed := False;
      PutDown(FCardsOnTable[i], FCardsOnTable[i].Fx, FCardsOnTable[i].Fy, Deck,
        True, FCardsOnTable[i].FAngle);
      FCardsOnTable[i].FDisplayed := True;
    end;
    DrawTableArea(9);
//Finally redraw the sprite.
    if FSprite.FDisplayed then
    begin
      FSprite.FDisplayed := False;//Stop undraw.
      FSprite.Draw;
    end;
  end;
  FCopyToScreen := Temp;
end;

procedure TCardTable.SetDragCards(const P: TCardList);
//Sets user defined list of cards that can be dragged.
begin
  FDragCards := P;
end;

procedure TCardTable.SetDropPoints(const P: TDropPoints);
//Sets user defined list of points that can be dropped onto.
begin
  FDropPoints := P;
end;

procedure TCardTable.SetDropAngles(const P: TDropAngles);
begin
  FDropAngles := P;
end;

procedure TCardTable.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
//Protected method that if FDragAndDrop is True and the left buton pressed the
//card is Lifted off the table. If card is within the deck and DragFromDeck is
//True then a card is drawn. If FOnCardClickEvent has been assigned then a
//TCardClickEvent is generated.
function MouseWithinArea(X, Y: integer; A: TTableArea): boolean;
//Just used to see if mouse within a table area.
begin
  if ((X >= A.FX) and (X <= A.FX + A.FWidth)) and
    ((Y >= A.FY) and (Y <= A.FY + A.FHeight)) then
    Result := True
  else
    Result := False;
end;

var
  ACard: TCard;
  i: Integer;
  Deck: TCardDeck;
  InList: Boolean;
  Rect: TRect;
  Covering: TCardList;
begin
  inherited;
  ACard := MouseButtonPressed(X,Y);
  if ACard <> nil then
  begin
    if ((ACard.FStatus = 1) and (ACard.FFaceUp or FDragFaceDown)) or
      ((ACard.FStatus = 0) and FDragFromDeck) then
      if FDragAndDrop and (Button = mbLeft) then
      begin
        Deck := ACard.FOwner;
        if ACard.FStatus = 0 then
        begin//Dragging a card from the deck.
          ACard := Deck.Draw;
          SetDrawnCard(ACard);
          FCOTPosition := 0;
          PickUp(ACard, Deck);
          ACard.FDisplayed := False;
          dec(FNoOfCardsOnTable);
          FCardDraggedFromDeck := True;
          FDraggedAngle := 0;
          Rect.Left := ACard.Fx;
          Rect.Right := Rect.Left + Deck.CardWidth;
          Rect.Top := ACard.Fy;
          Rect.Bottom := ACard.Fy + Deck.CardHeight;
        end
        else
          begin
//New code for v1.7.
            InList := False;
//If there is a user defined list of cards then we will drag it only if ACard is
//within the list.
            if Assigned(FDragCards) then
            begin
              for i := Low(FDragCards) to High(FDragCards) do
                if FDragCards[i] = ACard then
                begin
                  InList := True;
                  break;
                end;
              if not InList then exit;
            end;
//End of new code.
//Dragging a card on the table. Nb no longer in CardsOnTable array.
            PickUpCoveringCards2(ACard, Deck, Rect, Covering, FCOTPosition);
            PickUp(ACard, Deck);
            ACard.FDisplayed := False;
            if Length(Covering) <> 0 then
              ReplaceCoveringCards(Covering);
            if FCOTPosition <> FNoOfCardsOnTable then
              for i := FCOTPosition to FNoOfCardsOnTable-1 do
                FCardsOnTable[i] := FCardsOnTable[i+1];
            dec(FNoOfCardsOnTable);
            FCardDraggedFromDeck := False;
          end;
        FCardDragging := True;//Setting various fields used for drag & drop.
        FDraggingCard := ACard;
        FDraggedAngle := ACard.FAngle;//Used to restore a rotated card.
        FDragOrigin.X := ACard.Fx;
        FDragOrigin.Y := ACard.Fy;
        if ACard.FAngle <> 0 then
        begin
//Take account of alterations for rotated cards.
          if Rect.Top > ACard.Fy then Rect.Top := ACard.Fy;
          if Rect.Bottom < ACard.Fy + Deck.CardHeight +Deck.FShadow01.Width then
            Rect.Bottom := ACard.Fy + Deck.CardHeight + Deck.FShadow01.Width;
        end;
        if FLiftOffset then
        begin
          ACard.Fx := ACard.Fx - Deck.FShadow01.Width;
          ACard.Fy := ACard.Fy - Deck.FShadow01.Width;
          Rect.Left := Rect.Left - Deck.FShadow01.Width;
          Rect.Top := Rect.Top - Deck.FShadow01.Width;
        end
        else
//Alterations if no lift offset.
          begin
            if Rect.Right < ACard.X + Deck.CardWidth + Deck.FShadow01.Width then
              Rect.Right := ACard.X + Deck.CardWidth + Deck.FShadow01.Width;
            if Rect.Bottom < ACard.Y +Deck.CardHeight +Deck.FShadow01.Width then
              Rect.Bottom := ACard.Y + Deck.CardHeight + Deck.FShadow01.Width;
          end;
        FMouseRelX := X - ACard.Fx;
        FMouseRelY := Y - ACard.Fy;
        FPreDragCursor := Screen.Cursor;
//Resetting fields used by auto shade system in v1.7.
        FStackTop := -1;
        FShadeSetByPoint := -1;
        PutDownShadow(ACard.Fx, ACard.Fy, Deck);
        PutDown(ACard, ACard.Fx, ACard.Fy, Deck);
        ACard.FDisplayed := True;
        CopyImage(Rect.Left, Rect.Top, Rect.Right - Rect.Left,
          Rect.Bottom - Rect.Top);
        RefreshLabels;
        Screen.Cursor := DragCardCursor;
      end;
//Inform user by generating TCardClick event. Seperate event for external deck.
      if ACard.FOwner = FCardDeck then
      begin
        if Assigned(FOnCardClickEvent) then FOnCardClickEvent(ACard, Button);
      end
      else
        if Assigned(FOnExternalCardClickEvent) then
          FOnExternalCardClickEvent(ACard, Button);
  end
  else
//Check if mouse is within a table area.
    for i := 1 to MaxAreas do
      if FTableAreas[i].FEnabled then
        if MouseWithinArea(X, Y, FTableAreas[i]) then
          if Assigned(FTableAreas[i].FOnAreaClickEvent) then
            FTableAreas[i].FOnAreaClickEvent(X, Y, Button);
end;

procedure TCardTable.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
//Protected method that when the left mouse button is released and CardDragging
//is true then a TCardDropEvent is raised and the user MUST then either call
//DropCard, DropCardOnShade or RestoreCard. New in v1.7 Index integer parameter
//added to OnCardDropEvent.
var
  Index: Integer;
begin
//Index signifies in OnCardDropEvent that card was not over a shade when using
//auto shades and DropPoints property.
  Index := -1;
  if FCardDragging and (Button = mbLeft) then
  begin
    FCardDragging := False;
    Screen.Cursor := FPreDragCursor;
//V1.7.
    if FShadePlaced and Assigned(FDropPoints) then
    begin
      PickUpMarker(cmDragShade);
      Index := FStack[FStackTop];//Point card was dropped on in auto shades.
    end;
//End.
//New & needed for HQDradShade - reset.
    CardDeck.FHQDragShade.InstanceFlag := False;
    if Assigned(self.FExternalDeck) then
      FExternalDeck.FHQDragShade.InstanceFlag := False;

    if Assigned(FOnCardDropEvent) then
      FOnCardDropEvent(FDraggingCard, X, Y, FMouseRelX, FMouseRelY, Index);
  end;
end;

procedure TCardTable.MouseMove(Shift: TShiftState; X, Y: Integer);
//Protected method that if a card is being dragged by the mouse handles the
//movement of the card.
var
  Area: TRect;

  function SearchStack(const Target: Integer): boolean;
  var
    i: Integer;
  begin
    Result := False;
    for i := FStackTop downto 0 do
      if FStack[i] = Target then
      begin
        Result := True;
        Break;
      end;
  end;

  procedure UpdateArea(const Left, Top, Width, Height: Integer);
  begin
    if Area.Left > Left then Area.Left := Left;
    If Area.Top > Top then Area.Top := Top;
    if Area.Right < Left + Width then Area.Right := Left + Width;
    if Area.Bottom < Top + Height then Area.Bottom := Top + Height;
  end;

var
  ACard: TCard;
  i, j, k, X1, Y1, X2, Y2, Width, Height: Integer;
  Deck: TCardDeck;
  Bounds: TRect;
begin
  inherited;
  if FCardDragging then
  begin
    Area := Rect(9999,9999,-1,-1);//Holds invalidated area.
    ACard := FDraggingCard;
    Deck := ACard.FOwner;
    X1 := ACard.Fx;
    Y1 := ACard.Fy;
    PickUp(ACard, Deck);
    PickUpShadow(Deck);
    ACard.FDisplayed := False;
    ACard.Fx := X - FMouseRelX;
    ACard.Fy := Y - FMouseRelY;
    if ACard.Fx < 0 then ACard.Fx := 0;
    if ACard.Fy < 0 then ACard.Fy := 0;
    if ACard.Fx > Self.Width - Deck.FCardWidth then
      ACard.Fx := Self.Width - Deck.FCardWidth;
    if ACard.Fy > Self.Height - Deck.FCardHeight then
      ACard.Fy := Self.Height - Deck.FCardHeight;
//New code for 1.7 auto shade here. There are 2 different methods for switching
//shade positions depending upon value of AutoShadeMode property. The first one
//uses the dragging cards bounds as a trigger for drawing a shade and the second
//one uses the mouse position.
//If DropPoints property has been assigned then we will draw a shade if the card
//is passing over a drop point.
    if Assigned(FDropPoints) then
      if FAutoShadeMode = 1 then
      begin
        for i := low(FDropPoints) to High(FDropPoints) do
        begin
//We won't draw shade on drop point if the dragged card is from the drop point.
          if (FDropPoints[i].X = FDragOrigin.X) and
            (FDropPoints[i].Y = FDragOrigin.Y) then Continue;
//Bounds specify the target area.
          Bounds.Left := FDropPoints[i].X;
          Bounds.Top := FDropPoints[i].Y;
          Bounds.Right := Bounds.Left + Deck.CardWidth;
          Bounds.Bottom:= Bounds.Top + Deck.CardHeight;
//Is the card within these bounds.
          if DragCardWithinBounds(Bounds) then
          begin
//If point is not within the stack add it. Actually its not really a stack.
            if not SearchStack(i) then
            begin
              inc(FStackTop);
              FStack[FStackTop] := i;
            end;
          end else
//If the point is within the stack then remove it.
            if SearchStack(i) then
              for j := FStackTop downto 0 do
                if FStack[j] = i then
                  if j = FStackTop then
                  begin
                    dec(FStackTop);
                    break;
                  end
                  else begin
                    for k := j to FStackTop-1 do
                      FStack[k] := FStack[k+1];
                    dec(FStackTop);
                    break;
                  end;
        end;
//Is there is a mark on the table that needs picking up.
        if (FShadePlaced and (FStackTop = -1)) or (FShadePlaced and
          (FStack[FStackTop] <> FShadeSetByPoint)) then
        begin
          FDraggingCard := nil;//Temporarily unassigned.
          PickUpMarker(cmDragShade, 1, Deck, False);//Not copying to screen.
//Update invalidated area.
          if Deck.FCardMarks[CardMarkIndex(cmDragShade)].Angle = 0 then
            UpdateArea(Deck.FCardMarks[CardMarkIndex(cmDragShade)].Position.X,
              Deck.FCardMarks[CardMarkIndex(cmDragShade)].Position.Y,
              Deck.CardWidth, Deck.CardHeight)
          else
            UpdateArea(Deck.FCardMarks[CardMarkIndex(cmDragShade)].NXY.X,
              Deck.FCardMarks[CardMarkIndex(cmDragShade)].NXY.Y,
              Deck.FCardMarks[CardMarkIndex(cmDragShade)].NW,
              Deck.FCardMarks[CardMarkIndex(cmDragShade)].NH);
          FDraggingCard := ACard;
          FShadePlaced := False;
          FShadeSetByPoint := -1;
        end;
        if (FStackTop <> -1) and (FStack[FStackTop] <> FShadeSetByPoint) then
        begin
          Bounds.Left := FDropPoints[FStack[FStackTop]].X;
          Bounds.Top := FDropPoints[FStack[FStackTop]].Y;
          FCardDragging := False;//Temporarily set to false.
          if not Assigned(FDropAngles) then
            PlaceCardMarker(cmDragShade, Bounds.Left, Bounds.Top, 1, Deck, 0,
              False)
          else
            PlaceCardMarker(cmDragShade, Bounds.Left, Bounds.Top, 1, Deck,
              FDropAngles[FStack[FStackTop]], False);
//Update invalidated area.
          if Deck.FCardMarks[CardMarkIndex(cmDragShade)].Angle = 0 then
            UpdateArea(Deck.FCardMarks[CardMarkIndex(cmDragShade)].Position.X,
              Deck.FCardMarks[CardMarkIndex(cmDragShade)].Position.Y,
              Deck.CardWidth, Deck.CardHeight)
          else
            UpdateArea(Deck.FCardMarks[CardMarkIndex(cmDragShade)].NXY.X,
              Deck.FCardMarks[CardMarkIndex(cmDragShade)].NXY.Y,
              Deck.FCardMarks[CardMarkIndex(cmDragShade)].NW,
              Deck.FCardMarks[CardMarkIndex(cmDragShade)].NH);
          FCardDragging := True;
          FShadePlaced := True;
          FShadeSetByPoint := FStack[FStackTop];
        end;
      end
    else
//FAutoShadeMode is 2. Alternate system for drawing shades uses the mouse
//position and is sometimes better for when the cards are close together.
      for i := low(FDropPoints) to High(FDropPoints) do
      begin
//We won't draw shade on drop point if the dragged card is from the drop point.
        if (FDropPoints[i].X = FDragOrigin.X) and
          (FDropPoints[i].Y = FDragOrigin.Y) then continue;
//Bounds specify the target area.
        Bounds.Left := FDropPoints[i].X;
        Bounds.Top := FDropPoints[i].Y;
        Bounds.Right := Bounds.Left + Deck.CardWidth;
        Bounds.Bottom:= Bounds.Top + Deck.CardHeight;
//Is the mouse within these bounds.
        if (X >= Bounds.left) and (X <= Bounds.Right) and (Y >= Bounds.Top) and
          (Y <= Bounds.Bottom) then
        begin
//If there is NOT a mark already on the table place one.
          if not FShadePlaced then
          begin
            FCardDragging := False;//Temporarily set to false.
            if not Assigned(FDropAngles) then
              PlaceCardMarker(cmDragShade, Bounds.Left, Bounds.Top, 1, Deck, 0,
                False)
            else
              PlaceCardMarker(cmDragShade, Bounds.Left, Bounds.Top, 1, Deck,
                FDropAngles[i], False);
//Update invalidated area.
            if Deck.FCardMarks[CardMarkIndex(cmDragShade)].Angle = 0 then
              UpdateArea(Deck.FCardMarks[CardMarkIndex(cmDragShade)].Position.X,
                Deck.FCardMarks[CardMarkIndex(cmDragShade)].Position.Y,
                Deck.CardWidth, Deck.CardHeight)
            else
              UpdateArea(Deck.FCardMarks[CardMarkIndex(cmDragShade)].NXY.X,
                Deck.FCardMarks[CardMarkIndex(cmDragShade)].NXY.Y,
                Deck.FCardMarks[CardMarkIndex(cmDragShade)].NW,
                Deck.FCardMarks[CardMarkIndex(cmDragShade)].NH);
            FCardDragging := True;
            FShadePlaced := True;
            FShadeSetByPoint := i;
            FStackTop := 0;
            FStack[FStackTop] := i;
            break;
          end;
        end
        else
          if FShadePlaced and (FShadeSetByPoint = i) then
          begin
            FDraggingCard := nil;//Temporarily unassigned.
            PickUpMarker(cmDragShade, 1, Deck, False);
//Update invalidated area.
            if Deck.FCardMarks[CardMarkIndex(cmDragShade)].Angle = 0 then
              UpdateArea(Deck.FCardMarks[CardMarkIndex(cmDragShade)].Position.X,
                Deck.FCardMarks[CardMarkIndex(cmDragShade)].Position.Y,
                Deck.CardWidth, Deck.CardHeight)
            else
              UpdateArea(Deck.FCardMarks[CardMarkIndex(cmDragShade)].NXY.X,
                Deck.FCardMarks[CardMarkIndex(cmDragShade)].NXY.Y,
                Deck.FCardMarks[CardMarkIndex(cmDragShade)].NW,
                Deck.FCardMarks[CardMarkIndex(cmDragShade)].NH);
            FDraggingCard := ACard;
            FShadePlaced := False;
            FShadeSetByPoint := -1;//Needs to be set to -1.
          end;
      end;
//End of v1.7 code.
    PutDownShadow(ACard.Fx, ACard.Fy, Deck);
    PutDown(ACard, ACard.Fx, ACard.Fy, Deck);
    ACard.FDisplayed := True;
//Find invalidated region.
    if X1 < ACard.Fx then
      X2 := ACard.Fx
    else begin
      X2 := X1;
      X1 := ACard.Fx;
    end;
    if Y1 < ACard.Fy then
      Y2 := ACard.Fy
    else begin
      Y2 := Y1;
      Y1 := ACard.Fy;
    end;
    Width := X2 - X1 + Deck.FCardWidth + Deck.FShadow01.Width;
    Height := Y2 - Y1 + Deck.FCardHeight + Deck.FShadow01.Width;
    UpdateArea(X1, Y1, Width, Height);
//Finally copy the buffer in one swoop.
    CopyImage(Area.Left,Area.Top,Area.Right-Area.Left,Area.Bottom-Area.Top);
  end;
end;

procedure TCardTable.DropCard(X, Y: Integer; const Move: Boolean = False;
  const Angle: Single = 0);
//Method that user calls in response to a CardDropEvent raised by cardtable. It
//drops card at the x,y co-ordinates. Note parameter Move default false which if
//set to true moves dropped card to X, Y position on screen at speed FCardSpeed.
var
  Deck: TCardDeck;
  X1, Y1, ArrayPos, i: Integer;
  Rect: TRect;
  Covering: TCardList;
begin
  Deck := FDraggingCard.FOwner;
  PickUp(FDraggingCard, Deck);
  PickUpShadow(Deck);
  FDraggingCard.FDisplayed := False;
  if Move then
  begin
    PlaceCard(FDraggingCard, FDraggingCard.X, FDraggingCard.Y);
    if FLiftOffset then
    begin
      MoveTo(FDraggingCard, X - Deck.FShadow01.Width, Y-Deck.FShadow01.Width);
      PickUpCoveringCards2(FDraggingCard, Deck, Rect, Covering, ArrayPos);
      PickUp(FDraggingCard, Deck);
      FDraggingCard.FDisplayed := False;
      if ArrayPos <> FNoOfCardsOnTable then
        for i := ArrayPos to FNoOfCardsOnTable-1 do
          FCardsOnTable[i] := FCardsOnTable[i+1];
      dec(FNoOfCardsOnTable);
      PutDown(FDraggingCard, FDraggingCard.Fx+deck.FShadow01.Width,
        FDraggingCard.Fy+deck.FShadow01.Width, Deck, True, Angle);
      FDraggingCard.FDisplayed := true;
      inc(FNoOfCardsOnTable);
      FCardsOnTable[FNoOfCardsOnTable] := FDraggingCard;
      if Angle = 0 then
        CopyImage(FDraggingCard.Fx - Deck.FShadow01.Width,
          FDraggingCard.Fy - Deck.FShadow01.Width,
          Deck.FCardWidth + Deck.FShadow01.Width,
          Deck.FCardHeight + Deck.FShadow01.Width)
      else begin//CopyBuffer normal + rotated card area.
        Rect.Left :=
          Min(FDraggingCard.Fx - Deck.FShadow01.Width, FDraggingCard.FNXY.X);
        Rect.Top :=
          Min(FDraggingCard.Fy - Deck.FShadow01.Width, FDraggingCard.FNXY.Y);
        Rect.Right :=
          Max((FDraggingCard.Fx - Deck.FShadow01.Width) + Deck.FCardWidth +
            Deck.FShadow01.Width, FDraggingCard.FNXY.X +
            FDraggingCard.FFaceR.Width);
        Rect.Bottom :=
          Max((FDraggingCard.Fy - Deck.FShadow01.Width) + Deck.FCardHeight +
            Deck.FShadow01.Width, FDraggingCard.FNXY.Y +
            FDraggingCard.FFaceR.Height);
        CopyImage(Rect.Left, Rect.Top, Rect.Right - Rect.Left, Rect.Bottom -
            Rect.Top);
      end;
    end
    else//No liftoffset.
      begin
        MoveTo(FDraggingCard, X, Y);
        if Angle <> 0 then
          RotateCard(FDraggingCard, Angle);
      end;
  end
  else//Just drop card no move first.
    begin
      X1 := FDraggingCard.X;
      Y1 := FDraggingCard.Y;
      PutDown(FDraggingCard, X, Y, Deck, True, Angle);
      FDraggingCard.FDisplayed := True;
      inc(FNoOfCardsOnTable);
      FCardsOnTable[FNoOfCardsOnTable] := FDraggingCard;
      CopyImage(X1, Y1, Deck.CardWidth+Deck.FShadow01.Width,
        Deck.CardHeight+Deck.FShadow01.Width);
      if Angle = 0 then
        CopyImage(FDraggingCard.X, FDraggingCard.Y, Deck.CardWidth,
          Deck.CardHeight)
      else
        CopyImage(FDraggingCard.FNXY.X, FDraggingCard.FNXY.Y,
          FDraggingCard.FFaceR.Width, FDraggingCard.FFaceR.Height);
    end;
  FDraggingCard := nil;
  //The following 2 lines allow the forced dropping of a card in code.
  FCardDragging := False;
  Screen.Cursor := FPreDragCursor;
  RefreshLabels;
end;

procedure TCardTable.RestoreCardByMove;
//Called by user in response to a CardDropEvent that restores a dragged card to
//its original position on the table by first moving it onscreen back to its
//origin point. On completion an FOnCardRestoredEvent is triggered.
var
  Deck: TCardDeck;
begin
//We have to pick up & put down again using PlaceCard in order to use MoveTo
//method which needs cards to be in the CardsOnTable array. Later we need to do
//the opposite in order to use RestoreCard.
  Deck := FDraggingCard.FOwner;
  PickUp(FDraggingCard, Deck);
  PickUpShadow(Deck);
  FDraggingCard.FDisplayed := False;
  PlaceCard(FDraggingCard, FDraggingCard.X, FDraggingCard.Y);
  if FLiftOffset then
    MoveTo(FDraggingCard, FDragOrigin.X - Deck.FShadow01.Width,
      FDragOrigin.Y-Deck.FShadow01.Width)
  else
    MoveTo(FDraggingCard, FDragOrigin.X, FDragOrigin.Y);
  PickUp(FDraggingCard, Deck);
  FDraggingCard.FDisplayed := False;
  dec(FNoOfCardsOnTable);
  PutDownShadow(FDraggingCard.Fx, FDraggingCard.Fy, FDraggingCard.Owner);
  PutDown(FDraggingCard, FDraggingCard.Fx, FDraggingCard.Fy,
    FDraggingCard.Owner);
  FDraggingCard.FDisplayed := True;
//New event triggered now.
  if Assigned(FOnCardRestoredEvent) then FOnCardRestoredEvent;
  RestoreCard;
end;

procedure TCardTable.RestoreCard;
//Called by user in response to a CardDropEvent that restores a dragged card to
//its original position on the table.
var
  i, X1, Y1, ArrayPos: Integer;
  Deck: TCardDeck;
  Rect: TRect;
  Covering: TCardList;
begin
  Deck := FDraggingCard.FOwner;
  PickUp(FDraggingCard, Deck);
  PickUpShadow(Deck);
  FDraggingCard.FDisplayed := False;
  X1 := FDraggingCard.X;
  Y1 := FDraggingCard.Y;
  if FCOTPosition > 0 then
  begin
    inc(FNoOfCardsOnTable);
    for i := FNoOfCardsOnTable downto FCOTPosition + 1 do
      FCardsOnTable[i] := FCardsOnTable[i-1];
    FCardsOnTable[FCOTPosition] := FDraggingCard;
    FDraggingCard.Fx := FDragOrigin.X;
    FDraggingCard.Fy := FDragOrigin.Y;
    PickUpCoveringCards2(FDraggingCard, Deck, Rect, Covering, ArrayPos);
  end;
  FDraggingCard.FAngle := FDraggedAngle;//Restore rotation.
  PutDown(FDraggingCard, FDragOrigin.X, FDragOrigin.Y, Deck,
    True, FDraggingCard.FAngle);
  FDraggingCard.FDisplayed := True;
  if FCOTPosition > 0 then
  begin
    if Length(Covering) <> 0 then
      ReplaceCoveringCards(Covering);
  end else
  begin
    FDraggingCard.FStatus := 0;
    dec(Deck.FTop);
  end;
  FCardDragging := False;
  Screen.Cursor := FPreDragCursor;
//Buffer copy the dragging card position and the restore position if required.
  if (X1 <> FDragOrigin.X) or (Y1 <> FDragOrigin.Y) or
    (FDraggingCard.FAngle <> 0) then
    CopyImage(X1, Y1, Deck.CardWidth + Deck.FShadow01.Width, Deck.CardHeight +
      Deck.FShadow01.Width);
  if FDraggingCard.FAngle = 0 then
    CopyImage(FDragOrigin.X, FDragOrigin.Y, Deck.CardWidth +
      Deck.FShadow01.Width, Deck.CardHeight + Deck.FShadow01.Width)
  else
    CopyImage(FDraggingCard.FNXY.X, FDraggingCard.FNXY.Y, FDraggingCard.FNW,
      FDraggingCard.FNH);
  FDraggingCard := nil;
  RefreshLabels;
end;

procedure TCardTable.LoadTableTop(const FileName: TFileName);
//Property method. A BitMap or Jpeg can be displayed on the table top. If
//FStretchBackground is true then the picture is stretched to the tabletop else
//the picture is tiled on the tabletop. NB This MUST MUST have a fully qualified
//file name. ie c:\pic\a.jpg not just a.jpg even if in the program directory. So
//if in program dir use CardTable.Directory + '\a.jpg' as the filename.
var
  BitMap: TBitMap;
  Bounds: TRect;
  i, j, w, h: Integer;
begin
  if not FBitMap.Empty then
  begin
    FBitMap.Free;
    FBitMap := TBitMap.Create;
  end;
  FBitMap.PixelFormat := pf32Bit;
  if FileExists(FileName) then
  begin
    if AnsiCompareText(ExtractFileExt(FileName), '.jpg') = 0  then
      if FFileName <> FileName then
      begin
        if not FJpeg.Empty then
        begin
          FJpeg.Free;
          FJpeg := TJpegImage.Create;
          FJpeg.Performance := FJpegPerformance;
        end;
        FJpeg.LoadFromFile(FileName);
      end;
    BitMap := TBitMap.Create;
    FBitMap.Height := Height;
    FBitMap.Width := Width;
    try
      if AnsiCompareText(ExtractFileExt(FileName), '.jpg') = 0  then
        BitMap.Assign(FJpeg)
      else
        BitMap.LoadFromFile(FileName);
      BitMap.PixelFormat:=pf32bit;
//StretchBackground determines if the picture is stretched to the tabletop or if
//it is tiled.
      if FStretchBackground then
      begin
        Bounds.Left:=0;
        Bounds.Top:=0;
        Bounds.Right:=Width;
        Bounds.Bottom:=Height;
        FBitMap.Canvas.StretchDraw(Bounds, Bitmap);
      end
      else
        begin
//New v1.81 tile code.
          j := 0;
          repeat
            i := 0;
            repeat
              if i + BitMap.Width > Width then
                w := Width - i
              else
                w := BitMap.Width;
              if j + BitMap.Height > Height then
                h := Height - j
              else
                h := BitMap.Height;
              BitBlt(FBitMap.Canvas.Handle, i, j, w, h, BitMap.Canvas.Handle, 0,
                0, SRCCOPY);
              i := i + BitMap.Width;
            until i >= Width;
            j := j + BitMap.Height;
          until j >= Height;
        end;
    finally
      BitMap.Free;
    end;
    FFileName := FileName;
    FBitMap.Dormant;
    FBitMap.FreeImage;
    if FBackDrop.Enabled then FBackDrop.Enabled := False;
    RedrawBuffer;
    Invalidate;
    Application.ProcessMessages;
  end else
    SetColor(FColor);
end;

procedure TCardTable.SetColor(const Color: TColor);
//Property method that sets the color of the table or draws gradient background
//if enabled. If color is required to replace gradient then gradient must first
//be disabled.
begin
  if not FBitMap.Empty then
  begin
    FBitMap.Free;
    FBitMap := TBitMap.Create;
  end;
  FBitMap.Height := Height;
  FBitMap.Width := Width;
  FColor := Color;
  FBitMap.PixelFormat := pf32Bit;//Required else variable draw speeds possible.
  FBitMap.Canvas.Brush.Style := bsSolid;
  FBitMap.Canvas.Brush.Color := FColor;
  if FBackDrop.Enabled then
    FBackDrop.Paint(FBitMap)
  else
    FBitMap.Canvas.FillRect(Rect(0, 0, FBitMap.Width, FBitMap.Height));
  if FFileName <> 'None' then FFileName := 'None';
  RedrawBuffer;//Redraw any cards already on the table.
  Invalidate;
  Application.ProcessMessages;
end;

procedure TCardTable.Show;
//Makes a hidden cardtable visible.
begin
  If not Parent.Visible then Parent.Show;
  inherited;
  Repaint;
  RefreshLabels;
end;

procedure TCardTable.Resize;
//CardTable has resized. Only need to redraw when in component state.
begin
  if csDesigning in ComponentState then                      
    if ((FBitMap.Width <> Width) or (FBitMap.Height <> Height)) then
      if FFileName <> 'None' then
        LoadTableTop(BackgroundPicture)
      else
        SetColor(FColor);
end;

procedure TCardTable.FormIsResizing(Sender: TObject; var NewWidth, NewHeight:
  Integer; var Resize: Boolean);
//Parent form is about to resize. If the table is aligned alClient or AutoResize
//property is True then the table is automatically resized to the size of the
//form. The table does not have to fill the entire form it can be offset from
//the left and top of the table. Properties MinWidth and MinHeight control the
//minimum size allowed for the owner form. Resizing the table before the form
//has been resized reduces flicker.
//
//Note properties MessageFix_ClientWidth & MessageFixClientHeight - FMFCW FMFCH.
var
  F: TForm;
  CW, CH: Integer;
begin
  F := Sender as TForm;
  CW := F.ClientWidth;
  CH := F.ClientHeight;
  if (NewWidth < FMinWidth) or (NewHeight < FMinHeight) then
    Resize := False
  else
    if (Align = alClient) or FAutoResize then
//Make the table the size of the forms client area.
      ResizeTable(Left, Top, NewWidth - (F.Width - CW) - Left,
        NewHeight - (F.Height - CH) - Top)
    else
//Fix for other values for align.
      if (Align = alLeft) or (Align = alRight) then
        ResizeTable(Left, Top, Width, NewHeight - (F.Height - CH) -
          Top)
      else
        if (Align = alBottom) or (Align = alTop) then
          ResizeTable(Left, Top, NewWidth - (F.Width - CW) - Left,
            Height);
end;

function TCardTable.GetCanvas: TCanvas;
//Property method surfacing the internal buffer.
begin
  Result := FBitmap.Canvas;
end;

{$WARNINGS OFF}
procedure TCardTable.SortHand(var Hand: Array of TCard; const AcesLow: Boolean;
  const SuitSort: Boolean; const Planes: Integer = 1);
//Version 2.
//Sorts a hand of cards of any 1..MaxCards size. If visible then the card
//movement is displayed on screen - the cards will switch positions with each
//other horizontaly or verticaly as required depending on their x,y positions
//within the hand. Sorts are always left to right or top to bottom. If AcesLow
//is True aces are low, if False high. If SuitSort is True cards are sorted
//within suits. Planes determines if cards are moved out of the layout plane
//during the switching process. Value of 2 uses 2 plane movement direction
//depending upon the X/Y position of the hand. The cards always move towards the
//centre of the screen. Default value 1 moves cards only in one plane. Will work
//with unassigned array elements if these are higher in the array than the
//assigned cards. ie If [0..7] contain cards and [8..12] are nil than this will
//still work ok. If Jokers are used will sort highest.
type
  TInternalMode = (mUp, mDown, mRight, mLeft);
var
  StoredXY: Array[0..MaxCards-1] of TPoint;
  i, j, iValue, jValue, Top, ArrayPos: Integer;
  MoveCard, TempCard: TCard;
  SwapPoint: TPoint;
  Deck: TCardDeck;
  InternalMode: TInternalMode;
  Rect: TRect;
  Covering: TCardList;
begin
//First no need to sort hands < 2.
  if Length(Hand) < 2 then exit;
  if (Hand[0] = nil) or (Hand[1] = nil) then exit;
//Store the origin X,Y of each card as we need it later to swap the cards.
  for i := 0 to High(Hand) do
    if Assigned(Hand[i]) then
    begin
      StoredXY[i].X := Hand[i].Fx;
      StoredXY[i].Y := Hand[i].Fy;
      Top := i;
    end
    else break;
//Top points to last non nil element or High(Hand). Now sort the hand.
  for i := 0 to Top-1 do
    for j := Top downto i+1 do
    begin
      iValue := Ord(Hand[i].FValue);
      jValue := Ord(Hand[j].FValue);
      if not AcesLow then
      begin
        if (iValue = 0) and not (Hand[i].FSuit = csJoker) then iValue := 13;
        if (jValue = 0) and not (Hand[j].FSuit = csJoker) then jValue := 13;
      end;
      if SuitSort then
      begin
        iValue := iValue + Ord(Hand[i].FSuit)*13;
        jValue := jValue + Ord(Hand[j].FSuit)*13;
      end;
      if Hand[i].FSuit = csJoker then inc(iValue,15);
      if Hand[j].FSuit = csJoker then inc(jValue,15);
      if jValue < iValue then
      begin
        TempCard := Hand[i];
        Hand[i] := Hand[j];
        Hand[j] := TempCard;
      end;
  end;
  if Hand[0].FDisplayed then
  begin
//Move the cards to their sorted positions. All cards must be either horizontal
//or vertical. First find the type of sort.
    if Hand[0].Y = Hand[1].Y then
//Horizontal plane.
    begin
      if Planes = 2 then
        if Hand[0].Y < Height div 2 then
          InternalMode := mDown
        else
          InternalMode := mUp;
    end
    else
//Vertical Plane.
      if Planes = 2 then
        if Hand[0].X < Width div 2 then
          InternalMode := mRight
        else
          InternalMode := mLeft;
    for i := 0 to Top do
    begin
      MoveCard := Hand[i];
      Deck := MoveCard.FOwner;
      SwapPoint.X := StoredXY[i].X;//The origin we stored earlier.
      SwapPoint.Y := StoredXY[i].Y;
//MoveCard needs to be moved to the position of SwapPoint.
      if Planes <> 1 then
      begin
//Two plane movement.
        if InternalMode = mUp then j := -Deck.FCardHeight
        else
          if InternalMode = mDown then j := Deck.FCardHeight;
        if InternalMode = mLeft then j := -Deck.FCardWidth
        else
          if InternalMode = mRight then j := Deck.FCardWidth;
        if (MoveCard.Fx = SwapPoint.X) and (MoveCard.Fy = SwapPoint.Y) then
        begin
//Less flicker than PickUpCard,PlaceCard because only 1 copybuffer.
          PickUpCoveringCards2(MoveCard, Deck, Rect, Covering, ArrayPos);
          PickUp(MoveCard, Deck);
          MoveCard.FDisplayed := False;
          if Length(Covering) <> 0 then
            ReplaceCoveringCards(Covering);
//Delete entry in CardsOnTableArray.
          if ArrayPos <> FNoOfCardsOnTable then
            for j := ArrayPos to FNoOfCardsOnTable-1 do
              FCardsOnTable[j] := FCardsOnTable[j+1];
          dec(FNoOfCardsOnTable);
          PlaceCard(MoveCard, MoveCard.X, MoveCard.Y);
        end
        else begin
          if (InternalMode = mUp) or (InternalMode = mDown) then
          begin
            MoveTo(MoveCard, MoveCard.Fx, MoveCard.Fy+j);
            MoveTo(MoveCard, SwapPoint.X, SwapPoint.Y);
          end
          else
            begin
              MoveTo(MoveCard, MoveCard.Fx+j, MoveCard.Fy);
              MoveTo(MoveCard, SwapPoint.X, SwapPoint.Y);
            end;
        end;
      end
      else
        begin
//PickUp & PlaceCard need to be done for the case of overlapping cards in order
//to place them at the top of the CardsOnTable array (cards are moved from
//bottom to top) and for later cards therefore to be above them.
          PickUpCoveringCards2(MoveCard, Deck, Rect, Covering, ArrayPos);
          PickUp(MoveCard, Deck);
          MoveCard.FDisplayed := False;
          if Length(Covering) <> 0 then
            ReplaceCoveringCards(Covering);
//Delete entry in CardsOnTableArray.
          if ArrayPos <> FNoOfCardsOnTable then
            for j := ArrayPos to FNoOfCardsOnTable-1 do
              FCardsOnTable[j] := FCardsOnTable[j+1];
          dec(FNoOfCardsOnTable);
          PutDown(MoveCard, MoveCard.X, MoveCard.Y, Deck);
          MoveCard.FDisplayed := true;
          inc(FNoOfCardsOnTable);
          FCardsOnTable[FNoOfCardsOnTable] := MoveCard;
          if (MoveCard.Fx = SwapPoint.X) and (MoveCard.Fy = SwapPoint.Y) then
            CopyImage(MoveCard.X, MoveCard.Y,Deck.FCardWidth, Deck.FCardHeight)
          else
            MoveTo(MoveCard, SwapPoint.X, SwapPoint.Y);
        end;
    end;
    RefreshLabels;
  end;
end;
{$WARNINGS ON}
procedure TCardTable.SetDeckOffset(const Offset: Integer);
//Property method that governs how a deck is displayed on the table. An offset
//of around 7 gives a reasonable 3d look to the deck a high value eg 666 none.
begin
  If Offset <> 0 then FPlaceDeckOffset := Offset;
end;

procedure TCardTable.SetDragAndDrop(const Mode: Boolean);
//Property method enabling drag and drop with the mouse.
begin
  if Mode <> self.FDragAndDrop then
    FDragAndDrop := Mode;
end;

procedure TCardTable.SetDragFromDeck(const Mode: Boolean);
//Property method enabling cards to be dragged and drawn from a displayed deck.
begin
  if Mode <> FDragFromDeck then
    FDragFromDeck := Mode;
end;

procedure TCardTable.SetDragFaceDown(const Mode: Boolean);
//Property method  that if true allows face down cards to be dragged.
begin
  if Mode <> FDragFaceDown then
    FDragFaceDown := Mode;
end;

procedure TCardTable.PutDownShadow(const X, Y: Integer; const Deck: TCardDeck);
//Protected method that draws a cards shadow.
var
  X1, Y1, X2, Y2: Integer;
begin
  X1 := X + Deck.FShadow01.Width;
  Y1 := y + deck.FShadow01.Width + deck.FShadow01.Height;
  X2 := X + Deck.FCardWidth;
  Y2 := Y + Deck.FShadow01.Width;
  Deck.FShadow00Point.X := X1;
  Deck.FShadow00Point.Y := Y1;
  Deck.FShadow01Point.X := X2;
  Deck.FShadow01Point.Y := Y2;
  BitBlt(Deck.FShadow00Under.Canvas.Handle, 0, 0, Deck.FShadow00Under.Width,
    Deck.FShadow00Under.Height, FBitMap.Canvas.Handle, X1, Y1, SRCCOPY);
  BitBlt(Deck.FShadow01Under.Canvas.Handle, 0, 0, Deck.FShadow01Under.Width,
    Deck.FShadow01Under.Height, FBitMap.Canvas.Handle, X2, Y2, SRCCOPY);
  if FShadowMode = smOriginal then
  begin
    BitBlt(FBitMap.Canvas.Handle, X1, Y1, Deck.FShadow00.Width,
      Deck.FShadow00.Height, Deck.FShadow00.Canvas.Handle, 0, 0, SRCAND);
    BitBlt(FBitMap.Canvas.Handle, X2, Y2, Deck.FShadow01.Width,
      Deck.FShadow01.Height, Deck.FShadow01.Canvas.Handle, 0, 0, SRCAND);
  end else
    begin
//New shadow.
//Get cardtable region.
      BitBlt(Deck.FShadow00D.Canvas.Handle, 0, 0, Deck.FShadow00Under.Width,
        Deck.FShadow00Under.Height, FBitMap.Canvas.Handle, X1, Y1, SRCCOPY);
      BitBlt(Deck.FShadow01D.Canvas.Handle, 0, 0, Deck.FShadow01Under.Width,
        Deck.FShadow01Under.Height, FBitMap.Canvas.Handle, X2, Y2, SRCCOPY);
//Shade table.
      Darken(@Deck.FShadow00D, FSoftShadow, False);
      Darken(@Deck.FShadow01D, FSoftShadow, True);
//Add mask to shadow.
      BitBlt(Deck.FShadow00D.Canvas.Handle, 0, 0, Deck.FShadow00.Width,
        Deck.FShadow00.Height, Deck.FShadow00IM.Canvas.Handle, 0, 0, SrcAnd);
      BitBlt(Deck.FShadow01D.Canvas.Handle, 0, 0, Deck.FShadow01.Width,
        Deck.FShadow01.Height, Deck.FShadow01IM.Canvas.Handle, 0, 0, SrcAnd);
//Add mask to cardtable.
      BitBlt(FBitMap.Canvas.Handle, X1, Y1, Deck.FShadow00.Width,
        Deck.FShadow00.Height, Deck.FShadow00M.Canvas.Handle, 0, 0, SrcAnd);
      BitBlt(FBitMap.Canvas.Handle, X2, Y2, Deck.FShadow01.Width,
        Deck.FShadow01.Height, Deck.FShadow01M.Canvas.Handle, 0, 0, SrcAnd);
//Paint shadow within mask.
      BitBlt(FBitMap.Canvas.Handle, X1, Y1, Deck.FShadow00.Width,
        Deck.FShadow00.Height, Deck.FShadow00D.Canvas.Handle, 0, 0, SrcPaint);
      BitBlt(FBitMap.Canvas.Handle, X2, Y2, Deck.FShadow01.Width,
        Deck.FShadow01.Height, Deck.FShadow01D.Canvas.Handle, 0, 0, SrcPaint);
    end;
end;

procedure TCardTable.PickUpShadow(const Deck: TCardDeck);
//Protected method that picks up a shadow from the buffer.
begin
  BitBlt(FBitMap.Canvas.Handle, Deck.FShadow01Point.X, Deck.FShadow01Point.Y,
    Deck.FShadow01Under.Width, Deck.FShadow01Under.Height,
    Deck.FShadow01Under.Canvas.Handle, 0, 0, SRCCOPY);
  BitBlt(FBitMap.Canvas.Handle, Deck.FShadow00Point.X, Deck.FShadow00Point.Y,
    Deck.FShadow00Under.Width, Deck.FShadow00Under.Height,
    Deck.FShadow00Under.Canvas.Handle, 0, 0, SRCCOPY);
end;

procedure TCardTable.SetCardDeck(const Deck: TCardDeck);
//Property method that allows a 2nd external deck to be used with cardtable.
begin
  if Assigned(Deck) then
    FCardDeck.Assign(Deck);
end;
{$WARNINGS OFF}
procedure TCardTable.PlaceCardMarker(const CardMarker: TCardMarker; const X, Y:
  Integer; const No: Integer = 1; Deck: TCardDeck = nil;
  const Angle: Single = 0; const Copy: Boolean = True);
//Seven CardMarker types and (MaxOutLines+MaxMarks+MaxSuits*4+1) cardmarkers of
//these types can be placed on the table to signify where cards will be moved.
//These are named in the TCardMarker enumerated type. Parameter No details the
//specific marker of that type that is drawn. A CardMarker or shade can be
//placed whilst a card is being dragged. You can use the autoshade system to
//draw the shade. Assign an array of TDropPoints to property DropPoints
//detailing where shades are drawn. Alternatively you can manually draw the
//shade. The OnMouseMove event has to be caught & PlaceCardMarker called. Before
//dropping the card PickUpMarker must be called. Alternatively just call
//PlaceCardOnShade to pick up the shade & put down the card at its position.
//
//Copy param determines if drawn cardmarker is immediately copied to the screen.
//Not always wanted as when entire screen needs repainting.
//
//Cardmarkers available are:
//cmOutline   1..MaxOutlines
//cmMark      1..MaxMarks
//cmClub      1..MaxSuits
//cmDiamond   1..MaxSuits
//cmHeart     1..MaxSuits
//cmSpade     1..MaxSuits
//cmDragShade 1
//
//Note: When property DropAngles is assigned FShadow02 is used as a DragShade
//when using set C_2 with rotation and HQDragShade is false.
//
var
  ACard: TCard;
  P: PCardMark;
  Deck2: TCardDeck;
  CMIndex: Integer;
begin
  if not Assigned(Deck) then Deck := FCardDeck;
  CMIndex := CardMarkIndex(CardMarker) + No - 1;
  if not Deck.FCardMarks[CMIndex].Displayed then
  begin
    if FCardDragging then
    begin
      ACard := FDraggingCard;
      Deck2 := ACard.FOwner;
      PickUp(ACard, Deck2);
      PickUpShadow(Deck2);
      ACard.FDisplayed := False;
    end;
    P := @Deck.FCardMarks[CMIndex];
    if Angle = 0 then
    begin
      BitBlt(P^.Under.Canvas.Handle, 0, 0, Deck.FCardWidth, Deck.FCardHeight
        ,FBitMap.Canvas.Handle, X, Y, SRCCOPY);
      if (CardMarker = cmDragShade) and FHQDragShade then
      begin//New HQDragShade draw.
        if Deck.FHQDragShade.ShadedMark.Width <> Deck.FCardWidth then
          Deck.FHQDragShade.ShadedMark.Width := Deck.FCardWidth;
        if Deck.FHQDragShade.ShadedMark.Height <> Deck.FCardHeight then
          Deck.FHQDragShade.ShadedMark.Height := Deck.FCardHeight;
//Check if its safe to use current shaded mark.
        if (not Deck.FHQDragShade.InstanceFlag) or (X <> Deck.FHQDragShade.X)
          or (Y <> Deck.FHQDragShade.Y) then
        begin
          BitBlt(Deck.FHQDragShade.ShadedMark.Canvas.Handle, 0, 0,
            Deck.FCardWidth, Deck.FCardHeight ,FBitMap.Canvas.Handle, X, Y,
            SRCCOPY);
          Darken(@Deck.FHQDragShade.ShadedMark, false, true,
            FHQDragShadeColour);
          Deck.FHQDragShade.InstanceFlag := True;
          Deck.FHQDragShade.X := X;
          Deck.FHQDragShade.Y := Y;
//Add mask to shadow.
          BitBlt(Deck.FHQDragShade.ShadedMark.Canvas.Handle, 0, 0,
            Deck.FCardWidth, Deck.FcardHeight,
            Deck.FCardMaskInv.Canvas.Handle, 0, 0, srcand);
        end;
//Add mask to cardtable.
        BitBlt(FBitMap.Canvas.Handle, X, Y, Deck.FCardWidth,
          Deck.FCardHeight, Deck.FCardMask.Canvas.handle, 0, 0, SrcAnd);
//Paint shadow within mask.
        BitBlt(FBitMap.Canvas.Handle, X, Y, Deck.FCardWidth, Deck.FCardHeight,
          Deck.FHQDragShade.ShadedMark.Canvas.Handle, 0, 0, SrcPaint);
      end//Of HQDragShade draw.
      else
      if (CardMarker = cmDragShade) and Assigned(FDropAngles) and
        ((CardDeck.DeckName = 'C_1') or (CardDeck.DeckName = 'C_2')) then
        BitBlt(FBitMap.Canvas.Handle, X, Y, Deck.FCardWidth, Deck.FCardHeight,
          CardDeck.FShadow02.Canvas.Handle, 0, 0, SRCAND)
      else
        BitBlt(FBitMap.Canvas.Handle, X, Y, Deck.FCardWidth, Deck.FCardHeight,
          P^.Mark.Canvas.Handle, 0, 0, SRCAND);

      P^.Position.X := X;
      P^.Position.Y := Y;
      P^.Displayed := True;
      P^.Angle := 0;
    end
    else
      if (CardMarker = cmDragShade) and FHQDragShade then
      begin//New HQDragShade draw.
  //First rotate mask if required.
        if (not Deck.FHQDragShade.InstanceFlag) or (X <> Deck.FHQDragShade.X)
          or (Y <> Deck.FHQDragShade.Y) then
        begin
          gImageArray.AssignFromBitmap(Deck.FCardMask);
          P^.Angle := Angle;
  //CardSet Hard-a-port has no transparent region thus needs white to be set.
          if SameText(Deck.FCardDeckName, 'Hard-a-port') then
            gImageArray.RotateBitmap(Deck.FHQDragShade.RotatedMark, Angle,
              Point(P^.Mark.Width shr 1, P^.Mark.Height shr 1), P^.NA, 1,
              False, True)
          else
            gImageArray.RotateBitmap(Deck.FHQDragShade.RotatedMark, Angle,
              Point(P^.Mark.Width shr 1, P^.Mark.Height shr 1), P^.NA, 1,
              False);
          P^.NW := Deck.FHQDragShade.RotatedMark.Width;
          P^.NH := Deck.FHQDragShade.RotatedMark.Height;
  //Get inverted.
          Deck.FHQDragShade.RotatedMarkInv.Width := P^.NW;
          Deck.FHQDragShade.RotatedMarkInv.Height := P^.NH;
          BitBlt(Deck.FHQDragShade.RotatedMarkInv.Canvas.Handle, 0, 0, P^.NW,
            P^.NH, Deck.FHQDragShade.RotatedMark.Canvas.Handle, 0, 0,
            NOTSRCCOPY);
          P^.Position.X := X;
          P^.Position.Y := Y;
  //Store actual x,y of rotated mark.
          P^.NXY.X := P^.Mark.Width shr 1 + X - P^.NA.X;
          P^.NXY.Y := P^.Mark.Height shr 1 + Y - P^.NA.Y;

          if Deck.FHQDragShade.ShadedMark.Width <> P^.NW then
            Deck.FHQDragShade.ShadedMark.Width := P^.NW;
          if Deck.FHQDragShade.ShadedMark.Height <> P^.NH then
            Deck.FHQDragShade.ShadedMark.Height := P^.NH;
          BitBlt(Deck.FHQDragShade.ShadedMark.Canvas.Handle, 0, 0,
            P^.NW, P^.NH , FBitMap.Canvas.Handle, P^.NXY.X, P^.NXY.Y,
            SRCCOPY);
          Darken(@Deck.FHQDragShade.ShadedMark, false, true, FHQDragShadeColour);
          Deck.FHQDragShade.InstanceFlag := True;
          Deck.FHQDragShade.X := X;
          Deck.FHQDragShade.Y := Y;
//Add mask to shadow.
          BitBlt(Deck.FHQDragShade.ShadedMark.Canvas.Handle, 0, 0,
            P^.NW, P^.NH,
            Deck.FHQDragShade.RotatedMarkInv.Canvas.Handle, 0, 0, srcand);
        end;
        P^.Displayed := True;
  //Now store what will be under the mark.
        if P^.Under.Width < P^.NW then
          P^.Under.Width := P^.NW;
        if P^.Under.Height < P^.NH then
          P^.Under.Height := P^.NH;
        BitBlt(P^.Under.Canvas.Handle, 0, 0, P^.NW, P^.NH,
          FBitMap.Canvas.Handle, P^.NXY.X, P^.NXY.Y, SRCCOPY);
 //Add mask to cardtable.
        BitBlt(FBitMap.Canvas.Handle, P^.NXY.X, P^.NXY.Y, P^.NW,
          P^.NH, Deck.FHQDragShade.RotatedMark.Canvas.Handle, 0, 0, SrcAnd);
 //Paint shadow within mask.
        BitBlt(FBitMap.Canvas.Handle, P^.NXY.X, P^.NXY.Y, P^.NW, P^.NH,
          Deck.FHQDragShade.ShadedMark.Canvas.Handle, 0, 0, SrcPaint);
      end
      else
        begin
  //First rotate card mark if required.
          if P^.Angle <> Angle then
          begin
            P^.Angle := Angle;
            if (CardMarker = cmDragShade) and Assigned(FDropAngles) and
              (CardDeck.DeckName = 'C_2') then
              gImageArray.AssignFromBitmap(CardDeck.FShadow02)
            else
              gImageArray.AssignFromBitmap(P^.Mark);
              gImageArray.RotateBitmap(P^.MarkR, Angle, Point(P^.Mark.Width shr
                1, P^.Mark.Height shr 1), P^.NA, 1, False);
            P^.NW := P^.MarkR.Width;
            P^.NH := P^.MarkR.Height;
          end;
          P^.Position.X := X;
          P^.Position.Y := Y;
          P^.Displayed := True;
  //Store actual x,y of rotated mark.
          P^.NXY.X := P^.Mark.Width shr 1 + X - P^.NA.X;
          P^.NXY.Y := P^.Mark.Height shr 1 + Y - P^.NA.Y;
  //Now store what will be under the mark.
          if P^.Under.Width < P^.NW then
            P^.Under.Width := P^.NW;
          if P^.Under.Height < P^.NH then
            P^.Under.Height := P^.NH;
          BitBlt(P^.Under.Canvas.Handle, 0, 0, P^.NW, P^.NH,
            FBitMap.Canvas.Handle, P^.NXY.X, P^.NXY.Y, SRCCOPY);
  //Draw mark.
          FBitMap.Canvas.Draw(P^.NXY.X, P^.NXY.Y, P^.MarkR);
        end;

    if FCardDragging then
    begin
      PutDownShadow(ACard.Fx, ACard.Fy, Deck2);
      PutDown(ACard, ACard.Fx, ACard.Fy, Deck2);
      ACard.FDisplayed := True;
      FShadePlaced := True;
    end;
    if Copy then
      if Angle = 0 then
        CopyImage(X, Y, Deck.FCardWidth, Deck.FCardHeight)
      else
        CopyImage(P^.NXY.X, P^.NXY.Y, P^.NW, P^.NH);
  end;
end;

procedure TCardTable.PickUpMarker(const CardMarker: TCardMarker;
  const No: Integer = 1; Deck: TCardDeck = nil; const Copy: Boolean = True);
//Picks up a cardmarker from the table.
var
  ACard: TCard;
  P: PCardMark;
  Deck2: TCardDeck;
  CMIndex: Integer;
begin
  if not Assigned(Deck) then Deck := FCardDeck;
  CMIndex := CardMarkIndex(CardMarker) + NO - 1;
  if Deck.FCardMarks[CMIndex].Displayed then
  begin
  //As left mouse button may have been released & FCardDragging set to False.
    if Assigned(FDraggingCard) then
    begin
      ACard := FDraggingCard;
      Deck2 := ACard.FOwner;
      PickUp(ACard, Deck2);
      PickUpShadow(Deck2);
      ACard.FDisplayed := False;
    end;
    P := @Deck.FCardMarks[CMIndex];
    if P^.Angle = 0 then
      BitBlt(FBitMap.Canvas.Handle, P^.Position.X, P^.Position.Y,
        Deck.FCardWidth, Deck.FCardHeight, P^.Under.Canvas.Handle, 0, 0,
        SRCCOPY)
    else
      BitBlt(FBitMap.Canvas.Handle, P^.NXY.X, P^.NXY.Y, P^.NW, P^.NH,
        P^.Under.Canvas.Handle, 0, 0, SRCCOPY);
    P^.Displayed := False;
    if Assigned(FDraggingCard) then
    begin
      PutDownShadow(ACard.Fx, ACard.Fy, Deck2);
      PutDown(ACard, ACard.Fx, ACard.Fy, Deck2);
      ACard.FDisplayed := True;
      FShadePlaced := False;
    end;
    if Copy then
      if P^.Angle = 0 then
        CopyImage(P^.Position.X, P^.Position.Y, Deck.FCardWidth,
          Deck.FCardHeight)
      else
        CopyImage(P^.NXY.X, P^.NXY.Y, P^.NW, P^.NH);
  end;
end;

function TCardTable.CardMarkIndex(const CardMarker: TCardMarker): Integer;
//Protected method returns base index Of TCardMarker in FCardMarks array.
begin
  case CardMarker of
    cmOutline: Result := 1;
    cmMark: Result := MaxOutLines+1;
    cmClub: Result := MaxOutLines+MaxMarks+1;
    cmDiamond: Result := MaxOutLines+MaxMarks+MaxSuits+1;
    cmHeart: Result := MaxOutLines+MaxMarks+MaxSuits*2+1;
    cmSpade: Result := MaxOutLines+MaxMarks+MaxSuits*3+1;
    cmDragShade: Result := MaxOutLines+MaxMarks+MaxSuits*4+1;
  end;
end;
{$WARNINGS ON}
procedure TCardTable.PickUpAllMarkers(Deck: TCardDeck = nil);
//Pick up all cardmarkers from the table. Must not be covered by any cards or
//card being dragged at the time. Done from high to low so if placed low to high
//will pick up ok if rotated & in effect overlapping.
var
  i: Integer;
  P: PCardMark;
begin
  if not Assigned(Deck) then Deck := FCardDeck;
  for i := High(Deck.FCardMarks) downto Low(Deck.FCardMarks) do
    if Deck.FCardMarks[i].Displayed then
    begin
      P := @Deck.FCardMarks[i];
      if P^.Angle = 0 then
        BitBlt(FBitMap.Canvas.Handle, P^.Position.X, P^.Position.Y,
          Deck.FCardWidth, Deck.FCardHeight, P^.Under.Canvas.Handle, 0, 0,
          SRCCOPY)
      else
        BitBlt(FBitMap.Canvas.Handle, P^.NXY.X, P^.NXY.Y,
          P^.NW, P^.NH, P^.Under.Canvas.Handle, 0, 0,
          SRCCOPY);
      P^.Displayed := False;
    end;
  Paint;
end;

procedure TCardTable.PlaceCardMarkers;
//Protected method that redraws any CardMarkers that have been placed.
var
  i,j: Integer;
  P: PCardMark;
  Deck: TCardDeck;
begin
  for i := 1 to 2 do
  begin
    if i = 1 then Deck := FCardDeck
    else
      if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
    for j := Low(Deck.FCardMarks) to High(Deck.FCardMarks) do
    begin
      P := @Deck.FCardMarks[j];
      if P^.Displayed then
      begin
        if P^.Angle = 0 then
        begin
          BitBlt(P^.Under.Canvas.Handle, 0,0, Deck.FCardWidth, Deck.FCardHeight,
            FBitMap.Canvas.Handle, P^.Position.X, P^.Position.Y, SRCCOPY);
          BitBlt(FBitMap.Canvas.Handle, P^.Position.X, P^.Position.Y,
            Deck.FCardWidth, Deck.FCardHeight, P^.Mark.Canvas.Handle, 0, 0,
            SRCAND);
        end
        else
          begin
            BitBlt(P^.Under.Canvas.Handle, 0, 0, P^.NW, P^.NH,
              FBitMap.Canvas.Handle, P^.NXY.X, P^.NXY.Y, SRCCOPY);
            FBitMap.Canvas.Draw(P^.NXY.X, P^.NXY.Y, P^.MarkR);
          end;
      end;
    end;
  end;
end;

procedure TCardTable.DropCardOnShade(const CardMarker: TCardMarker;
  const No: Integer = 1; Deck: TCardDeck = nil; const Move: Boolean = False);
//Picks up the shade & drops dragged card at its position.
var
  CardMark: TCardMarkRecord;
begin
  if not Assigned(Deck) then Deck := FCardDeck;
  CardMark := Deck.FCardMarks[CardMarkIndex(CardMarker) + No - 1];
  PickUpMarker(CardMarker, No, Deck);
  if Move then
    DropCard(CardMark.Position.X, CardMark.Position.Y, True, CardMark.Angle)
  else
    DropCard(CardMark.Position.X, CardMark.Position.Y, False, CardMark.Angle);
end;

procedure TCardTable.ClearTable;
//Picks up & resets internal deck & external deck referenced by ExternalDeck
//property then redraws the table.
begin
  if Assigned(FExternalDeck) then PickUpAllCardsAndReset(FExternalDeck);
  PickUpAllCardsAndReset;
  if BackgroundPicture = 'None' then
    SetColor(FColor)
  else
    LoadTableTop(BackgroundPicture);
end;

procedure TCardTable.SelectBackgroundPicture(const Dir: TFileName = '');
//Selects the background picture of the table via a form.
var
  Picture: TFileName;
begin
  with TOpenPictureDialog.Create(Application) do
    try
      if Dir <> '' then
        InitialDir := Dir;
      Filter := 'Picture Files (*.bmp *.jpg)|*.BMP;*.JPG';
      if Execute then Picture := FileName;
    finally
      Free;
    end;
  Application.ProcessMessages;
  if Picture <> '' then BackgroundPicture := Picture;
end;

function TCardTable.DragCardWithinBounds(const Bounds: TRect): Boolean;
//Returns True if any part of a dragged card is within the Bounds given.
var
  ACard: TCard;
begin
  if FCardDragging then
  begin
    ACard := FDraggingCard;
    if (ACard.Fx + ACard.FFace.Width >= Bounds.Left) and
      (ACard.Fx <= Bounds.Right) and (ACard.Fy + ACard.FFace.Height >=
      Bounds.Top) and (ACard.Fy <= Bounds.Bottom) then
      Result := True
    else
      Result := False;
  end
  else Result := False;
end;

procedure TCardTable.ResizeTable(const Left, Top, Width, Height: Integer);
//Use this method to resize the table NOT the Width & Height properties.
var
  R: TRect;
begin
  if FCopyToScreen then
  begin
    if (Self.Width = Width) and (Self.Height = Height) then
//If not resizing its best just to use Top + Left.
    begin
      Self.Top := Top;
      Self.Left := Left;
    end
    else begin
      R.Left := Left;
      R.Top := Top;
      R.Right := Left + Width;
      R.Bottom := Top + Height;
      UpdateBoundsRect(R);
      if FFileName <> 'None' then
        LoadTableTop(BackgroundPicture)
      else
        SetColor(FColor);
    end;
  end;
end;

procedure TCardTable.SetJpegPerformance(const Performance: TJPEGPerformance);
//Property method setting jpeg perfomance of backgroung jpeg if used.
begin
  FJpeg.Performance := Performance;
  FJpegPerformance := Performance;
end;

function TCardTable.GetCardOnTable(I: Integer): TCard;
//Surfaces the FCardsOnTable array.
begin
  if I <= FNoOfCardsOnTable then
    result := FCardsOnTable[I]
  else
    result := nil;
end;

procedure TCardTable.DeckOrBackChanged;
//As the deck is an object independent of the table changes made to the deck are
//not automatically reflected in cards already displayed on the table. So when
//changes to deck objects are made and cards owned by the deck are already on
//the table you need to call this function to reflect the changes on the table.
begin
  if BackgroundPicture = 'None' then
    SetColor(FColor)
  else
    LoadTableTop(BackgroundPicture);
end;

procedure TCardTable.RefreshLabels;
//If RepaintLabels is set to true then CardTable will repaint any light controls
//as needed. Note however also repaints controls not on the table as well.
var
  i: Integer;
  Temp: TComponent;
begin
  if FCopyToScreen and FRefreshLabels then
    with Owner do
      for I := ComponentCount - 1 downto 0 do
      begin
        Temp := Components[I];
        if (Temp is TGraphicControl) and not (Temp is TCardTable) and
          (Temp as TGraphicControl).Visible then
          (Temp as TGraphicControl).Repaint;
      end;
end;

procedure TCardTable.BackDropRefresh;
//The gradient backdrop wants me to refresh it so lets oblige.
begin
  if FBackDrop.Enabled then
  begin
    if FFileName <> 'None' then
    begin
      FFileName := 'None';
//Following is needed to sometimes stop pixel format errors if display device is
//not 32bit.
      FBitMap.Free;
      FBitMap := TBitMap.Create;
      FBitMap.Height := Height;
      FBitMap.Width := Width;
      FBitMap.PixelFormat := pf32Bit;               
    end;
    FBackDrop.Paint(FBitMap);
    RedrawBuffer;//Redraw any cards already on the table.
    Invalidate;
  end
  else
    SetColor(FColor);
end;

procedure TCardTable.SetTOAS(const Speed: Integer);
//Setting the turn over animation speed property.
begin
  if (FTOAS <> Speed) and (Speed >= 0) then
    FTOAS := Speed;
end;

procedure TCardTable.SetTOAV(const Mode: Boolean);
begin
  if FTOAV <> Mode then
    FTOAV := Mode;
end;

procedure TCardTable.SetTOAL(const Mode: Boolean);
begin
  if FTOAL <> Mode then
    FTOAL := Mode;
end;

procedure TCardTable.SetAutoShadeMode(const Mode: Integer);
begin
  if Mode <> FAutoShadeMode then
    if (Mode = 1) or (Mode = 2) or (Mode = 0) then
      FAutoShadeMode := Mode;
end;

procedure TCardTable.SetStretchBackground(const Mode: Boolean);
begin
  if Mode <> FStretchBackground then
  begin
    FStretchBackground := Mode;
    if BackgroundPicture <> 'None' then
      BackgroundPicture := BackgroundPicture;
  end;
end;

procedure TCardTable.SetLiftOffset(const Mode: Boolean);
begin
  if Mode <> FLiftOffset then FLiftOffset := Mode;
end;

procedure TCardTable.RotateCard(const ACard: TCard; const ToRad: Single);
//Rotates a card on the table TO rotation ToRad.
var
  ArrayPos: Integer;
  Rect, Inval: TRect;
  Covering: TCardList;
  Deck: TCardDeck;
begin
  if ACard.FDisplayed and (ACard.FAngle <> ToRad) then
  begin
    Deck := ACard.FOwner;
    PickUpCoveringCards2(ACard, Deck, Rect, Covering, ArrayPos);
    PickUp(ACard, Deck);
//Get Invalidated rect for original card.
    if ACard.FAngle = 0 then
    begin
      Inval.Left := ACard.Fx;
      Inval.Top := ACard.Fy;
      InVal.Right := Inval.Left + Deck.CardWidth;
      Inval.Bottom := Inval.Top + Deck.CardHeight;
    end
    else
      begin
        Inval.Left := ACard.FNXY.X;
        Inval.Top := ACard.FNXY.Y;
        Inval.Right := Inval.Left + ACard.FNW;
        Inval.Bottom := Inval.Top + ACard.FNH;
      end;
    ACard.FDisplayed := False;
    PutDown(ACard, ACard.X, ACard.Y, ACard.FOwner, True, ToRad);
    ACard.FDisplayed := True;
    if Length(Covering) <> 0 then
      ReplaceCoveringCards(Covering);
//Update Inval with new rotation.
    if ACard.FAngle = 0 then
    begin
      if ACard.Fx < Inval.Left then Inval.Left := ACard.Fx;
      if ACard.Fy < Inval.Top then Inval.Top := ACard.Fy;
      if ACard.Fx + Deck.CardWidth > Inval.Right then
        Inval.Right := ACard.Fx + Deck.CardWidth;
      if ACard.Fy + Deck.CardHeight > Inval.Bottom then
        Inval.Bottom := ACard.Fy + Deck.CardHeight;
    end
    else
      begin
        if ACard.FNXY.X < Inval.Left then Inval.Left := ACard.FNXY.X;
        if ACard.FNXY.Y < Inval.Top then Inval.Top := ACard.FNXY.Y;
        if ACard.FNXY.X + ACard.FNW > Inval.Right then
          Inval.Right := ACard.FNXY.X + ACard.FNW;
        if ACard.FNXY.Y + ACard.FNH > Inval.Bottom then
          Inval.Bottom := ACard.FNXY.Y + ACard.FNH;
      end;
    CopyImage(Inval.Left, Inval.Top, Inval.Right - Inval.Left,
      Inval.Bottom - Inval.Top);
  end;
end;

procedure TCardTable.Wait(n: Integer);
//Using sleep for small n with midiplayer playing can be problematic.
var
  DateTime: TDateTime;
begin
  DateTime := Time;
  repeat
  until MilliSecondsBetween(Time, DateTime) >= n;
end;

procedure TCardTable.SetShadeColour(const C: Integer);
begin
  if (C >= 0) and (c <= 7) then
    FHQDragShadeColour := C
  else
    FHQDragShadeColour := 0;
end;

procedure TCardTable.SetArea(I: Integer; Value: TTableArea);
begin
  if (I > 1) and (I <= MaxAreas) then
    FTableAreas[I] := Value;
end;

function TCardTable.GetArea(I: Integer): TTableArea;
begin
  Result := FTableAreas[I];
end;

procedure TCardTable.SaveStatus(Path: TFileName = '');
//Saves runtime changes made to the table such as background & card speed. Note
//only the table not the owner form. Note Path has no trailing \.
begin
  if Path = '' then Path := FDirectory;
  WriteComponentResFile(Path + '\Status.Dat', self);
end;

procedure TCardTable.LoadStatus(Path: TFileName = '');
//Reload the changes made to the table.
var
  Temp: Boolean;
begin
  Temp := FCopyToScreen;
  FCopyToScreen := False;
  if Path = '' then Path := FDirectory;
  if FileExists(Path + '\Status.Dat') then
    ReadComponentResFile(Path + '\Status.dat', self);
  FCopyToScreen := Temp;
  DeckOrBackChanged;
end;

//Following methods are used in the saving & loading of the table + cards. These
//methods have not been tested much, could be buggy and may not be very useful.
//Might be easier to recreate a game by saving seed to random generator and all
//game moves and card clicks & then obtaining saved position by running thru all
//the game moves!

//WARNING no info on TTableArea class or TableAreas property currently saved.

procedure TCardTable.SaveTable(const FileName: TFileName; Path: TFileName = '');
//Saves Table and cards on the table (inc ExternalDeck). Note no other data eg
//control values or owner form data.
begin
  if Path = '' then Path := FDirectory;
  FSaveTable := True;
  WriteComponentResFile(Path + '\' + FileName, self);
  FSaveTable := False;
end;

procedure TCardTable.LoadTable(const FileName: TFileName; Path: TFileName = '');
//Loads Table state & deck (internal and ExternalDeck property) status. Thus you
//can load the table & cards and (with a bit of effort) 'should be' able to
//recreate  a game that was saved whilst cards were on the table. One way would
//be (external to CardTable) to save the cards values/suits as an integer
//(see WriteCOT and ReadCOT methods) & then on loading the table you could
//relate the card`s value & suit to its saved object in the CardsOnTable array.
//Another way would be to try and recreate the game thru the position of the
//cards in the CardsOnTable array and their relative positions on the table.
//NOTE that if a table is saved when ExternalDeck property is assigned that when
//loading again ExternalDeck MUST first point to an instance of TCardDeck.
//Likewise when loading a table saved without an external deck that ExternalDeck
//MUST first be nil.
var
  i, j, k, l, CardBack: Integer;
  Deck: TCardDeck;
  DT: string;
  Temp: Boolean;
begin
  if Path = '' then Path := FDirectory;
//When loading a multiple deck when a multiple deck is already in use then
//errors can occur unless FCardsOnTable array is reset to nil.
  if Assigned(FExternalDeck) then PickUpAllCardsAndReset(FExternalDeck);
  PickUpAllCardsAndReset;
  for i := 1 to MaxCards do
    FCardsOnTable[i] := nil;
//End of fix.
  Temp := FCopyToScreen;
  FCopyToScreen := False;//Stop intermediate screen redraws.
  FSaveTable := True;//Needs to be set.
  if FileExists(Path + '\' + FileName) then
    ReadComponentResFile(Path + '\' + FileName, self);
  FCopyToScreen := Temp;
  FSaveTable := False;
//Now set the discards array if used. As discards cannot be used the order of
//cards within the array is not important so we dont need to save and load them.
//However if deck offset is used to give a 3d look we do need to place them in
//the array in order of their X values so that the pile can be displayed ok.
  FNoOfDiscards := 0;
  for l := 1 to 2 do
  begin
    if l = 1 then Deck := FCardDeck
    else
      if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
    for i := 1 to FCardDeck.NoOfCards do
      if Deck.FCardArray[i].FStatus = -1 then
      begin
        inc(FNoOfDiscards);
        FDiscardArray[FNoOfDiscards] := nil;//Erasing any old values.
        for j := 1 to FNoOfDiscards do
          if not Assigned(FDiscardArray[j]) then
            FDiscardArray[j] := Deck.FCardArray[i]
          else
            if Deck.FCardArray[i].Fx > FDiscardArray[j].Fx then
            begin
              for k := FNoOfDiscards downto j+1 do
                FDiscardArray[k] := FDiscardArray[k-1];
              FDiscardArray[j] := Deck.FCardArray[i];
              break;
            end;
    end;
  end;
  if FNoOfDiscards <> 0 then
  begin
    FDiscardsAt.X := FDiscardArray[1].Fx;
    FDiscardsAt.Y := FDiscardArray[1].Fy;
  end;
//Now we need to change the internal deck's card face bitmaps. But it may mess
//up the card card back so.
  CardBack := FCardDeck.CardBack;
  DT := CardDeck.FCardDeckName;
  CardDeck.FCardDeckName := '';
  CardDeck.SetDeckName(DT);
//LoadDeck sets the cardback to 1.
  if CardBack <> 1 then FCardDeck.CardBack := CardBack;
  DeckOrBackChanged;
end;

procedure TCardTable.DefineProperties(Filer: TFiler);
//Protected method that overrides method used in the streaming system. This
//allows unpublished cardtable, carddeck and card properties to be saved and
//loaded from streams.
begin
  inherited;
  if not (csDesigning in ComponentState) then
  begin
    Filer.DefineProperty('cno', ReadNoOfCards, WriteNoOfCards, True);
    Filer.DefineProperty('dfu', ReadDeckFaceUp, WriteDeckFaceUp, True);
    Filer.DefineProperty('cv', ReadCardValue, WriteCardValue, True);
    Filer.DefineProperty('cs', ReadCardSuit, WriteCardSuit, True);
    Filer.DefineProperty('fu', ReadFaceUp, WriteFaceUp, True);
    Filer.DefineProperty('st', ReadStatus, WriteStatus, True);
    Filer.DefineProperty('di', ReadDisplayed, WriteDisplayed, True);
    Filer.DefineProperty('cx', ReadX, WriteX, True);
    Filer.DefineProperty('cy', ReadY, WriteY, True);
    Filer.DefineProperty('ft', ReadFT, WriteFT, True);
    Filer.DefineProperty('nocot', ReadNoOfCOT, WriteNoOfCOT, True);
    Filer.DefineProperty('cot', ReadCOT, WriteCOT, True);
    Filer.DefineProperty('cms', ReadCardMarks, WriteCardMarks, True);
    Filer.DefineProperty('dsd', ReadScaleD, WriteScaleD, True);
    Filer.DefineProperty('ds', ReadScale, WriteScale, True);
    Filer.DefineProperty('cr', ReadRotation, WriteRotation, True);
    if Assigned(FExternalDeck) then
    begin
      Filer.DefineProperty('d2name', ReadD2Name, WriteD2Name, True);
      Filer.DefineProperty('d2back', ReadD2Back, WriteD2Back, True);
    end;
  end;
end;

//Following methods write/read values from stream.

procedure TCardTable.WriteRotation(Writer: TWriter);
var
  i, j: Integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      for i := 1 to FCardDeck.NoOfCards do
        Writer.WriteFloat(Deck.FCardArray[i].Rotation);
    end;
end;

procedure TCardTable.ReadRotation(Reader: TReader);
var
  i, j: integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      for i := 1 to FCardDeck.NoOfCards do
        Deck.FCardArray[i].Rotation := Reader.ReadFloat;
    end;
end;

procedure TCardTable.WriteScaleD(Writer: TWriter);
var
  j: Integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      Writer.WriteInteger(Deck.ScaleDeck);
    end;
end;

procedure TCardTable.ReadScaleD(Reader: TReader);
var
  j: Integer;
  Deck: TCardDeck;
begin
  If FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      Deck.ScaleDeck := Reader.ReadInteger;
    end;
end;

procedure TCardTable.WriteScale(Writer: TWriter);
var
  j: Integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      Writer.WriteSingle(Deck.Scale);
    end;
end;

procedure TCardTable.ReadScale(Reader: TReader);
var
  j: Integer;
  Deck: TCardDeck;
begin
  If FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      Deck.Scale := Reader.ReadSingle;
    end;
end;

procedure TCardTable.WriteNoOfCards(Writer: TWriter);
var
  j: Integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      Writer.WriteInteger(Deck.NoOfCards);
    end;
end;

procedure TCardTable.ReadNoOfCards(Reader: TReader);
var
  j: Integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      Deck.NoOfCards := Reader.ReadInteger;
    end;
end;

procedure TCardTable.WriteDeckFaceUp(Writer: TWriter);
var
  j: Integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      Writer.WriteBoolean(Deck.FaceUp);
    end;
end;

procedure TCardTable.ReadDeckFaceUp(Reader: TReader);
var
  j: Integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      Deck.FaceUp := Reader.ReadBoolean;
    end;
end;

procedure TCardTable.WriteCardValue(Writer: TWriter);
var
  i, j: Integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      for i := 1 to FCardDeck.NoOfCards do
        Writer.WriteString(GetEnumName(TypeInfo(TCardValue),
          Ord(Deck.FCardArray[i].Value)));
    end;
end;

procedure TCardTable.ReadCardValue(Reader: TReader);
var
  i, j: integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      for i := 1 to FCardDeck.NoOfCards do
        Deck.FCardArray[i].Value := TCardValue(GetEnumValue(
          TypeInfo(TCardValue), Reader.ReadString));
    end;
end;

procedure TCardTable.WriteCardSuit(Writer: TWriter);
var
  i, j: Integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      for i := 1 to FCardDeck.NoOfCards do
        Writer.WriteString(GetEnumName(TypeInfo(TCardSuit),
          Ord(Deck.FCardArray[i].Suit)));
    end;
end;

procedure TCardTable.ReadCardSuit(Reader: TReader);
var
  i, j: integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      for i := 1 to FCardDeck.NoOfCards do
        Deck.FCardArray[i].Suit := TCardSuit(GetEnumValue(TypeInfo(TCardSuit),
          Reader.ReadString));
    end;
end;

procedure TCardTable.WriteFaceUp(Writer: TWriter);
var
  i, j: Integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      for i := 1 to FCardDeck.NoOfCards do
        Writer.WriteBoolean(Deck.FCardArray[i].FFaceUp);
    end;
end;

procedure TCardTable.ReadFaceUp(Reader: TReader);
var
  i, j: integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      for i := 1 to FCardDeck.NoOfCards do
        Deck.FCardArray[i].FFaceUp := Reader.ReadBoolean;
    end;
end;

procedure TCardTable.WriteStatus(Writer: TWriter);
var
  i, j: Integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      for i := 1 to FCardDeck.NoOfCards do
        Writer.WriteInteger(Deck.FCardArray[i].FStatus);
    end;
end;

procedure TCardTable.ReadStatus(Reader: TReader);
var
  i, j: integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      for i := 1 to FCardDeck.NoOfCards do
      begin
        Deck.FCardArray[i].FStatus := Reader.ReadInteger;
        if Deck.FCardArray[i].FStatus = -2 then inc(Deck.FNoOfStripped);
      end;
    end;
end;

procedure TCardTable.WriteDisplayed(Writer: TWriter);
var
  i, j: Integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
    if j = 1 then Deck := FCardDeck
    else
      if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      for i := 1 to FCardDeck.NoOfCards do
        Writer.WriteBoolean(Deck.FCardArray[i].FDisplayed);
    end;
end;

procedure TCardTable.ReadDisplayed(Reader: TReader);
var
  i, j: integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      for i := 1 to FCardDeck.NoOfCards do
        Deck.FCardArray[i].FDisplayed := Reader.ReadBoolean;
    end;
end;

procedure TCardTable.WriteX(Writer: TWriter);
var
  i, j: integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      for i := 1 to FCardDeck.NoOfCards do
        Writer.WriteInteger(Deck.FCardArray[i].Fx);
    end;
end;

procedure TCardTable.ReadX(Reader: TReader);
var
  i, j: integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      for i := 1 to FCardDeck.NoOfCards do
        Deck.FCardArray[i].Fx := Reader.ReadInteger;
    end;
end;

procedure TCardTable.WriteY(Writer: TWriter);
var
  i, j: integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      for i := 1 to FCardDeck.NoOfCards do
        Writer.WriteInteger(Deck.FCardArray[i].Fy);
    end;
end;

procedure TCardTable.ReadY(Reader: TReader);
var
  i, j: integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      for i := 1 to FCardDeck.NoOfCards do
        Deck.FCardArray[i].Fy := Reader.ReadInteger;
    end;
end;

procedure TCardTable.WriteFT(Writer: TWriter);
var
  j: integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      Writer.WriteInteger(Deck.FTop);
    end;
end;

procedure TCardTable.ReadFT(Reader: TReader);
var
  j: integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      Deck.FTop := Reader.ReadInteger;
    end;
end;

procedure TCardTable.WriteNoOfCOT(Writer: TWriter);
begin
  if FSaveTable then
    Writer.WriteInteger(FNoOfCardsOnTable);
end;

procedure TCardTable.ReadNoOfCOT(Reader: TReader);
begin
  if FSaveTable then
    FNoOfCardsOnTable := Reader.ReadInteger;
end;

procedure TCardTable.WriteCOT(Writer: TWriter);
//Writes an integer identifying the card & deck.
var
  i, a: Integer;
begin
  if FSaveTable then
    for i := 1 to NoOfCardsOnTable do
      with FCardsOnTable[i] do
      begin
        if Owner = FCardDeck then a := 0
        else
          a := FCardDeck.NoOfCards;
        Writer.WriteInteger(a + ord(FValue) + ord(FSuit) * 13);
      end;
end;

procedure TCardTable.ReadCOT(Reader: TReader);
var
  i,j, k: integer;
  V: TCardValue;
  S: TCardSuit;
  Deck: TCardDeck;
  Assigned: Boolean;
begin
  if FSaveTable then
    for i := 1 to NoOfCardsOnTable do
    begin
      j := Reader.ReadInteger;
      if j >= FCardDeck.NoOfCards then
      begin
        j := j - FCardDeck.NoOfCards;
        Deck := FExternalDeck;
      end
      else
        Deck := FCardDeck;
      V := TCardValue(j - (j div 13) * 13);
      S := TCardSuit(j div 13);
//Find the card with these values.
      for j := 1 to Deck.FTop do
        with Deck.FCardArray[j] do
          if (Value = V) and (Suit = S) then
          begin
//The following handles multiple decks. How well it handles them I`m not sure!
            if FCardDeck.NoOfCards > 56 then
            begin
              Assigned := False;
              for k := 1 to i do
                if FCardsOnTable[k] = Deck.FCardArray[j] then
                begin
                  Assigned := True;
                  break;
                end;
              if Assigned then continue;
            end;
            FCardsOnTable[i] := Deck.FCardArray[j];
            break;
          end;
    end;
end;

procedure TCardTable.WriteCardMarks(Writer: TWriter);
var
  i,j: Integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      for i := Low(Deck.FCardMarks) to High(Deck.FCardMarks) do
      begin
        Writer.WriteBoolean(Deck.FCardMarks[i].Displayed);
        Writer.WriteInteger(Deck.FCardMarks[i].Position.X);
        Writer.WriteInteger(Deck.FCardMarks[i].Position.Y);
      end;
    end;
end;

procedure TCardTable.ReadCardMarks(Reader: TReader);
var
  i, j: Integer;
  Deck: TCardDeck;
begin
  if FSaveTable then
    for j := 1 to 2 do
    begin
      if j = 1 then Deck := FCardDeck
      else
        if not Assigned(FExternalDeck) then break else Deck := FExternalDeck;
      for i := Low(Deck.FCardMarks) to High(Deck.FCardMarks) do
      begin
        Deck.FCardMarks[i].Displayed := Reader.ReadBoolean;
        Deck.FCardMarks[i].Position.X := Reader.ReadInteger;
        Deck.FCardMarks[i].Position.Y := Reader.ReadInteger;
      end;
    end;
end;

procedure TCardTable.WriteD2Name(Writer: TWriter);
begin
  Writer.WriteString(FExternalDeck.DeckName);
end;

procedure TCardTable.ReadD2Name(Reader: TReader);
begin
  FExternalDeck.DeckName := Reader.ReadString;
end;

procedure TCardTable.WriteD2Back(Writer: TWriter);
begin
  Writer.WriteInteger(FExternalDeck.CardBack);
end;

procedure TCardTable.ReadD2Back(Reader: TReader);
begin
  FExternalDeck.CardBack := Reader.ReadInteger;
end;



//............................................................................//
//.......................... T S P R I T E ...................................//
//............................................................................//



constructor TSprite.Create(AOwner: TCardTable);
begin
  inherited Create;
  FOwner := AOwner;
  FBitMap := TBitMap.Create;//Base image of sprite.
  FUnder := TBitMap.Create;//Under the sprite.
  FTranny := TBitMap.Create;//Holds transformed image.
  FTranny.PixelFormat := pf24bit;
  FTranny.Transparent := True;
  FBitMap.PixelFormat := pf24bit;
  FDisplayed := False;
  FAngle := 0;
  FScale := 1;
  FX := 0;
  FY := 0;
  FWidth := 0;
  FHeight := 0;
  FNA := Point(0,0);
  FRelative := True;//By default relative to x,y.
end;

destructor TSprite.Destroy;
begin
  FBitMap.Free;
  FUnder.Free;
  FTranny.Free;
  inherited Destroy;
end;

procedure TSprite.Draw;
//Draws sprite of scale at x,y of rotation on bitmap. By default it is relative
//to point x,y. Set Relative to True to draw AT point x,y.
var
  R, R2: TRect;
begin
  R := Rect(-1,0,0,0);
//If displayed then undo first.
  if FDisplayed then
  begin
    Undo;
    R.Left := FNX;
    R.Top := FNY;
    R.Right := R.Left + FWidth;
    R.Bottom := R.Top + FHeight;
  end;
//Transform FBitMap to FTranny.
  gImageArray.AssignFromBitmap(FBitMap);
  gImageArray.RotateBitmap(FTranny, FAngle, Point(FBitMap.Width shr 1,
    FBitMap.Height shr 1), FNA, FScale, False);
  FWidth := FTranny.Width;
  FHeight := FTranny.Height;
  FNX := FBitMap.Width shr 1 + FX - FNA.X;
  FNY := FBitMap.Height shr 1 + FY - FNA.Y;
//Now store what will be under the card. If FUnder is not big enough resize it.
  if FUnder.Width < FWidth then FUnder.Width := FWidth;
  if FUnder.Height < FHeight then FUnder.Height := FHeight;
  BitBlt(FUnder.Canvas.Handle, 0, 0, FWidth, FHeight,
    FOwner.FBitMap.Canvas.Handle, FNX, FNY, SRCCOPY);
//Draw sprite.
  FOwner.FBitMap.Canvas.Draw(FNX, FNY, FTranny);
//Copy buffer.
  R2.Left := FNX;
  R2.Top := FNY;
  R2.Right := R2.Left + FWidth;
  R2.Bottom := R2.Top + FHeight;
  FDisplayed := True;
  if R.Left <> -1 then
  begin
    R2.Left := Min(R.Left, R2.Left);
    R2.Top := Min(R.Top, R2.Top);
    R2.Right := Max(R.Right, R2.Right);
    R2.Bottom := Max(R.Bottom, R2.Bottom);
  end;
  FOwner.CopyImage(R2.Left, R2.Top, R2.Right - R2.Left, R2.Bottom - R2.Top);
end;

procedure TSprite.UnDraw;
begin
  Undo;
  FOwner.CopyImage(FNX, FNY, FWidth, FHeight);
end;

Procedure TSprite.Undo;
begin
  BitBlt(FOwner.FBitMap.Canvas.Handle, FNX, FNY, FWidth,
    FHeight, FUnder.Canvas.Handle, 0, 0, SRCCOPY);
  FDisplayed := False;
end;

procedure TSprite.Shrink(const ACard: TCard; const Target: Single);
//Before calling Angle MUST be set.
begin
  if ACArd.FFaceUp then
    BitMap.Assign(ACard.Face)
  else
    BitMap.Assign(ACard.FOwner.FBack);
  Scale := 1.0;
  Self.X := ACard.X;
  Self.Y := ACard.Y;
  Draw;
  repeat
    Scale := Scale - 0.001;
    Draw;
    sleep(0);
  until Scale <= Target;
  UnDraw;
  Application.ProcessMessages;
end;

procedure TSprite.Grow(const ACard: TCard; const Target, StartScale: Single);
//Before calling Angle MUST be set.
begin
  if ACArd.FFaceUp then
    BitMap.Assign(ACard.Face)
  else
    BitMap.Assign(ACard.FOwner.FBack);
  Scale := StartScale;
  Self.X := ACard.X;
  Self.Y := ACard.Y;
  Draw;
  repeat
    Scale := Scale + 0.001;
    Draw;
    sleep(0);
  until Scale >= Target;
  UnDraw;
  Application.ProcessMessages;
end;

procedure TSprite.Lift(const ACard: TCard; Const MilliSecs: Integer;
  const S: Single; const Reverse: boolean = false);
//Lift ACard using Scale property by S for MilliSecs. Before calling Angle MUST
//be set. Reverse mirrors the lift. Scale is set to 1.
var
  DateTime: TDateTime;
begin
  BitMap.Assign(ACard.Face);
  Scale := 1.0;
  Self.X := ACard.X;
  Self.Y := ACard.Y;
  Draw;
  DateTime := Time;
  repeat
    Scale := Scale + S;
    Draw;
  until MilliSecondsBetween(Time, DateTime) >= MilliSecs;
  if Reverse then
  begin
    DateTime := Time;
    repeat
      Scale := Scale - S;
      if Scale < 1 then break;
      Draw;
    until MilliSecondsBetween(Time, DateTime) >= MilliSecs;
  end;
  UnDraw;
  Application.ProcessMessages;
end;

procedure TSprite.Rotate(const ACard: TCard; const MilliSecs: Integer;
      const R: Single);
//Rotate ACard by radians R for Millisecs. Before calling set Scale if required.
var
  DateTime: TDateTime;
begin
  BitMap.Assign(ACard.Face);
  X := ACard.X;
  Y := ACard.Y;
  Angle := ACard.Rotation;
  Draw;
  DateTime := Time;
  repeat
    Angle := Angle + R;
    Draw;
  until MilliSecondsBetween(Time, DateTime) >= MilliSecs;
  UnDraw;
  Application.ProcessMessages;
end;

procedure TSprite.SaveToFile(const FileName: TFileName; const pf: TPixelFormat);
//Simply saves a transformed bitmap to a file via sprite class.
begin
//Transform FBitMap to FTranny.
  gImageArray.AssignFromBitmap(FBitMap);
  gImageArray.RotateBitmap(FTranny, FAngle, Point(FBitMap.Width shr 1,
    FBitMap.Height shr 1), FNA, FScale, False);
  FWidth := FTranny.Width;
  FHeight := FTranny.Height;
  FNX := FBitMap.Width shr 1 + FX - FNA.X;
  FNY := FBitMap.Height shr 1 + FY - FNA.Y;
//Now store what will be under the card. If FUnder is not big enough resize it.
  if FUnder.Width < FWidth then FUnder.Width := FWidth;
  if FUnder.Height < FHeight then FUnder.Height := FHeight;
  BitBlt(FUnder.Canvas.Handle, 0, 0, FWidth, FHeight,
    FOwner.FBitMap.Canvas.Handle, FNX, FNY, SRCCOPY);
//Save sprite.
  FTranny.PixelFormat := pf;
  FTranny.SaveToFile(FileName);
end;



//............................................................................//
//...................... T T A B L E I M A G E ...............................//
//............................................................................//



//Set displayed to true or call draw to enable images to be drawn by tablearea.
//Set displayed to false or call undraw to remove the image from the screen.
//CardTable will then need a call to paint to display change on screen.

constructor TTableImage.Create(AOwner: TCardTable);
begin
  inherited Create;
  FOwner := AOwner;
  FDisplayed := False;
  FBitMap := TBitMap.Create;
  FBitMap.PixelFormat := pf32Bit;
  FUnder := TBitMap.Create;
end;

destructor TTableImage.Destroy;
begin
  FBitMap.Free;
  FUnder.Free;
  inherited Destroy;
end;

procedure TTableImage.Draw(const X: Integer; const Y: Integer);
var
  b: TBitMap;
begin
  b := (FOwner as TCardTable).FBitMap;
  BitBlt(FUnder.Canvas.Handle, 0, 0, FBitMap.Width, FBitMap.Height,
    b.Canvas.Handle, X, Y, SrcCopy);
  BitBlt(b.Canvas.Handle, X, Y, FBitMap.Width, FBitMap.Height,
    FBitMap.Canvas.Handle, 0, 0, SrcCopy);
  FX := X;
  FY := Y;
  FDisplayed := True;
end;

procedure TTableImage.UnDraw;
var
  b: TBitMap;
begin
  b := (FOwner as TCardTable).FBitMap;
  BitBlt(b.Canvas.Handle, FX, FY, FBitMap.Width, FBitMap.Height,
    FUnder.Canvas.Handle, 0, 0, SrcCopy);
  FDisplayed := False;
end;

procedure TTableImage.LoadPicture(const F: TFileName);
var
  Jpeg: TJpegImage;
begin
  if AnsiCompareText(ExtractFileExt(F), '.jpg') = 0  then
  begin
    Jpeg := TJpegImage.Create;
    try
      Jpeg.Performance := jpBestQuality;
      Jpeg.LoadFromFile(F);
      FBitMap.Assign(Jpeg);
    finally
      Jpeg.Free;
    end;
  end
  else
    FBitMap.LoadFromFile(F);
  FUnder.Width := FBitMap.Width;
  Funder.Height := FBitMap.Height;
end;

procedure TTableImage.SetDisplayed(D: Boolean);
begin
  if D <> FDisplayed then
    if FDisplayed then
      UnDraw
    else
      FDisplayed := True;
end;



//............................................................................//
//....................... T T A B L E A R E A ................................//
//............................................................................//



//Set enabled to true or call draw to enable areas to be drawn by cardtable.
//Set enabled to false or call undraw to remove the area from the screen.
//CardTable will then need a call to paint to display change on screen.

constructor TTableArea.Create(AOwner: TCardTable);
//TableArea describes a table area - rectangular region of table.
begin
  inherited Create;
  FEnabled := False;
  FAreaType := 0;
  FOwner := AOwner;
  FImage := TTableImage.Create(FOwner);
  FUnder := TBitMap.Create;
end;

destructor TTableArea.Destroy;
begin
  FImage.Free;
  FUnder.Free;
  inherited Destroy;
end;

procedure TTableArea.Draw;
//Drawing for the various AreaTypes defined by the game. Type 9 is setaside for
//messages etc and redraws on top of cards unlike all others which paint below.
var
  b: TBitMap;
begin
  FEnabled := True;
  b := (FOwner as TCardTable).FBitMap;
  FUnder.Width := Width;
  FUnder.Height := Height;
  BitBlt(FUnder.Canvas.Handle, 0, 0, Width, Height, b.Canvas.Handle, FX, FY,
    SrcCopy);
  case FAreaType of
    0: begin
        b.Canvas.Brush.Color := clBlack;
        b.Canvas.Brush.Style  := bsSolid;
        b.Canvas.FrameRect(Rect(FX, FY, FX + Width, FY + Height));
        b.Canvas.Brush.Style := bsClear;
       end;
    1: if FImage.FDisplayed then FImage.Draw(FX, FY);
    9: if FImage.FDisplayed then FImage.Draw(FX, FY);
  end;
end;

procedure TTableArea.UnDraw;
var
  b: TBitMap;
begin
  FEnabled := False;
  b := (FOwner as TCardTable).FBitMap;
  BitBlt(b.Canvas.Handle, FX, FY, FUnder.Width, FUnder.Height,
    FUnder.Canvas.Handle, 0, 0, SrcCopy);
end;

procedure TTableArea.SetEnabled(E: Boolean);
begin
  if E <> FEnabled then
    if FEnabled then
      UnDraw
    else
      FEnabled := True;
end;

initialization

Randomize;
gImageArray := TImageArray.Create;

finalization

gImageArray.Free;

end.
