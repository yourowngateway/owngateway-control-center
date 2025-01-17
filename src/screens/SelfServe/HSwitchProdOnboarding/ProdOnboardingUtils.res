let defaultValueOfCheckList: ProdOnboardingTypes.checkListType = {
  headerText: "Setup Your First Processor",
  headerVariant: #SetupProcessor,
  itemsVariants: [SELECT_PROCESSOR, SETUP_CREDS, SETUP_WEBHOOK_PROCESSOR],
}

let checkList: array<ProdOnboardingTypes.checkListType> = [
  {
    headerText: "Configure Live Endpoints",
    headerVariant: #ConfigureEndpoint,
    itemsVariants: [REPLACE_API_KEYS, SETUP_WEBHOOK_USER],
  },
  {
    headerText: "Complete Setup",
    headerVariant: #SetupComplete,
    itemsVariants: [SETUP_COMPLETED],
  },
]

let updatedCheckList = [defaultValueOfCheckList]->Array.concat(checkList)

let getPageView = index => {
  open ProdOnboardingTypes
  switch index {
  | SELECT_PROCESSOR => SETUP_CREDS
  | SETUP_CREDS => SETUP_WEBHOOK_PROCESSOR
  | SETUP_WEBHOOK_PROCESSOR => REPLACE_API_KEYS
  | REPLACE_API_KEYS => SETUP_WEBHOOK_USER
  | SETUP_WEBHOOK_USER => SETUP_COMPLETED
  | _ => SETUP_COMPLETED
  }
}

let getBackPageView = index => {
  open ProdOnboardingTypes
  switch index {
  | SETUP_CREDS => SELECT_PROCESSOR
  | SETUP_WEBHOOK_PROCESSOR => SETUP_CREDS
  | REPLACE_API_KEYS => SETUP_WEBHOOK_PROCESSOR
  | SETUP_WEBHOOK_USER => REPLACE_API_KEYS
  | _ => SETUP_COMPLETED
  }
}

let getIndexFromVariant = index => {
  open ProdOnboardingTypes
  switch index {
  | SELECT_PROCESSOR => 0
  | SETUP_CREDS => 1
  | SETUP_WEBHOOK_PROCESSOR => 2
  | REPLACE_API_KEYS => 3
  | SETUP_WEBHOOK_USER => 4
  // | TEST_LIVE_PAYMENT => 5
  | SETUP_COMPLETED => 5
  | _ => 0
  }
}

let sidebarTextFromVariant = pageView => {
  open ProdOnboardingTypes
  switch pageView {
  | SELECT_PROCESSOR => "Select a Processor"
  | SETUP_CREDS => "Setup Credentials"
  | SETUP_WEBHOOK_PROCESSOR => "Configure Processor Webhooks"
  | REPLACE_API_KEYS => "Replace API keys & Live Endpoints"
  | SETUP_WEBHOOK_USER => "Configure OwnGateway Webhooks"
  // | TEST_LIVE_PAYMENT => "Test a live Payment"
  | SETUP_COMPLETED => "Setup Completed"
  | _ => ""
  }
}

let getCheckboxText = connectorName => {
  open ConnectorTypes
  switch connectorName {
  | Processors(STRIPE) | Processors(CHECKOUT) =>
    `I have enabled raw cards on ${connectorName
      ->ConnectorUtils.getConnectorNameString
      ->LogicUtils.capitalizeString}`
  | Processors(BLUESNAP) => `I have uploaded PCI DSS Certificate`
  | Processors(ADYEN) => "I have submitted OwnGateway's PCI Certificates to Adyen"
  | _ => ""
  }
}

