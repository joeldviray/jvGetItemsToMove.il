procedure(jvGetItemsToMove(@optional (win hiGetCurrentWindow()))
  let((transList items sourceCv level)
    transList =  reverse(mapcar('lambda((x) car(x)~>transform) geGetHierMemInst(win)))
    items = geGetSelSet()
    geDeselectAllFig() ;added for to move any instance or pcell down, to fix errror "cannot edit pcell"
    level = deGetEditLevel(win)
    sourceCv = geGetEditCellView()
    list(nil 'transList transList 'items items 'sourceCv sourceCv 'win win 'level level)
  ) ;let
) ;proc


procedure(myMoveItemsHierarchically(data)
  let((newLevel destCv transList transform dir)
    newLevel = deGetEditLevel(data->win)
    if(newLevel > data->level
        dir="down"
        dir="up"
    )
    destCv = geGetEditCellView()
    cond(
        (newLevel==0
            transList = data->transList
        )
        (dir=="up" 
            transList = reverse(nthcdr(newLevel reverse(data->transList)))
        )
        (dir=="down"
            transList = reverse(mapcar('lambda((x) car(x)~>transform) geGetHierMemInst(data->win)))
            transList = reverse(nthcdr(data->level reverse(transList)))
        )
    )
    transform = myConcatTransforms(transList)
    when(dir=="down"
        transform=myReverseTransform(transform)
    )
    dbReopen(data->sourceCv "a")
    foreach(item data->items
        ;use dbMoveFig to move the items
        dbCopyFig(item destCv transform)
    )
    ;dbSave(sourceCv)
  ) ;let
) ;proc

procedure(myConcatTransforms(transList)
    let((newTrans trans)
        newTrans=list('(0.0 0.0) "R0" 1.0)
        ;transList is in order from bottom of hierarchy to top
        foreach(trans transList
            newTrans=dbConcatTransform(newTrans trans)
        )
        newTrans
    )
)

procedure(myReverseTransform(trans)
    let((pt rot mag newPt)
        pt=car(trans)
        rot=cadr(trans)
        mag=caddr(trans)
        ;Think of the logic in this manner:  given that an instance is 
        ;rotated, translated and magnified in the top level, what do you
        ;need to do to get it back to normal orientation.  If it is R90
        ;at the top, you need to R270 to get back.
        case(rot
            ("R0"    newPt=list(xCoord(pt)*-1.0 yCoord(pt)*-1.0) rot="R0"  )
            ("R90"   newPt=list(yCoord(pt)*-1.0 xCoord(pt))      rot="R270")
            ("R180"  newPt=list(xCoord(pt)      yCoord(pt))      rot="R180")
            ("R270"  newPt=list(yCoord(pt)      xCoord(pt)*-1.0) rot="R90" )
            ("MX"    newPt=list(xCoord(pt)*-1.0 yCoord(pt))      rot="MX") 
            ("MY"    newPt=list(xCoord(pt)      yCoord(pt)*-1.0) rot="MY") 
            ("MXR90" newPt=list(yCoord(pt)*-1.0 xCoord(pt)*-1.0) rot="MXR90") 
            ("MYR90" newPt=list(yCoord(pt)      xCoord(pt))      rot="MYR90")
            (t newPt=pt)
        )
        list(newPt rot mag)
    )
)

hiSetBindKey("Layout" "Ctrl<Key>k" "let((data) data=jvGetItemsToMove() geReturnToLevel() myMoveItemsHierarchically(data))")
hiSetBindKey("Layout" "Ctrl<Key>l" "let((data) data=jvGetItemsToMove() leHiEditInPlace() myMoveItemsHierarchically(data))")
