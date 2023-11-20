module ConnectorCurrentStepIndicator = {
  @react.component
  let make = (~currentStep: ConnectorTypes.steps, ~stepsArr, ~borderWidth="w-8/12") => {
    let cols = stepsArr->Js.Array2.length->Belt.Int.toString
    let currIndex = stepsArr->Js.Array2.findIndex(item => item === currentStep)
    <div className=" w-full md:w-2/3">
      <div className={`grid grid-cols-${cols} relative`}>
        <div className={`h-0.5 bg-gray-200 ${borderWidth} absolute top-1/4`} />
        {stepsArr
        ->Array.mapWithIndex((step, i) => {
          let isStepCompleted = i <= currIndex
          let stepNumberIndicator = isStepCompleted ? "bg-black text-white" : "bg-white"
          let stepNameIndicator = isStepCompleted ? "text-black" : "text-jp-gray-700"

          <div key={i->Belt.Int.toString} className="z-10 flex flex-col gap-2 font-semibold">
            <div
              className={`w-min px-5 py-3 border rounded-full ${stepNumberIndicator} border-gray-300`}>
              {(i + 1)->string_of_int->React.string}
            </div>
            <div className={stepNameIndicator}>
              {step->ConnectorUtils.getStepName->React.string}
            </div>
          </div>
        })
        ->React.array}
      </div>
    </div>
  }
}

@react.component
let make = (~isPayoutFlow=false, ~showStepIndicator=true, ~showBreadCrumb=true) => {
  open ConnectorTypes
  open ConnectorUtils
  open APIUtils
  let url = RescriptReactRouter.useUrl()
  let hyperswitchMixPanel = HSMixPanel.useSendEvent()
  let connector = UrlUtils.useGetFilterDictFromUrl("")->LogicUtils.getString("name", "")
  let connectorID = url.path->Belt.List.toArray->Belt.Array.get(1)->Belt.Option.getWithDefault("")
  let (screenState, setScreenState) = React.useState(_ => PageLoaderWrapper.Success)
  let (initialValues, setInitialValues) = React.useState(_ => Js.Dict.empty()->Js.Json.object_)
  let (currentStep, setCurrentStep) = React.useState(_ => ConnectorTypes.IntegFields)
  let fetchDetails = useGetMethod()

  let isUpdateFlow = switch url.path {
  | list{"connectors", "new"} => false
  | list{"payoutconnectors", "new"} => false
  | _ => true
  }

  React.useEffect1(() => {
    if connector->Js.String2.length > 0 && connector !== "Unknown Connector" {
      [connector, "global"]->Js.Array2.forEach(ele =>
        hyperswitchMixPanel(
          ~pageName=url.path->LogicUtils.getListHead,
          ~contextName=ele,
          ~actionName=`${isUpdateFlow ? "selectedold" : "selectednew"}`,
          (),
        )
      )
    }
    None
  }, [connector])

  let getConnectorDetails = async () => {
    try {
      let connectorUrl = getURL(~entityName=CONNECTOR, ~methodType=Get, ~id=Some(connectorID), ())
      let json = await fetchDetails(connectorUrl)
      setInitialValues(_ => json)
      setCurrentStep(_ => Preview)
    } catch {
    | _ => ()
    }
  }

  let getDetails = async () => {
    try {
      setScreenState(_ => Loading)
      let _wasmResult = await Window.connectorWasmInit()
      if isUpdateFlow {
        await getConnectorDetails()
      }
      setScreenState(_ => Success)
    } catch {
    | Js.Exn.Error(e) => {
        let err = Js.Exn.message(e)->Belt.Option.getWithDefault("Something went wrong")
        setScreenState(_ => Error(err))
      }
    }
  }

  React.useEffect1(() => {
    if connector->Js.String2.length > 0 {
      getDetails()->ignore
    }
    None
  }, [connector])

  let (title, link) = isPayoutFlow
    ? ("Payout Processor", "/payoutconnectors")
    : ("Processor", "/connectors")

  let stepsArr = isPayoutFlow ? payoutStepsArr : stepsArr
  let borderWidth = isPayoutFlow ? "w-8/12" : "w-9/12"

  <PageLoaderWrapper screenState>
    <div className="flex flex-col gap-8 overflow-scroll h-full w-full">
      <UIUtils.RenderIf condition={showBreadCrumb}>
        <BreadCrumbNavigation
          path=[
            connectorID === "new"
              ? {
                  title,
                  link,
                  warning: `You have not yet completed configuring your ${connector->LogicUtils.snakeToTitle} connector. Are you sure you want to go back?`,
                }
              : {
                  title,
                  link,
                },
          ]
          currentPageTitle={connector->LogicUtils.capitalizeString}
          cursorStyle="cursor-pointer"
        />
      </UIUtils.RenderIf>
      <UIUtils.RenderIf condition={currentStep !== Preview && showStepIndicator}>
        <ConnectorCurrentStepIndicator currentStep stepsArr borderWidth />
      </UIUtils.RenderIf>
      <div className="bg-white rounded border h-3/4 p-2 md:p-6 overflow-scroll">
        {switch currentStep {
        | IntegFields =>
          <ConnectorAccountDetails
            currentStep setCurrentStep setInitialValues initialValues isUpdateFlow isPayoutFlow
          />
        | Webhooks =>
          <ConnectorWebhooks connectorName={connector} setCurrentStep currentStep isUpdateFlow />
        | PaymentMethods =>
          <ConnectorPaymentMethod
            currentStep
            setCurrentStep
            connector
            setInitialValues
            initialValues
            isUpdateFlow
            isPayoutFlow
          />
        | SummaryAndTest
        | Preview =>
          <ConnectorPreview
            connectorInfo={initialValues} currentStep setCurrentStep isUpdateFlow isPayoutFlow
          />
        }}
      </div>
    </div>
  </PageLoaderWrapper>
}