let subTextStyle = "text-base font-normal text-grey-700 opacity-50"
let useGetWarningBlockForConnector = connectorName => {
  open ConnectorTypes
  let {globalUIConfig: {font: {textColor}}} = React.useContext(ConfigContext.configContext)
  let hightlightedText = `text-base font-normal ${textColor.primaryNormal} underline`
  switch connectorName {
  | Processors(STRIPE) =>
    Some(
      <span>
        <span className={`${subTextStyle} !opacity-100`}>
          {"Enable Raw Cards: Navigate to Settings > Integrations in your Stripe dashboard; click on advanced options and toggle 'Handle card information directly' or raise a support ticket"->React.string}
        </span>
        <span className="ml-2">
          <a
            href="https://support.stripe.com/contact/email?body=I+would+like+to+request+that+Stripe+enable+raw+card+data+APIs+for+my+account&question=other&subject=Request+to+enable+raw+card+data+APIs&topic=other"
            target="_blank"
            className={`${hightlightedText} cursor-pointer`}>
            {`here`->React.string}
          </a>
        </span>
      </span>,
    )
  | Processors(ADYEN) =>
    Some(<>
      <p className={hightlightedText}> {"Download"->React.string} </p>
      <p className={`${subTextStyle} !opacity-100`}>
        {`and submit our PCI Certificates to Adyen's support team to enable raw cards`->React.string}
      </p>
    </>)
  | Processors(CHECKOUT) =>
    Some(<>
      <p className={`${subTextStyle} !opacity-100`}>
        {`Enable Raw Cards: To enable full card processing on your account, drop an email to`->React.string}
      </p>
      <p className={hightlightedText}> {`support@checkout.com`->React.string} </p>
    </>)
  | Processors(BLUESNAP) =>
    Some(<>
      <p className={hightlightedText}> {"Download"->React.string} </p>
      <p className={`${subTextStyle} !opacity-100`}>
        {`and upload the PCI DSS Certificates`->React.string}
      </p>
      <a
        href="https://www.securitymetrics.com/pcidss/bluesnap"
        target="_blank"
        className={hightlightedText}>
        {`here`->React.string}
      </a>
    </>)
  | _ => None
  }
}

let getProdApiBody = (
  ~parentVariant: ProdOnboardingTypes.sectionHeadingVariant,
  ~connectorId="",
  ~_paymentId: string="",
  (),
) => {
  switch parentVariant {
  | #SetupProcessor =>
    [
      (
        (parentVariant :> string),
        [("connector_id", connectorId->JSON.Encode.string)]->Dict.fromArray->JSON.Encode.object,
      ),
    ]->LogicUtils.getJsonFromArrayOfJson

  | #ProductionAgreement => {
      let agreementVersion = Window.env.agreementVersion->Option.getOr("")
      [
        (
          (parentVariant :> string),
          [("version", agreementVersion->JSON.Encode.string)]->LogicUtils.getJsonFromArrayOfJson,
        ),
      ]->LogicUtils.getJsonFromArrayOfJson
    }
  | _ => (parentVariant :> string)->JSON.Encode.string
  }
}

let getProdOnboardingUrl = (
  enum: ProdOnboardingTypes.sectionHeadingVariant,
  getURL: (
    ~entityName: APIUtilsTypes.entityName,
    ~methodType: Fetch.requestMethod,
    ~id: option<string>=?,
    ~connector: option<'a>=?,
    ~userType: APIUtilsTypes.userType=?,
    ~userRoleTypes: APIUtilsTypes.userRoleTypes=?,
    ~reconType: APIUtilsTypes.reconType=?,
    ~queryParamerters: option<string>=?,
    unit,
  ) => string,
) => {
  `${getURL(~entityName=USERS, ~userType=#USER_DATA, ~methodType=Get, ())}?keys=${(enum :> string)}`
}

let prodOnboardingEnumIntialArray: array<ProdOnboardingTypes.sectionHeadingVariant> = [
  #ProductionAgreement,
  #SetupProcessor,
  #ConfigureEndpoint,
  #SetupComplete,
]
let getSetupProcessorType: Dict.t<'a> => ProdOnboardingTypes.setupProcessor = value => {
  {
    connector_id: value->LogicUtils.getString("connector_id", ""),
  }
}

let stringToVariantMapperForUserData = str =>
  switch str {
  | "ProductionAgreement" => #ProductionAgreement
  | "SetupProcessor" => #SetupProcessor
  | "SetupComplete" => #SetupComplete
  | "ConfigureEndpoint" => #ConfigureEndpoint
  | _ => #ProductionAgreement
  }

let getStringFromVariant = variant => {
  (variant: ProdOnboardingTypes.sectionHeadingVariant :> string)
}

let getTypedValue = dict => {
  open ProdOnboardingTypes
  open LogicUtils
  {
    productionAgreement: dict->getBool(#ProductionAgreement->getStringFromVariant, false),
    configureEndpoint: dict->getBool(#ConfigureEndpoint->getStringFromVariant, false),
    setupComplete: dict->getBool(#SetupComplete->getStringFromVariant, false),
    setupProcessor: dict
    ->getDictfromDict(#SetupProcessor->getStringFromVariant)
    ->getSetupProcessorType,
  }
}

let getPreviewState = headerVariant => {
  open ProdOnboardingTypes
  switch headerVariant {
  | #SetupProcessor => SELECT_PROCESSOR_PREVIEW
  | #ConfigureEndpoint => LIVE_ENDPOINTS_PREVIEW
  | #SetupComplete => COMPLETE_SETUP_PREVIEW
  | _ => SELECT_PROCESSOR_PREVIEW
  }
}
