open LogicUtils

type role = Admin | ViewOnly | Operations | Developer | None

type userStatus = Active | InviteSent | None

type userTableTypes = {
  user_id: string,
  email: string,
  last_modified_at: string,
  name: string,
  role_id: string,
  role_name: string,
  status: string,
}

type userColTypes =
  | Email
  | Name
  | Role
  | Status

let defaultColumnsForUser = [Name, Role, Email, Status]

let allColumnsForUser = [Name, Role, Email, Status]

type roleColTypes =
  | CreatedOn
  | Role
  | CreatedBy
  | Description
  | ActiveUsers

let defaultColumnsForRole = [Role, Description, CreatedBy, CreatedOn, ActiveUsers]

let allColumnsForRole = [Role, Description, CreatedBy, CreatedOn, ActiveUsers]

let itemToObjMapperForUser = dict => {
  {
    user_id: getString(dict, "user_id", ""),
    email: getString(dict, "email", ""),
    name: getString(dict, "name", ""),
    role_id: getString(dict, "role_id", ""),
    role_name: getString(dict, "role_name", ""),
    status: getString(dict, "status", ""),
    last_modified_at: getString(dict, "last_modified_at", ""),
  }
}

type roleTableTypes = {
  permissions: array<string>,
  role_id: string,
}

type roleListResponse = {
  permissions: array<string>,
  role_id: string,
  role_name: string,
}

let getHeadingForUser = (colType: userColTypes) => {
  switch colType {
  | Name => Table.makeHeaderInfo(~key="name", ~title="Name", ~showSort=true, ())
  | Email => Table.makeHeaderInfo(~key="email", ~title="Email", ~showSort=true, ())
  | Role => Table.makeHeaderInfo(~key="role", ~title="Role", ~showSort=true, ())
  | Status => Table.makeHeaderInfo(~key="status", ~title="Status", ~showSort=true, ())
  }
}

let itemToObjMapperForRole = dict => {
  {
    permissions: dict->getStrArray("permissions"),
    role_id: dict->getString("role_id", ""),
  }
}

let getHeadingForRole = colType => {
  switch colType {
  | Role => Table.makeHeaderInfo(~key="role", ~title="Role name", ~showSort=true, ())
  | Description =>
    Table.makeHeaderInfo(~key="description", ~title="Description", ~showSort=true, ())
  | CreatedBy => Table.makeHeaderInfo(~key="created_by", ~title="Created By", ~showSort=true, ())
  | CreatedOn => Table.makeHeaderInfo(~key="created_on", ~title="Created On", ~showSort=true, ())
  | ActiveUsers =>
    Table.makeHeaderInfo(~key="activeUsers", ~title="Active Users", ~showSort=true, ())
  }
}

let roleToVariantMapper = role => {
  switch role->Js.String2.toUpperCase {
  | "ADMIN" => Admin
  | "VIEW ONLY" => ViewOnly
  | "OPERATIONS" => Operations
  | "DEVELOPER" => Developer
  | _ => None
  }
}

let statusToVariantMapper = role => {
  switch role->Js.String2.toUpperCase {
  | "ACTIVE" => Active
  | "INVITATIONSENT" => InviteSent
  | _ => None
  }
}

let getCssMapperForRole = role => {
  switch role {
  | Admin => "border-blue-500 bg-blue-200"
  | ViewOnly => "border-light-grey bg-extra-light-grey"
  | Developer => "border-red bg-red-200"
  | Operations => "border-green bg-green-200"
  | None => ""
  }
}

let getCssMapperForStatus = status => {
  switch status {
  | Active => "text-green-700"
  | InviteSent => "text-grey-700 opacity-50"
  | None => ""
  }
}

let getCellForUser = (data: userTableTypes, colType: userColTypes): Table.cell => {
  let role = data.role_name->roleToVariantMapper
  let status = data.status->statusToVariantMapper
  switch colType {
  | Name => Text(data.name)
  | Email => Text(data.email)
  | Role =>
    CustomCell(
      <div
        className={`w-fit font-semibold text-sm px-3 py-1 rounded-full border-1 ${role->getCssMapperForRole}`}>
        {data.role_name->Js.String2.toUpperCase->React.string}
      </div>,
      "",
    )
  | Status =>
    CustomCell(
      <div className={`font-semibold text-sm ${status->getCssMapperForStatus}`}>
        {switch status {
        | InviteSent => "INVITE SENT"->Js.String2.toUpperCase->React.string
        | _ => data.status->Js.String2.toUpperCase->React.string
        }}
      </div>,
      "",
    )
  }
}

let getCellForRole = (data: roleTableTypes, colType: roleColTypes): Table.cell => {
  let role = data.role_id->roleToVariantMapper
  switch colType {
  | Role =>
    CustomCell(
      <div
        className={`w-fit font-semibold text-sm px-3 py-1 rounded-full border-1 ${role->getCssMapperForRole}`}>
        {data.role_id->Js.String2.toUpperCase->React.string}
      </div>,
      "",
    )
  | Description => Text(data.role_id)
  | CreatedBy => Text(data.role_id)
  | CreatedOn => Date(data.role_id)
  | ActiveUsers => Text(data.role_id)
  }
}

let getUserData: Js.Json.t => array<userTableTypes> = json => {
  getArrayDataFromJson(json, itemToObjMapperForUser)
}

let getRoleData: Js.Json.t => array<roleTableTypes> = json => {
  getArrayDataFromJson(json, itemToObjMapperForRole)
}

let userEntity = EntityType.makeEntity(
  ~uri="",
  ~getObjects=getUserData,
  ~defaultColumns=defaultColumnsForUser,
  ~allColumns=allColumnsForUser,
  ~getHeading=getHeadingForUser,
  ~getCell=getCellForUser,
  ~dataKey="",
  ~getShowLink={userId => `/users/${userId.user_id}?state=user`},
  (),
)

// let roleEntity = EntityType.makeEntity(
//   ~uri="",
//   ~getObjects=getRoleData,
//   ~defaultColumns=defaultColumnsForRole,
//   ~allColumns=allColumnsForRole,
//   ~getHeading=getHeadingForRole,
//   ~getCell=getCellForRole,
//   ~dataKey="",
//   ~getShowLink={roleId => `/users/${roleId.role_id}?state=role`},
//   (),
// )
