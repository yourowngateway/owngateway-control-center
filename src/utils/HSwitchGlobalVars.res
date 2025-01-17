@val external appVersion: string = "appVersion"

let dashboardBasePath = Some("/dashboard")

let appendTrailingSlash = url => {
  url->String.startsWith("/") ? url : `/${url}`
}

let appendDashboardPath = (~url) => {
  switch dashboardBasePath {
  | Some(dashboardBaseUrl) =>
    if url->String.length === 0 {
      dashboardBaseUrl
    } else {
      `${dashboardBaseUrl}${url->appendTrailingSlash}`
    }
  | None => url
  }
}

type hostType = Live | Sandbox | Local | Netlify

let hostName = Window.Location.hostname

let hostType = switch hostName {
| "my.owngateway.com" => Live
| "sandox.owngateway.com" => Sandbox
| _ => hostName->String.includes("netlify") ? Netlify : Local
}

let getHostUrlWithBasePath = `${Window.Location.origin}${appendDashboardPath(~url="")}`

let getHostUrl = Window.Location.origin

let isHyperSwitchDashboard = GlobalVars.dashboardAppName === #hyperswitch

let playgroundUserEmail = "dummyuser@dummymerchant.com"
let playgroundUserPassword = "Dummy@1234"

let maximumRecoveryCodes = 8
