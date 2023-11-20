module InfoField = {
  open LogicUtils
  open FRMInfo
  @react.component
  let make = (~label, ~flowTypeValue, ~actionTypeValue) => {
    <div className="flex flex-col gap-2 mb-7">
      <h4 className="text-lg font-semibold underline"> {label->snakeToTitle->React.string} </h4>
      <div className="flex flex-col gap-1">
        <h3 className="break-all">
          <span className="font-semibold mr-3"> {"Flow :"->React.string} </span>
          {flowTypeValue->getFlowTypeLabel->React.string}
        </h3>
        <h3 className="break-all">
          <span className="font-semibold mr-3"> {"Action :"->React.string} </span>
          {actionTypeValue->getActionTypeLabel->React.string}
        </h3>
      </div>
    </div>
  }
}

module ConfigInfo = {
  open LogicUtils
  open ConnectorTypes
  @react.component
  let make = (~frmConfigs) => {
    frmConfigs
    ->Js.Array2.map(config => {
      <div className="grid grid-cols-2 md:w-1/2 ml-12 my-12">
        <h4 className="text-lg font-semibold"> {config.gateway->snakeToTitle->React.string} </h4>
        <div>
          {config.payment_methods
          ->Js.Array2.map(paymentMethod => {
            <div>
              {paymentMethod.payment_method_types
              ->Array.mapWithIndex(
                (paymentMethodType, i) => {
                  <InfoField
                    key={i->string_of_int}
                    label={paymentMethodType.payment_method_type}
                    flowTypeValue={paymentMethodType.flow}
                    actionTypeValue={paymentMethodType.action}
                  />
                },
              )
              ->React.array}
            </div>
          })
          ->React.array}
        </div>
      </div>
    })
    ->React.array
  }
}

@react.component
let make = (~initialValues, ~currentStep, ~setCurrentStep, ~isUpdateFlow) => {
  open LogicUtils
  open FRMUtils
  open APIUtils
  open ConnectorTypes
  let hyperswitchMixPanel = HSMixPanel.useSendEvent()
  let updateDetails = useUpdateMethod()
  let url = RescriptReactRouter.useUrl()
  let frmName = UrlUtils.useGetFilterDictFromUrl("")->LogicUtils.getString("name", "")

  let showToast = ToastState.useShowToast()
  let frmInfo = initialValues->getDictFromJsonObject->ConnectorTableUtils.getProcessorPayloadType
  let isfrmDisabled = initialValues->getDictFromJsonObject->getBool("disabled", false)

  let frmConfigs = switch frmInfo.frm_configs {
  | Some(config) => config
  | _ => []
  }

  let disableFRM = async isFRMDisabled => {
    try {
      let frmID = initialValues->getDictFromJsonObject->getString("merchant_connector_id", "")
      let disableFRMPayload = initialValues->FRMTypes.getDisableConnectorPayload(isFRMDisabled)
      let url = getURL(~entityName=FRAUD_RISK_MANAGEMENT, ~methodType=Post, ~id=Some(frmID), ())
      let _res = await updateDetails(url, disableFRMPayload->Js.Json.object_, Post)
      showToast(~message=`Successfully Saved the Changes`, ~toastType=ToastSuccess, ())
      RescriptReactRouter.push("/fraud-risk-management")
    } catch {
    | Js.Exn.Error(e) =>
      let _err = Js.Exn.message(e)->Belt.Option.getWithDefault("Failed to Disable connector!")
      showToast(~message=`Failed to Disable connector!`, ~toastType=ToastError, ())
    }
  }

  <div>
    <div className="flex justify-between border-b sticky top-0 bg-white pb-2">
      <div className="flex gap-2 items-center">
        <GatewayIcon gateway={Js.String2.toUpperCase(frmInfo.connector_name)} className=size />
        <h2 className="text-xl font-semibold">
          {frmInfo.connector_name->capitalizeString->React.string}
        </h2>
      </div>
      {switch currentStep {
      | Preview =>
        <div className="flex gap-6 items-center">
          <p
            className={`text-fs-13 font-bold ${isfrmDisabled ? "text-red-800" : "text-green-700"}`}>
            {(isfrmDisabled ? "INACTIVE" : "ACTIVE")->React.string}
          </p>
          <ConnectorPreview.MenuOption
            updateStepValue={ConnectorTypes.PaymentMethods}
            setCurrentStep
            disableConnector={disableFRM}
            isConnectorDisabled={isfrmDisabled}
            connectorInfo={frmInfo}
            pageName={url.path->LogicUtils.getListHead}
          />
        </div>
      | _ =>
        <Button
          onClick={_ => {
            getMixpanelForFRMOnSubmit(
              ~frmName,
              ~currentStep,
              ~isUpdateFlow,
              ~url,
              ~hyperswitchMixPanel,
            )
            RescriptReactRouter.push("/fraud-risk-management")
          }}
          text="Done"
          buttonType={Primary}
        />
      }}
    </div>
    <div>
      <div className="grid grid-cols-2 md:w-1/2 m-12">
        <h4 className="text-lg font-semibold"> {"Processor Mode"->React.string} </h4>
        <div>
          {if frmInfo.test_mode {
            <span className="font-semibold p-2 px-3 bg-orange-200 rounded-full">
              {"TEST MODE"->React.string}
            </span>
          } else {
            <span className="font-semibold p-2 px-3 bg-blue-200 rounded-full">
              {"LIVE MODE"->React.string}
            </span>
          }}
        </div>
      </div>
      <div className="grid grid-cols-2 md:w-1/2 m-12">
        <h4 className="text-lg font-semibold"> {"Profile id"->React.string} </h4>
        <div> {frmInfo.profile_id->React.string} </div>
      </div>
      <UIUtils.RenderIf condition={frmConfigs->Js.Array2.length > 0}>
        <ConfigInfo frmConfigs />
      </UIUtils.RenderIf>
    </div>
  </div>
}
