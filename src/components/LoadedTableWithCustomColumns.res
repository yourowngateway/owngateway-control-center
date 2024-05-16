@react.component
let make = (
  ~defaultSort=?,
  ~title,
  ~description=?,
  ~tableActions=?,
  ~rightTitleElement=React.null,
  ~bottomActions=?,
  ~showSerialNumber=false,
  ~actualData,
  ~totalResults,
  ~resultsPerPage,
  ~offset,
  ~setOffset,
  ~handleRefetch=() => (),
  ~entity: EntityType.entityType<'colType, 't>,
  ~onEntityClick=?,
  ~currrentFetchCount,
  ~filters=React.null,
  ~tableDataBackgroundClass="",
  ~hideRightTitleElement=false,
  ~evenVertivalLines=false,
  ~showPagination=true,
  ~downloadCsv=?,
  ~ignoreUrlUpdate=false,
  ~hideTitle=false,
  ~ignoreHeaderBg=false,
  ~tableDataLoading=false,
  ~dataLoading=false,
  ~advancedSearchComponent=?,
  ~setData=_ => (),
  ~setSummary=_ => (),
  ~dataNotFoundComponent=?,
  ~renderCard=?,
  ~tableLocalFilter=false,
  ~tableheadingClass="",
  ~tableBorderClass="",
  ~tableDataBorderClass="",
  ~collapseTableRow=false,
  ~getRowDetails=_ => React.null,
  ~onMouseEnter=?,
  ~onMouseLeave=?,
  ~frozenUpto=?,
  ~heightHeadingClass=?,
  ~highlightText="",
  ~enableEqualWidthCol=false,
  ~clearFormatting=false,
  ~rowHeightClass="",
  ~allowNullableRows=false,
  ~titleTooltip=false,
  ~isAnalyticsModule=false,
  ~rowCustomClass="",
  ~isHighchartLegend=false,
  ~filterObj=?,
  ~setFilterObj=?,
  ~headingCenter=false,
  ~filterIcon=?,
  ~customColumnMapper,
  ~defaultColumns,
  ~sortingBasedOnDisabled=true,
  ~showSerialNumberInCustomizeColumns=true,
  ~showResultsPerPageSelector=true,
  ~setExtFilteredDataLength=?,
  ~noScrollbar=false,
  ~previewOnly=false,
) => {
  let (showColumnSelector, setShowColumnSelector) = React.useState(() => false)
  let activeColumnsAtom = customColumnMapper->Some
  let visibleColumns = customColumnMapper->Recoil.useRecoilValueFromAtom

  let chooseCols =
    <DynamicTableUtils.ChooseColumnsWrapper
      entity
      totalResults={actualData->Array.length}
      activeColumnsAtom
      defaultColumns
      setShowColumnSelector
      showColumnSelector
      sortingBasedOnDisabled
      showSerialNumber={showSerialNumberInCustomizeColumns}
    />

  let filt =
    <div className="flex flex-row gap-4">
      {filters}
      {chooseCols}
    </div>

  let customizeColumn =
    <UIUtils.RenderIf condition={!hideRightTitleElement}>
      <Portal to={`${title}CustomizeColumn`}>
        <Button
          leftIcon=Button.CustomIcon(<Icon name="edit" size=16 />)
          text="Customize Columns"
          buttonType=SecondaryFilled
          buttonSize=XSmall
          onClick={_ => setShowColumnSelector(_ => true)}
          customButtonStyle="!rounded-lg !bg-white !h-10 !text-black"
        />
      </Portal>
    </UIUtils.RenderIf>

  let rightTitleElement = !previewOnly ? customizeColumn : React.null

  <LoadedTable
    visibleColumns
    entity
    actualData
    title
    hideTitle
    ?description
    rightTitleElement
    ?tableActions
    showSerialNumber
    totalResults
    currrentFetchCount
    offset
    resultsPerPage
    setOffset
    handleRefetch
    ?onEntityClick
    ?downloadCsv
    filters=filt
    tableDataLoading
    dataLoading
    ignoreUrlUpdate
    ?advancedSearchComponent
    setData
    setSummary
    ?dataNotFoundComponent
    ?bottomActions
    ?renderCard
    ?defaultSort
    tableLocalFilter
    collapseTableRow
    ?frozenUpto
    ?heightHeadingClass
    getRowDetails
    ?onMouseEnter
    ?onMouseLeave
    rowHeightClass
    titleTooltip
    rowCustomClass
    ?filterObj
    ?setFilterObj
    ?filterIcon
    tableheadingClass
    tableDataBackgroundClass
    showResultsPerPageSelector
    ?setExtFilteredDataLength
    noScrollbar
  />
}
