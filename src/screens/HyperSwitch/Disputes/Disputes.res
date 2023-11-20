open APIUtils
open PageLoaderWrapper
@react.component
let make = () => {
  let (screenState, setScreenState) = React.useState(_ => Loading)
  let (disputesData, setDisputesData) = React.useState(_ => [])
  let (filteredDisputesData, setFilteredDisputesData) = React.useState(_ => [])
  let (offset, setOffset) = React.useState(_ => 0)
  let (searchText, setSearchText) = React.useState(_ => "")
  let fetchDetails = useGetMethod()

  let getDisputesList = async () => {
    try {
      setScreenState(_ => Loading)
      let disputesUrl = getURL(~entityName=DISPUTES, ~methodType=Get, ())
      let response = await fetchDetails(disputesUrl)
      let disputesValue = response->LogicUtils.getArrayDataFromJson(DisputesEntity.itemToObjMapper)
      if disputesValue->Js.Array2.length > 0 {
        setDisputesData(_ => disputesValue->Js.Array2.map(Js.Nullable.return))
        setScreenState(_ => Success)
      } else {
        setScreenState(_ => Custom)
      }
    } catch {
    | Js.Exn.Error(e) =>
      let err = Js.Exn.message(e)->Belt.Option.getWithDefault("Failed to Fetch!")
      if err->Js.String2.includes("HE_02") {
        setScreenState(_ => Custom)
      } else {
        setScreenState(_ => PageLoaderWrapper.Error(err))
      }
    }
  }
  React.useEffect0(() => {
    getDisputesList()->ignore
    None
  })

  // TODO: Convert it to remote filter
  let filterLogic = ReactDebounce.useDebounced(ob => {
    let (searchText, arr) = ob
    let filteredList = Js.Array2.filter(arr, (ob: Js.Nullable.t<DisputesEntity.disputes>) => {
      switch Js.Nullable.toOption(ob) {
      | Some(obj) =>
        Js.String2.includes(
          obj.payment_id->Js.String2.toLowerCase,
          searchText->Js.String2.toLowerCase,
        ) ||
        Js.String2.includes(
          obj.dispute_id->Js.String2.toLowerCase,
          searchText->Js.String2.toLowerCase,
        )
      | None => false
      }
    })
    setFilteredDisputesData(_ => filteredList)
  }, ~wait=200)

  let customUI =
    <HelperComponents.BluredTableComponent
      infoText="No disputes as of now." moduleName="Disputes" showRedirectCTA=false
    />

  <PageLoaderWrapper screenState customUI>
    <div className="flex flex-col gap-4">
      <PageUtils.PageHeading title="Disputes" />
      <LoadedTableWithCustomColumns
        title=""
        actualData=filteredDisputesData
        entity={DisputesEntity.disputesEntity}
        resultsPerPage=10
        filters={<TableSearchFilter
          data={disputesData}
          filterLogic
          placeholder="Search payment id or dispute id"
          searchVal=searchText
          setSearchVal=setSearchText
        />}
        showSerialNumber=true
        totalResults={filteredDisputesData->Js.Array2.length}
        offset
        setOffset
        currrentFetchCount={filteredDisputesData->Js.Array2.length}
        defaultColumns={DisputesEntity.defaultColumns}
        customColumnMapper={DisputesEntity.disputesMapDefaultCols}
        showSerialNumberInCustomizeColumns=false
        sortingBasedOnDisabled=false
        hideTitle=true
      />
    </div>
  </PageLoaderWrapper>
}
